"""Trust manager stub for social_tracking v2.

Wraps the DB's trust operations with the interface expected by __init__.py.
"""
from typing import List, Optional


class TrustManager:
    """Manages trust scores for persons."""

    def __init__(self, db, increment: float = 0.05, decrement: float = 0.05,
                 clamp_min: float = 0.0, clamp_max: float = 1.0):
        self.db = db
        self.increment = increment
        self.decrement = decrement
        self.clamp_min = clamp_min
        self.clamp_max = clamp_max

    def get_trust(self, name: str) -> float:
        """Get trust score for a person by name."""
        person = self.db.get_person(name)
        return float(person["trust_score"]) if person else 0.5

    def trust_summary(self, name: str) -> str:
        """Get a human-readable trust summary."""
        trust = self.get_trust(name)
        if trust >= 0.8:
            level = "high trust"
        elif trust >= 0.6:
            level = "moderate trust"
        elif trust >= 0.4:
            level = "neutral"
        elif trust >= 0.2:
            level = "low trust"
        else:
            level = "very low trust"
        return f"{name}: {trust:.2f} ({level})"

    def adjust(self, person_id: int, delta: float) -> None:
        """Adjust trust for a person by ID."""
        self.db.adjust_trust([person_id], delta)

    def reward(self, person_id: int) -> None:
        """Reward trust (on fulfillment)."""
        self.db.adjust_trust([person_id], self.increment)

    def penalize(self, person_id: int) -> None:
        """Penalize trust (on broken commitment)."""
        self.db.adjust_trust([person_id], -self.decrement)
