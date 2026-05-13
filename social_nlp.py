"""
social_nlp.py — LLM-powered social signal extraction for the social_tracking plugin.

Replaces the six regex-based detection functions:
    _detect_user_commitment       → NLP (regex fallback)
    _detect_third_party_commitments → NLP (regex fallback)
    _detect_relationships         → NLP (regex fallback)
    _detect_relationship_changes  → NLP (regex fallback)
    _auto_sentiment_trust         → NLP (keyword fallback)
    _classify_interaction         → NLP (keyword fallback)

Architecture:
    text → LLM structured prompt → validated JSON → DB writes
    On any LLM failure → regex fallback (existing patterns still work)
"""
from __future__ import annotations

import json
import logging
import re
from typing import Any, Dict, List, Optional

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# JSON Schema — the single structured output contract
# ---------------------------------------------------------------------------
_SOCIAL_EXTRACTION_SCHEMA: dict = {
    "type": "object",
    "properties": {
        "persons_mentioned": {
            "type": "array",
            "items": {"type": "string"},
            "description": "All person/entity names mentioned (humans and agents)."
        },
        "commitments": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "promisor": {"type": "string",
                                 "description": "Who made the commitment."},
                    "promisee": {"type": "string",
                                 "description": "Who the commitment was made to."},
                    "description": {"type": "string",
                                    "description": "What was promised (concise)."},
                    "strength": {"type": "number", "minimum": 0.0, "maximum": 1.0,
                                 "description": "How firm this commitment is (0=weak hint, 1=explicit promise)."}
                },
                "required": ["promisor", "promisee", "description", "strength"]
            },
            "description": "All commitments detected in the text, any direction."
        },
        "relationships": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "person_a": {"type": "string"},
                    "person_b": {"type": "string"},
                    "type": {
                        "type": "string",
                        "enum": [
                            "spouse", "dating", "engaged", "partner", "divorced",
                            "separated", "parent_of", "child_of", "sibling", "family",
                            "colleague", "manager_of", "reports_to", "mentor_of",
                            "mentee_of", "business_partner", "client_of",
                            "friend", "close_friend", "acquaintance", "roommate",
                            "adversarial", "estranged"
                        ]
                    },
                    "status": {"type": "string", "enum": ["active", "ended"]},
                },
                "required": ["person_a", "person_b", "type"]
            },
            "description": "Relationships detected. Use 'ended' status for breakups/divorces."
        },
        "sentiments": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "target": {"type": "string",
                               "description": "Name of the person the sentiment is about."},
                    "polarity": {
                        "type": "string", "enum": ["positive", "negative", "neutral"],
                        "description": "Overall sentiment direction."
                    },
                    "intensity": {"type": "number", "minimum": 0.0, "maximum": 1.0,
                                  "description": "How strong the sentiment is."}
                },
                "required": ["target", "polarity"]
            },
            "description": "Sentiment toward each mentioned person."
        },
        "interaction_class": {
            "type": "string",
            "enum": ["positive_interaction", "problem_report", "technical_discussion",
                      "question", "commitment_made", "general_chat"],
            "description": "Overall interaction type."
        }
    },
    "required": ["persons_mentioned", "commitments", "relationships",
                  "sentiments", "interaction_class"]
}

