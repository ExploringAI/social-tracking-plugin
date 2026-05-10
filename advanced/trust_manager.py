"""Dynamic trust management for social tracking."""

from __future__ import annotations
from typing import Optional, List, Dict, Any
import logging
from datetime import datetime

# Simplified version - uses CoreDB directly
from core.db import CoreDB


class TrustManager:
    """Manages trust scores for persons in the social graph."""
    
    def __init__(self, db_path: str):
        self.db_path = db_path
        self.db = CoreDB(db_path)
        self.logger = logging.getLogger(__name__)
        
    def initialize(self) -> None:
        """Initialize the trust management system."""
        self.db.init_db()
        
    def upsert_person(self, name: str, roles: Optional[List[str]] = None) -> int:
        """Add or update a person."""
        return self.db.upsert_person(name, roles)
    
    def get_person(self, name: str) -> Optional[Dict[str, Any]]:
        """Get person record."""
        return self.db.get_person(name)
    
    def adjust_trust_for_person(self, name: str, delta: float) -> None:
        """Adjust trust for a specific person."""
        person = self.db.get_person(name)
        if not person:
            return
        person_id = person["person_id"]
        self.db.adjust_trust([person_id], delta)
    
    def get_trust_score(self, name: str) -> float:
        """Get current trust score for a person."""
        person = self.db.get_person(name)
        return float(person["trust_score"]) if person else 0.5
    
    def set_trust_score(self, name: str, score: float) -> None:
        """Set trust score directly (use with caution)."""
        if not 0.0 <= score <= 1.0:
            raise ValueError("Trust score must be between 0.0 and 1.0")
        person = self.db.get_person(name)
        if person:
            person_id = person["person_id"]
            now = datetime.utcnow().isoformat(timespec="seconds") + "Z"
            conn = self.db._connect(reuse=False)
            cur = conn.cursor()
            cur.execute(
                "UPDATE persons SET trust_score = ?, last_active = ? WHERE person_id = ?",
                (score, now, person_id),
            )
            conn.commit()
            self.db._close(conn)
    
    def batch_adjust_trust(self, adjustments: List[Tuple[str, float]]) -> None:
        """Adjust trust for multiple persons at once."""
        person_ids = []
        name_to_id = {}
        
        # Get person IDs
        for name, delta in adjustments:
            person = self.db.get_person(name)
            if person:
                person_ids.append((person["person_id"], delta))
                name_to_id[name] = person["person_id"]
        
        # Adjust trust
        if person_ids:
            self.db.adjust_trust([pid for pid, _ in person_ids], sum(delta for _, delta in person_ids))
