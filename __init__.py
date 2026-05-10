"""
Hermes Plugin: social_tracking v2 (Auto-Awareness)

Key improvements over v1:
1. AUTO-PERSON-DISCOVERY: Any named entity in messages auto-creates a person record
2. SENTIMENT-TRUST: Trust scores auto-adjust based on interaction sentiment
3. BIDIRECTIONAL COMMITMENTS: Detects commitments from BOTH user and assistant
4. TRUST DECAY: Inactive persons slowly lose trust over time
5. PROACTIVE REMINDERS: Pending/broken commitments always injected into context
6. UNIVERSAL TOOL HOOKS: Any tool call mentioning persons gets linked

The agent never needs to consciously call social tools — awareness is fully passive.
"""
from __future__ import annotations
import logging
import os
import re
from typing import Any, Callable, Dict, List, Optional
from datetime import datetime, timezone, timedelta

logger = logging.getLogger(__name__)


def register(ctx):
    """Plugin entry-point."""
    from .config import SocialTrackingConfig
    from .db import SocialDB
    from .memory_client import MemoryClient
    from .entity import extract_persons
    from .tom_pipeline import ToMPipeline
    from .trust import TrustManager
    from .commitment import CommitmentTracker

    # ---- Config -----------------------------------------------------------
    raw_cfg = ctx.config.get("social_tracking", {})
    cfg = SocialTrackingConfig(**raw_cfg)

    # ---- Database ---------------------------------------------------------
    db_path = cfg.db_path or _resolve_mazemaker_db(ctx)
    db = SocialDB(db_path)
    db.connect()
    logger.info("SocialDB v2 connected: %s", db_path)

    # ---- Components -------------------------------------------------------
    mem = MemoryClient(ctx.tool_registry)
    trust_mgr = TrustManager(db, cfg.trust_increment, cfg.trust_decrement,
                              cfg.trust_clamp_min, cfg.trust_clamp_max)
    commits = CommitmentTracker(db)

    def _llm_call(prompt: str, model: Optional[str]) -> str:
        return ctx.llm_call(prompt, model=model or cfg.tom_model
                            or ctx.get_agent_model())

    tom_pipeline = ToMPipeline(
        llm_call=_llm_call,
        model=cfg.tom_model,
        norms=cfg.domain_norms,
    )

    worker = ConsolidationWorkerV2(db, trust_mgr, mem, cfg.consolidation_interval_s)
    worker.start()

    _state: Dict[str, Any] = {}

    # =======================================================================
    # HOOK: on_session_start
    # =======================================================================
    def on_session_start(session_id: str, **_kw):
        eid = db.create_event("session_start",
                              context_notes=f"session={session_id}")
        _state["session_id"] = session_id
        _state["event_id"] = eid
        logger.debug("Session started id=%s event=%s", session_id, eid)

    ctx.register_hook("on_session_start", on_session_start)

    # =======================================================================
    # HOOK: pre_llm_call — V2: proactive reminders + richer context
    # =======================================================================
    def pre_llm_call(system_prompt: str, user_message: str, **_kw) -> dict:
        # 1. Extract persons from user message
        persons = extract_persons(user_message, cfg.entity_backend,
                                  cfg.spacy_model)

        # 2. Auto-discover: upsert any new persons found (passive)
        person_ids = {}
        for name in persons:
            # V3: Auto-detect entity kind from context
            _kind = _detect_entity_kind(name, user_message)
            pid = db.upsert_person(name, kind=_kind)
            person_ids[name] = pid
            _auto_detect_roles(db, name, user_message)

        # 3. Recall social memories
        recall_parts = []
        for name in persons:
            mems = mem.recall_about_person(name, top_k=cfg.top_k_recall // 2)
            if mems:
                recall_parts.extend(mems)
        recent = mem.recall(user_message, top_k=cfg.top_k_recall // 2)
        recall_parts.extend(recent)

        context_block = mem.format_context_block(
            recall_parts[:cfg.top_k_recall], "SOCIAL MEMORY"
        )

        # 4. Run ToM pipeline
        pipeline_result = tom_pipeline.run(user_message, context_block)
        _state["pipeline_result"] = pipeline_result
        _state["person_ids"] = person_ids
        _state["user_message"] = user_message

        # 5. Build injection with PROACTIVE REMINDERS
        tom = pipeline_result.tom
        dom = pipeline_result.domain
        trust_lines = []
        for name in persons:
            summary = trust_mgr.trust_summary(name)
            person = db.get_person(name)
            kind_tag = f" [{person.get('kind', 'human')}]" if person else ""
            trust_lines.append(f"{summary}{kind_tag}")

        injection = (
            f"\n[SOCIAL CONTEXT]\n"
            f"Detected persons: {', '.join(persons) or 'none'}\n"
            f"User emotion: {tom.emotion} | intent: {tom.intent}\n"
            f"Suggested tone: {dom.suggested_tone}\n"
            f"Social notes: {dom.social_notes or 'none'}\n"
        )
        if trust_lines:
            injection += "Trust scores:\n" + "\n".join(
                f"  - {t}" for t in trust_lines
            ) + "\n"

        # V2: PROACTIVE COMMITMENT REMINDERS
        pending = _get_proactive_commitments(db)
        if pending:
            injection += "\n⚠️ OUTSTANDING COMMITMENTS:\n"
            injection += pending + "\n"

        if context_block:
            injection += context_block + "\n"
        injection += "[/SOCIAL CONTEXT]"

        return {"extra_system": injection}

    ctx.register_hook("pre_llm_call", pre_llm_call)

    # =======================================================================
    # HOOK: post_llm_call — V2: auto-sentiment, auto-commitments, auto-trust
    # =======================================================================
    def post_llm_call(assistant_response: str, user_message: str, **_kw):
        pr = _state.get("pipeline_result")
        if pr:
            valid, note = tom_pipeline.validate_response(
                assistant_response, pr.domain
            )
            pr.response_valid = valid
            pr.validation_note = note
            if not valid:
                logger.warning("Response validation FAILED: %s", note[:120])

        # V2: Extract persons from BOTH messages (auto-discovery)
        user_persons = extract_persons(user_message, cfg.entity_backend,
                                        cfg.spacy_model)
        asst_persons = extract_persons(assistant_response, cfg.entity_backend,
                                        cfg.spacy_model)
        all_persons = list(set(user_persons + asst_persons))
        all_pids = {}
        for name in all_persons:
            _kind = _detect_entity_kind(name, user_message + " " + assistant_response)
            pid = db.upsert_person(name, kind=_kind)
            all_pids[name] = pid

        # Store episodic memories
        uid = mem.remember(f"User: {user_message}", category="episodic")
        aid = mem.remember(f"Assistant: {assistant_response}", category="episodic")

        # Link memories to ALL persons (not just pre-detected)
        for name, pid in all_pids.items():
            db.upsert_edge(uid, pid, "mentioned", 1.0)
            db.upsert_edge(aid, pid, "mentioned", 1.0)

        # V2: AUTO-SENTIMENT trust adjustment
        _auto_sentiment_trust(db, trust_mgr, user_message, all_pids)

        # V3: FOUR-DIRECTION commitment detection
        # 1. Assistant → User (first-person)
        cid = commits.maybe_record(
            assistant_response,
            promisor_name="assistant",
            promisee_name=_state.get("user_name", "user"),
        )
        if cid:
            logger.info("Auto-detected commitment: assistant→user: %s", cid)

        # 2. User → Assistant (first-person)
        user_cid = _detect_user_commitment(
            db, commits, user_message,
            promisor_name=_state.get("user_name", "user"),
            promisee_name="assistant",
        )
        if user_cid:
            logger.info("Auto-detected commitment: user→assistant: %s", user_cid)

        # 3 + 4: Third-party commitments (any person → any person)
        _detect_third_party_commitments(db, commits, user_message, all_pids)
        _detect_third_party_commitments(db, commits, assistant_response, all_pids)

        # V3: RELATIONSHIP detection from both messages
        _detect_relationships(db, user_message, all_pids)
        _detect_relationships(db, assistant_response, all_pids)

        # V3: RELATIONSHIP CHANGE detection (divorce, breakup, etc.)
        _detect_relationship_changes(db, user_message, all_pids)
        _detect_relationship_changes(db, assistant_response, all_pids)

        # Record interaction event
        kind = _classify_interaction(user_message, assistant_response)
        db.create_event(kind, context_notes=f"session={_state.get('session_id', 'unknown')}")
        for pid in set(all_pids.values()):
            db.upsert_edge(_state.get("event_id", 0), pid, "participated", 1.0)

        _state["all_pids"] = all_pids

    ctx.register_hook("post_llm_call", post_llm_call)

    # =======================================================================
    # HOOK: on_session_end
    # =======================================================================
    def on_session_end(**_kw):
        sid = _state.get("session_id", "unknown")
        mem.remember(f"Session {sid} ended.", category="episodic")
        worker.run_cycle()

    ctx.register_hook("on_session_end", on_session_end)

    # =======================================================================
    # HOOK: pre_tool_call — V2: capture tool args for person detection
    # =======================================================================
    def pre_tool_call(tool_name: str, **kwargs):
        _state["last_tool_name"] = tool_name
        _state["last_tool_args"] = kwargs
        return {"tool_name": tool_name, "args": kwargs}

    ctx.register_hook("pre_tool_call", pre_tool_call)

    # =======================================================================
    # HOOK: post_tool_call — V2: universal person detection in all tool calls
    # =======================================================================
    def post_tool_call(tool_name: str, result: Any, **kwargs):
        # V2: Check ALL tool calls for person mentions, not just Mazemaker
        all_text = str(kwargs) + " " + str(result)
        persons = extract_persons(all_text, cfg.entity_backend, cfg.spacy_model)

        for name in persons[:5]:  # limit to avoid spam
            pid = db.upsert_person(name)
            # Record that this person was referenced in a tool call
            mem.remember(
                f"Tool {tool_name} referenced person: {name}",
                category="tool_reference"
            )
            # Auto-detect roles from tool context
            _auto_detect_roles(db, name, all_text)

        # Special handling for Mazemaker tools (legacy support)
        if tool_name in ["neural_remember", "neural_recall", "neural_think"]:
            if tool_name == "neural_remember":
                content = kwargs.get("content", "No content provided")
                mid = mem.remember(content, category="mazemaker_remember")
                for name in persons[:3]:
                    pid = db.upsert_person(name)
                    db.upsert_edge(mid, pid, "mentioned", 1.0)
            elif tool_name == "neural_recall":
                query = kwargs.get("query", "")
                mem.remember(f"Recall query: {query}", category="mazemaker_recall")
                for name in persons[:3]:
                    pid = db.upsert_person(name)
                    db.upsert_edge(pid, 0, "recalled", 0.5)

        # V2: Track file operations mentioning persons
        if tool_name in ["read_file", "write_file", "patch", "search_files"]:
            for name in persons[:3]:
                pid = db.upsert_person(name)
                mem.remember(
                    f"File operation ({tool_name}) referenced: {name}",
                    category="file_reference"
                )

    ctx.register_hook("post_tool_call", post_tool_call)

# =======================================================================
    # TOOLS — Proper JSON Schema registration for Hermes exposure
    # =======================================================================

    def social_remember(content: str, person_name: str = "",
                        category: str = "social") -> dict:
        mid = mem.remember(content, category=category)
        if person_name:
            pid = db.upsert_person(person_name)
            db.upsert_edge(mid, pid, "mentioned", 1.0)
        return {"memory_id": mid, "person": person_name}

    def social_query(person_name: str = "",
                     query_type: str = "trust") -> dict:
        if query_type == "trust":
            return {"trust": trust_mgr.get_trust(person_name),
                    "summary": trust_mgr.trust_summary(person_name)}
        if query_type == "commitments":
            return {"summary": commits.pending_summary()}
        if query_type == "profile" and person_name:
            person = db.get_person(person_name)
            mems = mem.recall_about_person(person_name, top_k=5)
            return {"profile": person,
                    "recent_memories": [m.get("content", "") for m in mems]}
        return {"error": "Unknown query_type or missing person_name"}

    def social_commit(description: str, promisee_name: str = "user",
                      due_date: str = "") -> dict:
        promisor_id = db.upsert_person("assistant")
        promisee_id = db.upsert_person(promisee_name)
        cid = db.add_commitment(
            from_person="assistant",
            to_person=promisee_name,
            description=description,
            due_date=due_date or None
        )
        return {"commitment_id": cid, "description": description}

    def social_fulfill(commitment_id: str,
                       fulfiller_name: str = "assistant") -> dict:
        commits.mark_fulfilled(commitment_id, fulfiller_name)
        fulfiller_id = db.upsert_person(fulfiller_name)
        trust_mgr.reward(fulfiller_id)
        return {"status": "fulfilled", "commitment_id": commitment_id}
    ctx.register_tool("social_remember", social_remember, {
        "description": "Store a socially-tagged memory, optionally linked to a named person. Use when you learn something important about someone that auto-detection might miss (preferences, facts, personal details).",
        "parameters": {
            "type": "object",
            "properties": {
                "content": {
                    "type": "string",
                    "description": "The memory content to store"
                },
                "person_name": {
                    "type": "string",
                    "description": "Optional: name of the person this memory is about"
                },
                "category": {
                    "type": "string",
                    "description": "Memory category (default: 'social')",
                    "default": "social"
                }
            },
            "required": ["content"]
        }
    })

    ctx.register_tool("social_query", social_query, {
        "description": "Query social information: trust scores, pending commitments, or person profiles. Use when you need to look up your history with someone before responding.",
        "parameters": {
            "type": "object",
            "properties": {
                "person_name": {
                    "type": "string",
                    "description": "Name of the person to query"
                },
                "query_type": {
                    "type": "string",
                    "description": "What to query: 'trust' (trust score), 'commitments' (pending promises), or 'profile' (full person record + recent memories)",
                    "enum": ["trust", "commitments", "profile"]
                }
            },
            "required": ["person_name", "query_type"]
        }
    })

    ctx.register_tool("social_commit", social_commit, {
        "description": "Explicitly record a promise or commitment you are making to someone. More reliable than auto-detection — use this for important promises.",
        "parameters": {
            "type": "object",
            "properties": {
                "description": {
                    "type": "string",
                    "description": "What you are promising to do"
                },
                "promisee_name": {
                    "type": "string",
                    "description": "Who you are making the promise to (default: 'user')",
                    "default": "user"
                },
                "due_date": {
                    "type": "string",
                    "description": "Optional ISO 8601 due date (e.g., '2026-05-15')"
                }
            },
            "required": ["description"]
        }
    })

    ctx.register_tool("social_fulfill", social_fulfill, {
        "description": "Mark a previously-made commitment as fulfilled. Increases trust of the fulfiller.",
        "parameters": {
            "type": "object",
            "properties": {
                "commitment_id": {
                    "type": "string",
                    "description": "The ID of the commitment to mark as fulfilled"
                },
                "fulfiller_name": {
                    "type": "string",
                    "description": "Who fulfilled it (default: 'assistant')",
                    "default": "assistant"
                }
            },
            "required": ["commitment_id"]
        }
    })

    logger.info("social_tracking v2 plugin registered (auto-awareness mode).")
    return {"db": db, "trust": trust_mgr, "commits": commits,
            "tom": tom_pipeline, "worker": worker}
# ===========================================================================
# V2 HELPER FUNCTIONS
# ===========================================================================

# Sentiment keywords for auto-trust adjustment
_POSITIVE_SENTIMENT = [
    "thank", "thanks", "great", "excellent", "amazing", "awesome",
    "helpful", "appreciate", "good job", "well done", "perfect",
    "fantastic", "brilliant", "love", "wonderful", "impressive",
    "grateful", "nice work", "solid", "superb", "outstanding",
]
_NEGATIVE_SENTIMENT = [
    "wrong", "broken", "failed", "error", "bad", "terrible",
    "useless", "disappointed", "frustrated", "angry", "hate",
    "awful", "waste", "stupid", "ridiculous", "unacceptable",
    "missed", "late", "never", "worst", "horrible",
]
_ROLE_HINTS = {
    "manager": ["manager", "managing", "supervisor", "boss", "director", "lead"],
    "coworker": ["coworker", "colleague", "teammate", "peer", "team"],
    "client": ["client", "customer", "stakeholder", "external"],
    "mentor": ["mentor", "mentoring", "guide", "advisor", "coach"],
    "engineer": ["developer", "engineer", "programmer", "coder", "architect"],
    "new-hire": ["new hire", "onboarding", "junior", "intern", "new"],
}


def _resolve_mazemaker_db(ctx) -> str:
    """Resolve DB path from context or default."""
    return ctx.config.get("social_tracking", {}).get(
        "db_path",
        os.path.expanduser("~/.hermes/social_tracking.db")
    )


def _auto_detect_roles(db, name: str, text: str):
    """Passively detect role hints from text and update person record."""
    text_lower = text.lower()
    detected = []
    for role, keywords in _ROLE_HINTS.items():
        for kw in keywords:
            if kw in text_lower:
                detected.append(role)
                break
    if detected:
        person = db.get_person(name)
        if person:
            existing_roles_str = person.get("roles") or ""
            existing = set(existing_roles_str.split(",")) if existing_roles_str else set()
            new_roles = existing | set(detected)
            # Update roles using direct connection
            conn = db._connect(reuse=False)
            cur = conn.cursor()
            cur.execute(
                "UPDATE persons SET roles = ? WHERE name = ?",
                (",".join(sorted(new_roles)), name)
            )
            conn.commit()
            db._close(conn)


def _auto_sentiment_trust(db, trust_mgr, text: str, person_ids: Dict[str, int]):
    """Auto-adjust trust based on sentiment toward mentioned persons."""
    text_lower = text.lower()
    sentiment_score = 0

    for word in _POSITIVE_SENTIMENT:
        if word in text_lower:
            sentiment_score += 0.02
    for word in _NEGATIVE_SENTIMENT:
        if word in text_lower:
            sentiment_score -= 0.03  # Negative weighted slightly more

    if abs(sentiment_score) < 0.01:
        return  # No significant sentiment

    # Clamp
    sentiment_score = max(-0.1, min(0.1, sentiment_score))

    # Apply to all persons mentioned
    for name, pid in person_ids.items():
        # Apply smaller delta for sentiment (trust changes accumulate)
        trust_mgr.adjust(pid, sentiment_score * 0.5)
        logger.debug(
            "Auto-trust %s: %+.3f (sentiment %+.3f)",
            name, sentiment_score * 0.5, sentiment_score
        )


def _detect_user_commitment(db, commits, text: str, promisor_name: str,
                             promisee_name: str) -> Optional[str]:
    """Detect commitments made by the user in their message."""
    commitment_patterns = [
        r"(?:i will|i'll|i promise to|i commit to|i shall|i am going to)\s+(.+?)(?:\.|$|by|before|until)",
        r"(?:i owe you|i need to|i have to|i must)\s+(.+?)(?:\.|$|by|before|until)",
        r"(?:let me|i can)\s+(?:get|do|make|send|write|create|fix|build|deliver)\s+(.+?)(?:\.|$|by|before|until)",
    ]

    text_lower = text.lower()
    for pattern in commitment_patterns:
        matches = re.findall(pattern, text_lower, re.IGNORECASE)
        if matches:
            description = matches[0].strip()
            if len(description) > 5 and len(description) < 200:
                try:
                    cid = db.add_commitment(
                        from_person=promisor_name,
                        to_person=promisee_name,
                        description=description,
                    )
                    return str(cid)
                except Exception as e:
                    logger.warning("Failed to record user commitment: %s", e)
    return None


def _classify_interaction(user_msg: str, asst_msg: str) -> str:
    """Classify the type of interaction for event recording."""
    combined = (user_msg + " " + asst_msg).lower()
    if any(w in combined for w in ["thank", "thanks", "appreciate"]):
        return "positive_interaction"
    if any(w in combined for w in ["wrong", "error", "broken", "fail"]):
        return "problem_report"
    if any(w in combined for w in ["promise", "will do", "i'll", "commit"]):
        return "commitment_made"
    if any(w in combined for w in ["question", "how", "what", "why", "?"]):
        return "question"
    if any(w in combined for w in ["code", "pr", "review", "merge"]):
        return "technical_discussion"
    return "general_chat"


def _get_proactive_commitments(db) -> str:
    """Get a concise summary of pending/broken commitments for injection."""
    try:
        conn = db._connect()
        cur = conn.cursor()
        cur.execute("""
            SELECT c.commitment_id, c.description, c.status,
                   p_from.name as from_name, p_to.name as to_name
            FROM commitments c
            JOIN commitment_parties cp_from ON c.commitment_id = cp_from.commitment_id AND cp_from.role = 'maker'
            JOIN persons p_from ON cp_from.person_id = p_from.person_id
            JOIN commitment_parties cp_to ON c.commitment_id = cp_to.commitment_id AND cp_to.role = 'target'
            JOIN persons p_to ON cp_to.person_id = p_to.person_id
            WHERE c.status IN ('pending', 'broken')
            ORDER BY c.status DESC, c.timestamp_promised ASC
            LIMIT 8
        """)
        rows = cur.fetchall()
        db._close(conn)

        if not rows:
            return ""

        lines = []
        for r in rows:
            icon = "🔴" if r[2] == "broken" else "🟡"
            lines.append(f"  {icon} #{r[0]} [{r[2]}] {r[3]} → {r[4]}: {r[1][:80]}")
        return "\n".join(lines)
    except Exception as e:
        logger.debug("Proactive commitments query failed: %s", e)
        return ""


class ConsolidationWorkerV2:
    """V2: Adds trust decay for inactive persons."""

    def __init__(self, db, trust_mgr, mem, interval_s: int = 3600):
        self.db = db
        self.trust_mgr = trust_mgr
        self.mem = mem
        self.interval_s = interval_s
        self._running = False

    def start(self):
        self._running = True
        logger.info("ConsolidationWorkerV2 started (interval=%ds, trust_decay=enabled)",
                     self.interval_s)

    def run_cycle(self):
        """Run consolidation + trust decay."""
        if not self._running:
            return

        # V2: Trust decay for inactive persons
        self._apply_trust_decay()

        # Original consolidation logic
        try:
            self.mem.consolidate()
        except Exception as e:
            logger.debug("Consolidation skipped: %s", e)

    def _apply_trust_decay(self):
        """Slightly decay trust for HUMAN persons inactive > 7 days.
        Agents do NOT decay — their reliability doesn't fade with disuse."""
        try:
            conn = self.db._connect()
            cur = conn.cursor()
            threshold = (datetime.now(timezone.utc) - timedelta(days=7)).isoformat()
            cur.execute("""
                SELECT person_id, name, trust_score, last_active, kind
                FROM persons
                WHERE last_active < ? 
                  AND trust_score > 0.1
                  AND kind = 'human'
            """, (threshold,))
            inactive = cur.fetchall()

            for pid, name, trust, last, kind in inactive:
                new_trust = max(0.1, float(trust) - 0.01)
                cur.execute(
                    "UPDATE persons SET trust_score = ? WHERE person_id = ?",
                    (new_trust, pid)
                )
                logger.debug("Trust decay: %s [%s] %.3f -> %.3f (inactive since %s)",
                             name, kind, float(trust), new_trust, last)

            if inactive:
                conn.commit()
                logger.info("Trust decay applied to %d inactive humans (agents skipped)", len(inactive))
            self.db._close(conn)
        except Exception as e:
            logger.debug("Trust decay skipped: %s", e)


# ===========================================================================
# V3 HELPER FUNCTIONS
# ===========================================================================

# Agent name patterns for auto-detection
_AGENT_PATTERNS = [
    r'\b(?:agent|bot|ai|assistant|claude|gpt|hermes|trivium|yunami|kardashev|lilly|iustitia)\b',
    r'\b\w+[-_]?(?:agent|bot|ai)\b',
]
_USER_PATTERNS = [
    r'\b(?:user|marko|human|operator|you)\b',
]


def _detect_entity_kind(name: str, context: str) -> str:
    """Auto-detect whether a named entity is a human, agent, or user."""
    ctx_lower = context.lower()
    name_lower = name.lower()

    # Check for user identity
    for pattern in _USER_PATTERNS:
        if re.search(pattern, name_lower):
            return "user"

    # Check for agent identity  
    for pattern in _AGENT_PATTERNS:
        if re.search(pattern, name_lower):
            return "agent"

    # Context clues: "the agent Trivium", "AI assistant", "Claude said"
    agent_context_clues = [
        rf'{re.escape(name_lower)}\s+(?:is\s+(?:an?\s+)?(?:agent|bot|ai|assistant))',
        rf'(?:agent|bot|ai|assistant)\s+{re.escape(name_lower)}',
    ]
    for clue_pattern in agent_context_clues:
        if re.search(clue_pattern, ctx_lower):
            return "agent"

    # Default: human
    return "human"


def _detect_third_party_commitments(db, commits, text: str,
                                     known_persons: Dict[str, int]):
    """Detect third-party commitments like 'Alice promised Bob she'd send files.'

    Matches patterns where one named person commits something to another.
    Covers: human→human, agent→agent, agent→human, human→agent.
    """
    if not known_persons or len(known_persons) < 2:
        return

    names = list(known_persons.keys())
    # Build person name alternation for regex
    names_pattern = '|'.join(re.escape(n) for n in names)

# Third-party commitment patterns
    # ALL patterns return groups in order: (promisor, description, promisee)
    patterns = [
        # "Alice told Bob she would send the files"
        rf'({names_pattern})\s+(?:told|promised|assured|informed)\s+({names_pattern})\s+(?:that\s+)?(?:she|he|they|it)\s+(?:would|will|shall)\s+(.+?)(?:\.|$|\s+by|\s+before)',
        # "Alice committed to Bob that she'd deliver"
        rf'({names_pattern})\s+committed\s+to\s+({names_pattern})\s+(?:that\s+)?(?:she|he|they|it)\s+(?:would|will)\s+(.+?)(?:\.|$|\s+by|\s+before)',
        # "Alice owes Bob the design doc"
        rf'({names_pattern})\s+owes?\s+({names_pattern})\s+(.+?)(?:\.|$)',
        # These patterns have description in MIDDLE: (promisor, desc, promisee)
        # Pattern tag 'mid' indicates description is group 2
    ]
    
    mid_desc_patterns = [
        # "Bob is supposed to send Alice the report"
        rf'({names_pattern})\s+(?:is|are)\s+(?:supposed|expected)\s+to\s+(.+?)\s+(?:to|for)\s+({names_pattern})(?:\.|$|\s+by|\s+before)',
        # "Agent-7 will deploy to Agent-3"
        rf'({names_pattern})\s+(?:will|shall)\s+(.+?)\s+(?:to|for)\s+({names_pattern})(?:\.|$|\s+by|\s+before)',
    ]

    for pattern in patterns:
        matches = re.findall(pattern, text, re.IGNORECASE)
        for match in matches:
            if len(match) == 3:
                promisor, promisee, description = match
            elif len(match) == 4:
                promisor, promisee, description = match[0], match[2], match[1]
            else:
                continue
            _record_commitment(db, promisor, promisee, description, known_persons)

    for pattern in mid_desc_patterns:
        matches = re.findall(pattern, text, re.IGNORECASE)
        for match in matches:
            if len(match) == 3:
                promisor, description, promisee = match  # swapped
            else:
                continue
            _record_commitment(db, promisor, promisee, description, known_persons)


def _resolve_name(name_variant: str, known_persons: Dict[str, int]) -> Optional[str]:
    """Resolve a name variant to a known person name."""
    name_lower = name_variant.lower()
    # Handle pronouns for the user
    if name_lower in ("i", "me", "my", "myself", "mine"):
        # Find the user in known persons
        for known_name in known_persons:
            p = _get_db().get_person(known_name) if hasattr(_resolve_name, '_db') else None
            if known_name.lower() == "user":
                return known_name
        return "user"
    for known_name in known_persons:
        if known_name.lower() == name_lower:
            return known_name
        if name_lower in known_name.lower() or known_name.lower() in name_lower:
            return known_name
    return None


def _record_commitment(db, promisor: str, promisee: str, description: str,
                       known_persons: Dict[str, int]):
    """Record a detected commitment after resolving names and validating."""
    description = description.strip()
    if not (5 < len(description) < 200):
        return

    promisor_name = _resolve_name(promisor, known_persons)
    promisee_name = _resolve_name(promisee, known_persons)

    if not promisor_name or not promisee_name:
        return
    if promisor_name == promisee_name:
        return  # Don't record self-commitments

    try:
        cid = db.add_commitment(
            from_person=promisor_name,
            to_person=promisee_name,
            description=description,
        )
        logger.info(
            "Auto-detected commitment: %s→%s: %s",
            promisor_name, promisee_name, description[:50]
        )
    except Exception as e:
        logger.debug("Third-party commitment failed: %s", e)


# ===========================================================================
# V3 RELATIONSHIP DETECTION
# ===========================================================================

# Relationship type mapping: phrase → rel_type
_RELATIONSHIP_SIGNALS = {
    # FAMILY
    "married": "spouse", "husband": "spouse", "wife": "spouse",
    "spouse": "spouse",
    "engaged": "engaged", "fiance": "engaged",
    "dating": "dating", "girlfriend": "dating", "boyfriend": "dating",
    "partner": "partner",
    "divorced": "divorced", "ex-wife": "divorced", "ex-husband": "divorced",
    "separated": "separated",
    "parent": "parent_of", "mother": "parent_of", "father": "parent_of",
    "son": "child_of", "daughter": "child_of", "child": "child_of",
    "sibling": "sibling", "brother": "sibling", "sister": "sibling",
    "family": "family",
    # PROFESSIONAL
    "manager": "manager_of", "boss": "manager_of", "supervisor": "manager_of",
    "direct report": "reports_to", "reports to": "reports_to",
    "coworker": "colleague", "colleague": "colleague", "teammate": "colleague",
    "mentor": "mentor_of", "mentee": "mentee_of",
    "business partner": "business_partner",
    "client": "client_of", "customer": "client_of",
    # PERSONAL
    "friend": "friend", "best friend": "close_friend", "close friend": "close_friend",
    "acquaintance": "acquaintance",
    "roommate": "roommate",
    # ADVERSARIAL
    "enemy": "adversarial", "rival": "adversarial",
    "feuding": "adversarial", "feud": "adversarial",
    "estranged": "estranged",
    "hates": "adversarial",
}

# Phrases that indicate a relationship has ENDED/CHANGED
_RELATIONSHIP_END_SIGNALS = [
    r"(?:no longer|not anymore|used to be|formerly|previously)\s+(?:a|an\s+)?({types})",
    r"(?:got|getting|just got)\s+(?:a\s+)?divorced",
    r"(?:broke up|broken up|split up|separated)",
    r"(?:is now|now)\s+(?:my|his|her|their)\s+(?:ex[-\s])",
    r"(?:ended|called off)\s+(?:their|the)\s+(?:marriage|relationship|engagement)",
    r"(?:stepped down|resigned|fired|laid off|quit)\s+(?:as|from)",
]


def _detect_relationships(db, text: str, known_persons: Dict[str, int]):
    """Auto-detect relationship statements from text.

    Detects patterns like:
    - "Alice is my wife"
    - "Bob and Charlie are coworkers"
    - "Diana manages Eve"
    - "Frank and Grace are feuding"
    """
    if not known_persons or len(known_persons) < 2:
        return

    names = list(known_persons.keys())
    names_pattern = '|'.join(re.escape(n) for n in names)
    text_lower = text.lower()

    # Pattern 1: "Alice is my wife" / "Alice is Bob's manager"
    for name in names:
        name_esc = re.escape(name)
        # "Alice is my wife"
        m = re.search(
            rf'{name_esc}\s+(?:is|was|became)\s+(?:my|his|her|their)\s+(\w+)',
            text_lower, re.IGNORECASE
        )
        if m:
            phrase = m.group(1).strip()
            rel_type = _RELATIONSHIP_SIGNALS.get(phrase)
            if rel_type:
                _record_relationship(db, known_persons, name, "user", rel_type)

        # "Alice is a manager" / "Alice became a colleague"
        m = re.search(
            rf'{name_esc}\s+(?:is|was|became)\s+(?:a|an)\s+(\w+)',
            text_lower, re.IGNORECASE
        )
        if m:
            phrase = m.group(1).strip()
            rel_type = _RELATIONSHIP_SIGNALS.get(phrase)
            if rel_type:
                _record_relationship(db, known_persons, name, "user", rel_type)

        # "Alice is Bob's wife/manager/..."
        m = re.search(
            rf'{name_esc}\s+(?:is|was|became)\s+({names_pattern})\'?s?\s+(\w+)',
            text_lower, re.IGNORECASE
        )
        if m:
            other_name = _resolve_name(m.group(1), known_persons)
            phrase = m.group(2).strip()
            rel_type = _RELATIONSHIP_SIGNALS.get(phrase)
            if rel_type and other_name:
                _record_relationship(db, known_persons, name, other_name, rel_type)

    # Pattern 2: "Alice and Bob are married/dating/colleagues"
    # Add "I" as user synonym
    extended_names_pattern = names_pattern + '|I|me'
    types_pattern = '|'.join(re.escape(t) for t in _RELATIONSHIP_SIGNALS.keys())
    m = re.findall(
        rf'({extended_names_pattern})\s+and\s+({extended_names_pattern})\s+(?:are|were|became|got|started)\s+(?:a|an\s+)?({types_pattern})',
        text_lower, re.IGNORECASE
    )
    for match in m:
        name1 = _resolve_name(match[0], known_persons)
        name2 = _resolve_name(match[1], known_persons)
        rel_type = _RELATIONSHIP_SIGNALS.get(match[2])
        if name1 and name2 and rel_type:
            _record_relationship(db, known_persons, name1, name2, rel_type)

    # Pattern 5: "Alice is dating Charlie" / "Alice married Bob"
    # Verbs that describe a relationship + the other person
    for verb, rel_type in [
        ("dating", "dating"), ("married", "spouse"), ("seeing", "dating"),
        ("divorcing", "divorced"), ("leaving", "estranged"),
    ]:
        m = re.findall(
            rf'({names_pattern})\s+(?:is|was|just|recently|started)\s+{verb}\s+({names_pattern})',
            text_lower, re.IGNORECASE
        )
        for name1, name2 in m:
            n1 = _resolve_name(name1, known_persons)
            n2 = _resolve_name(name2, known_persons)
            if n1 and n2:
                _record_relationship(db, known_persons, n1, n2, rel_type)

    # Pattern 3: "Alice manages Bob" / "Diana mentors Charlie"
    for verb, rel_type in [
        ("manages", "manager_of"), ("supervises", "manager_of"),
        ("mentors", "mentor_of"), ("owns", "owns"),
    ]:
        m = re.findall(
            rf'({names_pattern})\s+{verb}\s+({names_pattern})',
            text_lower, re.IGNORECASE
        )
        for name1, name2 in m:
            n1 = _resolve_name(name1, known_persons)
            n2 = _resolve_name(name2, known_persons)
            if n1 and n2:
                _record_relationship(db, known_persons, n1, n2, rel_type)

    # Pattern 4: "Alice reports to Bob"
    m = re.findall(
        rf'({names_pattern})\s+reports?\s+to\s+({names_pattern})',
        text_lower, re.IGNORECASE
    )
    for name1, name2 in m:
        n1 = _resolve_name(name1, known_persons)
        n2 = _resolve_name(name2, known_persons)
        if n1 and n2:
            _record_relationship(db, known_persons, n1, n2, "reports_to")


def _detect_relationship_changes(db, text: str, known_persons: Dict[str, int]):
    """Detect statements indicating relationships have ended or changed.

    Examples:
    - "Alice and Bob got divorced"
    - "Charlie is no longer my manager"
    - "Diana used to be Eve's mentor"
    """
    if not known_persons:
        return

    names = list(known_persons.keys())
    names_pattern = '|'.join(re.escape(n) for n in names)
    extended_names = names_pattern + '|I|me'
    text_lower = text.lower()

    # "Alice and Bob got divorced / broke up"
    m = re.findall(
        rf'({extended_names})\s+and\s+({extended_names})\s+(?:got|are|just got)\s+(?:a\s+)?(divorced|separated)',
        text_lower, re.IGNORECASE
    )
    for name1, name2, _ in m:
        n1 = _resolve_name(name1, known_persons)
        n2 = _resolve_name(name2, known_persons)
        if n1 and n2:
            db.end_relationship(n1, n2, reason="divorce/separation detected")
            logger.info("Relationship ended: %s ↔ %s (divorce/separation)", n1, n2)

# "Alice broke up with Bob"
    m = re.findall(
        rf'({extended_names})\s+broke?\s+up\s+with\s+({extended_names})',
        text_lower, re.IGNORECASE
    )
    for name1, name2 in m:
        n1 = _resolve_name(name1, known_persons)
        n2 = _resolve_name(name2, known_persons)
        if n1 and n2:
            db.end_relationship(n1, n2, reason="breakup detected")
            logger.info("Relationship ended: %s ↔ %s (breakup)", n1, n2)

    # "Alice is no longer Bob's manager" / "Charlie used to be my mentor"
    types_pattern = '|'.join(re.escape(t) for t in _RELATIONSHIP_SIGNALS.keys())
    m = re.findall(
        rf'({extended_names})\s+(?:is\s+)?(?:no longer|not anymore|used to be|formerly)\s+(?:a|an\s+)?(?:({extended_names})\'?s?\s+)?({types_pattern})',
        text_lower, re.IGNORECASE
    )
    for match in m:
        name1 = _resolve_name(match[0], known_persons)
        other = match[1] if match[1] else ""
        rel_type_phrase = match[2] if len(match) > 2 else match[1]
        rel_type = _RELATIONSHIP_SIGNALS.get(rel_type_phrase)
        if name1 and rel_type and other:
            n2 = _resolve_name(other, known_persons)
            if n2:
                db.end_relationship(name1, n2, rel_type=rel_type, reason="ended by statement")

    # "I fired Alice"
    m = re.findall(
        rf'(?:i\s+)?(?:fired|laid off)\s+({names_pattern})',
        text_lower, re.IGNORECASE
    )
    for name in m:
        n = _resolve_name(name if isinstance(name, str) else name[0], known_persons)
        if n:
            db.end_relationship("user", n, reason="employment ended")
            logger.info("Relationship ended: user ↔ %s (fired/laid off)", n)


def _record_relationship(db, known_persons: Dict[str, int],
                          name1: str, name2: str, rel_type: str):
    """Record a detected relationship between two persons."""
    n1 = _resolve_name(name1, known_persons)
    n2 = _resolve_name(name2, known_persons)
    if not n1 or not n2 or n1 == n2:
        return
    try:
        db.upsert_relationship(n1, n2, rel_type, confidence=0.6, source="conversation")
        logger.info("Auto-detected relationship: %s ↔ %s [%s]", n1, n2, rel_type)
    except Exception as e:
        logger.debug("Relationship record failed: %s", e)


def _get_relationship_context(db, person_name: str) -> str:
    """Get a concise relationship summary for context injection."""
    rels = db.get_relationships_for_person(person_name, status="active", limit=5)
    if not rels:
        return ""
    lines = []
    for r in rels:
        other = r["person_b_name"] if r["person_a_name"] == person_name else r["person_a_name"]
        lines.append(f"  {r['rel_type']} of {other} (confidence: {r['confidence']:.0%})")
    return "Relationships:\n" + "\n".join(lines) if lines else ""