# ---------------------------------------------------------------------------
# Instructions that define what the LLM should do
# ---------------------------------------------------------------------------
_EXTRACTION_INSTRUCTIONS = (
    "You are a social information extractor. Analyze the conversation text "
    "and extract social signals. The text contains a user message followed by "
    "an assistant response.\n\n"
    "Rules:\n"
    "1. Extract ALL person/entity names mentioned (humans and AI agents).\n"
    "2. Detect commitments in ANY direction:\n"
    "   - 'I will do X' → assistant/user → other\n"
    "   - 'Alice told Bob she'd do X' → Alice → Bob\n"
    "   - 'Alice owes Bob the report' → Alice → Bob\n"
    "   - 'Alice is supposed to send the files to Bob' → Alice → Bob\n"
    "   Set strength=0.9-1.0 for explicit promises, 0.5-0.8 for 'will do', "
    "0.3-0.5 for tentative plans ('I'll try', 'maybe I can').\n"
    "3. Detect relationships: spouse, dating, manager_of, colleague, friend, "
    "etc. Use status='ended' for breakups, divorces, firings.\n"
    "4. Classify sentiment toward each mentioned person (positive/negative/neutral). "
    "Consider context, not just keywords.\n"
    "5. Classify the overall interaction.\n\n"
    "Be conservative: if a signal is ambiguous, set lower strength or skip it. "
    "Output ONLY valid JSON matching the schema."
)

# ---------------------------------------------------------------------------
# Core: call ctx.llm.complete_structured with graceful fallback
# ---------------------------------------------------------------------------

def extract_social_signals(
    user_message: str,
    assistant_response: str,
    llm,  # ctx.llm (PluginLlm instance)
    known_persons: Optional[Dict[str, Any]] = None,
) -> dict:
    """
    Extract social signals via LLM structured output.

    Args:
        user_message: The user's last message.
        assistant_response: The assistant's last response.
        llm: The ctx.llm PluginLlm instance for making the call.
        known_persons: Dict of {name: person_record} from the DB — passed
                       as context hints to the LLM.

    Returns:
        dict with keys: persons_mentioned, commitments, relationships,
                        sentiments, interaction_class.
        On LLM failure: returns empty structure (caller falls back to regex).
    """
    combined = f"USER: {user_message}\n\nASSISTANT: {assistant_response}"

    person_hints = ""
    if known_persons:
        names = list(known_persons.keys())
        person_hints = f"\n\nKnown persons in context: {', '.join(names)}"

    input_text = combined + person_hints

    messages = [{"role": "user", "content": input_text}]

    try:
        result = llm.complete_structured(
            instructions=_EXTRACTION_INSTRUCTIONS,
            input=messages,
            json_schema=_SOCIAL_EXTRACTION_SCHEMA,
            max_tokens=1024,
            temperature=0.0,
        )
        # result is already validated by complete_structured
        data = result  # PluginLlmStructuredResult returns parsed dict

        logger.debug("NLP extraction succeeded: %d persons, %d commitments, "
                      "%d relationships, %d sentiments",
                      len(data.get("persons_mentioned", [])),
                      len(data.get("commitments", [])),
                      len(data.get("relationships", [])),
                      len(data.get("sentiments", [])))
        return data

    except Exception as exc:
        logger.warning("NLP social extraction failed, falling back to regex: %s",
                        exc)
        return {}  # Caller handles empty → regex fallback


# ---------------------------------------------------------------------------
# Apply helpers — consume NLP results and write to DB
# ---------------------------------------------------------------------------

def _apply_commitments(
    db,
    commitments: List[dict],
    known_persons: Dict[str, int],
    strength_threshold: float = 0.3,
) -> int:
    """Record commitments from NLP extraction. Returns count written."""
    recorded = 0
    for c in commitments:
        if c.get("strength", 0) < strength_threshold:
            continue

        promisor = _resolve(c.get("promisor", ""), known_persons)
        promisee = _resolve(c.get("promisee", ""), known_persons)
        desc = c.get("description", "").strip()

        if not (promisor and promisee and 5 < len(desc) < 200):
            continue
        if promisor == promisee:
            continue

        try:
            db.add_commitment(
                from_person=promisor,
                to_person=promisee,
                description=desc,
            )
            logger.info("NLP commitment: %s→%s: %s (strength=%.2f)",
                         promisor, promisee, desc[:60], c["strength"])
            recorded += 1
        except Exception as e:
            logger.debug("NLP commitment record failed: %s", e)
    return recorded


