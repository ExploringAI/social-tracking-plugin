"""ToM Pipeline stub for social_tracking v2.

Provides lightweight Theory-of-Mind analysis without external LLM calls.
"""
from dataclasses import dataclass, field
from typing import Optional


@dataclass
class ToMResult:
    emotion: str = "neutral"
    intent: str = "information_request"
    confidence: float = 0.5


@dataclass
class DomainResult:
    suggested_tone: str = "professional"
    social_notes: str = ""
    norms_violated: list = field(default_factory=list)


@dataclass
class PipelineResult:
    tom: ToMResult = field(default_factory=ToMResult)
    domain: DomainResult = field(default_factory=DomainResult)
    response_valid: bool = True
    validation_note: str = ""


class ToMPipeline:
    """Lightweight ToM analysis — no external LLM needed for basic sentiment."""

    def __init__(self, llm_call=None, model: str = "", norms: list = None):
        self.llm_call = llm_call
        self.model = model
        self.norms = norms or []

    def run(self, user_message: str, context_block: str = "") -> PipelineResult:
        """Analyze user message for emotion, intent, and domain context."""
        msg_lower = user_message.lower()

        # Emotion detection
        emotion = "neutral"
        if any(w in msg_lower for w in ["thank", "thanks", "great", "awesome", "love"]):
            emotion = "grateful"
        elif any(w in msg_lower for w in ["angry", "frustrated", "upset", "annoyed"]):
            emotion = "frustrated"
        elif any(w in msg_lower for w in ["worried", "concerned", "nervous", "anxious"]):
            emotion = "concerned"
        elif any(w in msg_lower for w in ["urgent", "asap", "immediately", "emergency"]):
            emotion = "urgent"
        elif any(w in msg_lower for w in ["curious", "wonder", "how", "what if"]):
            emotion = "curious"
        elif any(w in msg_lower for w in ["sad", "disappointed", "sorry", "unfortunately"]):
            emotion = "disappointed"

        # Intent detection
        intent = "information_request"
        if "?" in user_message:
            intent = "question"
        if any(w in msg_lower for w in ["fix", "broken", "error", "bug", "issue"]):
            intent = "problem_report"
        if any(w in msg_lower for w in ["promise", "will do", "i'll", "commit"]):
            intent = "commitment"
        if any(w in msg_lower for w in ["please", "can you", "could you"]):
            intent = "request"

        # Domain analysis
        tone = "professional"
        notes = ""
        if emotion in ("grateful", "curious"):
            tone = "warm"
        elif emotion in ("frustrated", "urgent"):
            tone = "concise and solution-focused"
        elif emotion == "concerned":
            tone = "reassuring"

        if self.norms:
            notes = f"Domain norms active: {', '.join(self.norms[:3])}"

        return PipelineResult(
            tom=ToMResult(emotion=emotion, intent=intent),
            domain=DomainResult(suggested_tone=tone, social_notes=notes),
        )

    def validate_response(self, assistant_response: str,
                          domain: DomainResult) -> tuple:
        """Validate assistant response against domain norms."""
        # Basic validation: check for empty/short responses
        if not assistant_response or len(assistant_response.strip()) < 10:
            return False, "Response too short"
        return True, "OK"
