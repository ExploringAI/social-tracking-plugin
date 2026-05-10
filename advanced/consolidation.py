"""Background consolidation jobs for social tracking."""

from __future__ import annotations
from typing import Optional, List, Dict, Any
import time
import threading
import logging

from core.db import CoreDB


class ConsolidationWorker:
    """Background worker for periodic social graph consolidation."""
    
    def __init__(self, db_path: str, interval: int = 60):
        self.db_path = db_path
        self.db = CoreDB(db_path)
        self.interval = interval  # seconds
        self.running = False
        self.thread: Optional[threading.Thread] = None
        self.logger = self._setup_logger()
        
    def _setup_logger(self):
        """Setup a simple logger."""
        logger = logging.getLogger(__name__)
        handler = logging.StreamHandler()
        formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
        handler.setFormatter(formatter)
        logger.addHandler(handler)
        logger.setLevel(logging.INFO)
        return logger
    
    def _consolidate_trust(self) -> None:
        """Consolidate trust scores based on recent commitments."""
        self.logger.info("Running trust consolidation")
        conn = self.db._connect(reuse=False)
        cur = conn.cursor()
        
        # Get recent commitments
        cur.execute(
            "SELECT c.commitment_id, c.status, GROUP_CONCAT(cp.role) "
            "FROM commitments c "
            "JOIN commitment_parties cp ON cp.commitment_id = c.commitment_id "
            "WHERE c.timestamp_updated > datetime('now', '-1 day') "
            "GROUP BY c.commitment_id"
        )
        
        recent_comms = cur.fetchall()
        for comm in recent_comms:
            comm_id, status, roles_str = comm
            roles = roles_str.split(",") if roles_str else []
            
            if status == "fulfilled":
                # Find makers and increase trust
                maker_count = roles.count("maker")
                if maker_count > 0:
                    # Simple boost
                    self.db.adjust_trust([self.db.upsert_person("Maker")], 0.01)
            elif status == "broken":
                # Find makers and decrease trust
                maker_count = roles.count("maker")
                if maker_count > 0:
                    self.db.adjust_trust([self.db.upsert_person("Maker")], -0.05)
        
        self.db._close(conn)
    
    def _expire_old_commitments(self) -> None:
        """Expire commitments that are past their due date."""
        self.logger.info("Expiring old commitments")
        conn = self.db._connect(reuse=False)
        cur = conn.cursor()
        
        cur.execute(
            "UPDATE commitments SET status = 'broken' "
            "WHERE due_date IS NOT NULL AND due_date < datetime('now') "
            "AND status = 'pending'"
        )
        
        expired_count = conn.total_changes
        if expired_count > 0:
            self.logger.info(f"Expired {expired_count} overdue commitments")
        
        conn.commit()
        self.db._close(conn)
    
    def _consolidate_loop(self) -> None:
        """Main consolidation loop."""
        while self.running:
            try:
                self._consolidate_trust()
                self._expire_old_commitments()
            except Exception as e:
                self.logger.error(f"Consolidation error: {e}")
            time.sleep(self.interval)
    
    def start(self) -> None:
        """Start the consolidation worker."""
        if self.running:
            return
        self.running = True
        self.thread = threading.Thread(target=self._consolidate_loop, daemon=True)
        self.thread.start()
        self.logger.info(f"Consolidation worker started with interval {self.interval} seconds")
    
    def stop(self) -> None:
        """Stop the consolidation worker."""
        if not self.running:
            return
        self.running = False
        if self.thread:
            self.thread.join(timeout=5)
        self.logger.info("Consolidation worker stopped")
    
    def run_once(self) -> None:
        """Run one consolidation cycle."""
        self._consolidate_trust()
        self._expire_old_commitments()


def main():
    """Test the consolidation worker."""
    print("Testing Consolidation Worker...")
    worker = ConsolidationWorker(db_path="/tmp/test_social.db")
    worker.initialize()
    
    # Add some test data
    worker.db.upsert_person("Marko")
    worker.db.upsert_person("Alice")
    
    # Run one cycle
    worker.run_once()
    print("✓ Consolidation worker ran successfully")
    
    # Check results
    marko = worker.db.get_person("Marko")
    alice = worker.db.get_person("Alice")
    print(f"Marko trust: {marko['trust_score']:.2f}")
    print(f"Alice trust: {alice['trust_score']:.2f}")


if __name__ == "__main__":
    main()