def _apply_relationships(
    db,
    relationships: List[dict],
    known_persons: Dict[str, int],
) -> int:
    """Upsert relationships from NLP extraction. Returns count written."""
    written = 0
    for r in relationships:
        pa = _resolve(r.get("person_a", ""), known_persons)
        pb = _resolve(r.get("person_b", ""), known_persons)
        rel_type = r.get("type", "")

        if not (pa and pb and rel_type):
            continue
        if pa == pb:
            continue

        try:
            if r.get("status") == "ended":
                db.end_relationship(pa, pb, rel_type=rel_type,
                                    reason="NLP: relationship ended")
                logger.info("NLP relationship ended: %s ↔ %s [%s]",
                             pa, pb, rel_type)
            else:
                db.upsert_relationship(pa, pb, rel_type, confidence=0.6,
                                        source="conversation_nlp")
                logger.info("NLP relationship: %s ↔ %s [%s] (active)",
                             pa, pb, rel_type)
            written += 1
        except Exception as e:
            logger.debug("NLP relationship write failed: %s", e)
    return written


def _apply_sentiment_trust(
    db,
    trust_mgr,
    sentiments: List[dict],
    known_persons: Dict[str, int],
) -> int:
    """Apply sentiment-based trust adjustments. Returns count adjusted."""
    adjusted = 0
    for s in sentiments:
        target = _resolve(s.get("target", ""), known_persons)
        polarity = s.get("polarity", "neutral")
        intensity = s.get("intensity", 0.5) or 0.5

        if not target or polarity == "neutral":
            continue

        # Map polarity + intensity to trust delta
        if polarity == "positive":
            delta = intensity * 0.06  # Max ~0.06
        else:  # negative
            delta = -intensity * 0.08  # Negative weighted more, max ~0.08

        try:
            trust_mgr.adjust(known_persons.get(target), delta)
            logger.debug("NLP trust %s: %+.3f (%s, intensity=%.2f)",
                          target, delta, polarity, intensity)
            adjusted += 1
        except Exception as e:
            logger.debug("NLP trust adjust failed: %s", e)
    return adjusted


def _classify(nlp_interaction_class: str) -> str:
    """Return the DB-friendly interaction class from NLP output."""
    valid = {
        "positive_interaction", "problem_report", "technical_discussion",
        "question", "commitment_made", "general_chat"
    }
    return nlp_interaction_class if nlp_interaction_class in valid else "general_chat"


def _resolve(name_variant: str, known_persons: Dict[str, int]) -> Optional[str]:
    """Resolve a name from NLP output to a known person."""
    if not name_variant:
        return None
    name_lower = name_variant.lower().strip()

    # Pronoun resolution
    if name_lower in ("i", "me", "my", "myself", "mine"):
        return known_persons.get("user") and "user" or "user"

    for known_name in known_persons:
        if known_name.lower() == name_lower:
            return known_name
        if name_lower in known_name.lower() or known_name.lower() in name_lower:
            return known_name

    # If the LLM invented a name not in known_persons, still accept it
    # (it will be auto-created upstream in post_llm_call)
    return name_variant if len(name_variant) > 1 else None


# ---------------------------------------------------------------------------
# Fallback — the existing keyword-based classifier when NLP is empty
# ---------------------------------------------------------------------------

def fallback_classify_interaction(user_msg: str, asst_msg: str) -> str:
    """Keyword-based fallback interaction classifier."""
    combined = (user_msg + " " + asst_msg).lower()
    if any(w in combined for w in ["thank", "thanks", "appreciate"]):
        return "positive_interaction"
    if any(w in combined for w in ["wrong", "error", "broken", "fail"]):
        return "problem_report"
    if any(w in combined for w in ["promise", "will do", "i'll", "commit"]):
        return "commitment_made"
    if any(w in combined for w in ["question", "how", "what", "why", "?"]):
        return "question"
    if any(w in combined for w in ["code", "pr", "review", "merge", "fix"]):
        return "technical_discussion"
    return "general_chat"
