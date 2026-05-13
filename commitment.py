"""Commitment tracker stub for social_tracking v2."""
from typing import Optional, List, Dict, Any
import re
import logging

logger = logging.getLogger(__name__)


class CommitmentTracker:
    """Tracks commitments — auto-detection + status management."""

    def __init__(self, db):
        self.db = db

    def maybe_record(self, text: str, promisor_name: str = "assistant",
                     promisee_name: str = "user") -> Optional[str]:
        """Auto-detect and record a commitment from text.

        Returns commitment_id if detected, None otherwise.
        """
        patterns = [
            r"(?:i will|i'll|i promise to|i commit to|i shall)\s+(.+?)(?:\.|$|by|before|until|tomorrow|today|this week|next week)",
            r"(?:i owe you|i need to|i have to|i must|let me)\s+(?:get|do|make|send|write|create|fix|build|deliver|provide|share|review|check|update|deploy)\s+(.+?)(?:\.|$|by|before|until)",
        ]

        text_lower = text.lower()
        for pattern in patterns:
            matches = re.findall(pattern, text_lower, re.IGNORECASE)
            if matches:
                desc = matches[0].strip()
                if 5 < len(desc) < 200:
                    try:
                        return str(self.db.add_commitment(
                            from_person=promisor_name,
                            to_person=promisee_name,
                            description=desc,
                        ))
                    except Exception as e:
                        logger.warning("maybe_record failed: %s", e)
        return None

    def pending_summary(self) -> str:
        """Get summary of all pending/broken commitments."""
        try:
            conn = self.db._connect()
            cur = conn.cursor()
            cur.execute("""
                SELECT c.commitment_id, c.description, c.status,
                       p_from.name, p_to.name
                FROM commitments c
                JOIN commitment_parties cp_from ON c.commitment_id = cp_from.commitment_id AND cp_from.role = 'maker'
                JOIN persons p_from ON cp_from.person_id = p_from.person_id
                JOIN commitment_parties cp_to ON c.commitment_id = cp_to.commitment_id AND cp_to.role = 'target'
                JOIN persons p_to ON cp_to.person_id = p_to.person_id
                WHERE c.status IN ('pending', 'broken')
                ORDER BY c.status DESC
                LIMIT 20
            """)
            rows = cur.fetchall()
            self.db._close(conn)

            if not rows:
                return "No pending or broken commitments."

            lines = []
            for r in rows:
                icon = "BROKEN" if r[2] == "broken" else "PENDING"
                lines.append(f"  #{r[0]} [{icon}] {r[3]} → {r[4]}: {r[1][:100]}")
            return "\n".join(lines)
        except Exception as e:
            logger.debug("pending_summary failed: %s", e)
            return "Unable to retrieve commitments."

    def mark_fulfilled(self, commitment_id: str, fulfiller_name: str = "assistant") -> Dict[str, Any]:
        """Mark a commitment as fulfilled."""
        return self.db.update_commitment_status(int(commitment_id), "fulfilled")
