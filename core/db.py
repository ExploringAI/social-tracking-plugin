"""Core SQLite schema and operations for social tracking."""

from __future__ import annotations
from typing import Optional, List, Dict, Any, Tuple
import sqlite3
from pathlib import Path
from datetime import datetime


class CoreDB:
    """Thin wrapper around SQLite with social tracking schema."""
    
    def __init__(self, db_path: str | Path):
        self.db_path = str(db_path)
        self._conn: Optional[sqlite3.Connection] = None
        
    def _connect(self, reuse: bool = False) -> sqlite3.Connection:
        """Get a database connection.
        
        Args:
            reuse: If True and a connection already exists, reuse it.
                  If False, always create a new connection.
                  
        Returns:
            sqlite3.Connection
        """
        if reuse and self._conn:
            return self._conn
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        return conn
    
    def _close(self, conn: sqlite3.Connection, commit: bool = True) -> None:
        """Close the database connection."""
        if commit:
            conn.commit()
        conn.close()
    
    def init_db(self) -> None:
        """Create tables if they do not exist.
        
        Tables:
          - persons: known individuals with trust scores
          - events: social interactions and events
          - commitments: promises and expectations
        """
        conn = self._connect(reuse=False)
        cur = conn.cursor()
        
        cur.executescript(self._schema())
        self._close(conn)
        
    def _schema(self) -> str:
        """Return the SQL schema for the social tracking database."""
        return """
        CREATE TABLE IF NOT EXISTS persons (
            person_id    INTEGER PRIMARY KEY AUTOINCREMENT,
            name         TEXT NOT NULL UNIQUE,
            roles        TEXT,
            last_active  TEXT,
            trust_score  REAL NOT NULL DEFAULT 0.5
        );
        
        CREATE TABLE IF NOT EXISTS events (
            event_id   INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp  TEXT NOT NULL,
            kind       TEXT,
            summary    TEXT
        );
        
        CREATE TABLE IF NOT EXISTS person_events (
            person_id  INTEGER NOT NULL,
            event_id   INTEGER NOT NULL,
            PRIMARY KEY (person_id, event_id),
            FOREIGN KEY (person_id) REFERENCES persons(person_id) ON DELETE CASCADE,
            FOREIGN KEY (event_id) REFERENCES events(event_id)   ON DELETE CASCADE
        );
        
        CREATE TABLE IF NOT EXISTS commitments (
            commitment_id      INTEGER PRIMARY KEY AUTOINCREMENT,
            description        TEXT NOT NULL,
            status             TEXT NOT NULL CHECK(status IN ('pending','fulfilled','broken')),
            timestamp_promised TEXT NOT NULL,
            due_date           TEXT,
            timestamp_updated  TEXT NOT NULL
        );
        
        CREATE TABLE IF NOT EXISTS commitment_parties (
            commitment_id  INTEGER NOT NULL,
            role           TEXT NOT NULL, -- 'maker' or 'target' or 'other'
            person_id      INTEGER NOT NULL,
            PRIMARY KEY (commitment_id, role, person_id),
            FOREIGN KEY (commitment_id) REFERENCES commitments(commitment_id) ON DELETE CASCADE,
            FOREIGN KEY (person_id) REFERENCES persons(person_id) ON DELETE CASCADE
        );
        
        CREATE TABLE IF NOT EXISTS meta (
            key    TEXT PRIMARY KEY,
            value  TEXT
        );
        
        CREATE INDEX IF NOT EXISTS idx_person_name ON persons(name);
        CREATE INDEX IF NOT EXISTS idx_event_time ON events(timestamp);
        CREATE INDEX IF NOT EXISTS idx_commitment_status ON commitments(status);
        CREATE INDEX IF NOT EXISTS idx_commitment_updated ON commitments(timestamp_updated);
        """
    
    # --- Meta helpers ---
    
    def get_primary_user_name(self, conn: Optional[sqlite3.Connection] = None) -> str:
        """Get the name of the primary user."""
        commit = False
        if conn is None:
            conn = self._connect(reuse=False)
            commit = True
        cur = conn.cursor()
        cur.execute("SELECT value FROM meta WHERE key = 'primary_user_name'")
        row = cur.fetchone()
        if commit:
            self._close(conn)
        return row[0] if row and row[0] else "User"
    
    def set_primary_user_name(self, name: str, conn: Optional[sqlite3.Connection] = None) -> None:
        """Set the name of the primary user."""
        commit = False
        if conn is None:
            conn = self._connect(reuse=False)
            commit = True
        cur = conn.cursor()
        cur.execute(
            "INSERT INTO meta(key, value) VALUES('primary_user_name', ?) "
            "ON CONFLICT(key) DO UPDATE SET value=excluded.value",
            (name,),
        )
        if commit:
            conn.commit()
            self._close(conn)
    
    # --- Person helpers ---
    
    def upsert_person(self, name: str, roles: Optional[List[str]] = None, conn: Optional[sqlite3.Connection] = None) -> int:
        """Insert or update a person, returning their ID.
        
        Args:
            name: Person's name
            roles: Optional list of role labels (e.g., ['friend', 'coworker'])
            conn: Optional existing connection to reuse
            
        Returns:
            person_id
        """
        commit = False
        if conn is None:
            conn = self._connect(reuse=False)
            commit = True
        cur = conn.cursor()
        roles_str = ",".join(roles) if roles else None
        now = datetime.utcnow().isoformat(timespec="seconds") + "Z"
        
        cur.execute(
            "INSERT INTO persons(name, roles, last_active) VALUES(?,?,?) "
            "ON CONFLICT(name) DO UPDATE SET roles=COALESCE(?, persons.roles), last_active=?",
            (name, roles_str, now, roles_str, now),
        )
        
        cur.execute("SELECT person_id FROM persons WHERE name = ?", (name,))
        row = cur.fetchone()
        if commit:
            conn.commit()
            self._close(conn)
        return int(row[0])
    
    def get_person(self, name: str, conn: Optional[sqlite3.Connection] = None) -> Optional[Dict[str, Any]]:
        """Get person record by name.
        
        Args:
            name: Person's name
            conn: Optional existing connection to reuse
            
        Returns:
            Person dictionary or None if not found
        """
        commit = False
        if conn is None:
            conn = self._connect(reuse=False)
            commit = True
        cur = conn.cursor()
        cur.execute("SELECT * FROM persons WHERE name = ?", (name,))
        row = cur.fetchone()
        if commit:
            self._close(conn)
        if not row:
            return None
        return dict(row)
    
    def adjust_trust(self, person_ids: List[int], delta: float, conn: Optional[sqlite3.Connection] = None) -> None:
        """Adjust trust score for multiple persons.
        
        Args:
            person_ids: List of person IDs
            delta: Amount to adjust trust (can be positive or negative)
            conn: Optional existing connection to reuse
        """
        commit = False
        if conn is None:
            conn = self._connect(reuse=False)
            commit = True
        cur = conn.cursor()
        for pid in person_ids:
            cur.execute("SELECT trust_score FROM persons WHERE person_id = ?", (pid,))
            row = cur.fetchone()
            if not row:
                continue
            current = float(row[0])
            new_val = max(0.0, min(1.0, current + delta))
            cur.execute(
                "UPDATE persons SET trust_score = ?, last_active = ? WHERE person_id = ?",
                (new_val, datetime.utcnow().isoformat(timespec="seconds") + "Z", pid),
            )
        if commit:
            conn.commit()
            self._close(conn)
    
    # --- Event helpers ---
    
    def record_event(self, summary: str, kind: str = "chat_turn", persons: Optional[List[str]] = None, conn: Optional[sqlite3.Connection] = None) -> int:
        """Record an event and optionally link persons to it.
        
        Args:
            summary: Brief description of the event
            kind: Event type label (e.g., 'chat', 'meeting', 'conflict')
            persons: Optional list of person names to associate
            conn: Optional existing connection to reuse
            
        Returns:
            event_id
        """
        commit = False
        if conn is None:
            conn = self._connect(reuse=False)
            commit = True
        cur = conn.cursor()
        ts = datetime.utcnow().isoformat(timespec="seconds") + "Z"
        
        cur.execute(
            "INSERT INTO events(timestamp, kind, summary) VALUES(?,?,?)",
            (ts, kind, summary),
        )
        event_id = cur.lastrowid
        
        if persons:
            for name in persons:
                pid = self.upsert_person(name, conn=conn)
                cur.execute(
                    "INSERT OR IGNORE INTO person_events(person_id, event_id) VALUES(?,?)",
                    (pid, event_id),
                )
        
        if commit:
            conn.commit()
            self._close(conn)
        return int(event_id)
    
    def get_recent_events_for_person(self, name: str, limit: int = 5, conn: Optional[sqlite3.Connection] = None) -> List[Dict[str, Any]]:
        """Get recent events for a person.
        
        Args:
            name: Person's name
            limit: Maximum number of events to return
            conn: Optional existing connection to reuse
            
        Returns:
            List of event dictionaries
        """
        commit = False
        if conn is None:
            conn = self._connect(reuse=False)
            commit = True
        cur = conn.cursor()
        
        # Find person ID
        cur.execute("SELECT person_id FROM persons WHERE name = ?", (name,))
        row = cur.fetchone()
        if not row:
            if commit:
                self._close(conn)
            return []
        
        pid = int(row[0])
        
        # Get recent events
        cur.execute(
            """SELECT e.event_id, e.timestamp, e.kind, e.summary
            FROM events e
            JOIN person_events pe ON pe.event_id = e.event_id
            WHERE pe.person_id = ?
            ORDER BY e.timestamp DESC
            LIMIT ?""",
            (pid, limit),
        )
        
        rows = [dict(r) for r in cur.fetchall()]
        if commit:
            self._close(conn)
        return rows
    
    # --- Commitment helpers ---
    
    def add_commitment(
        self, 
        from_person: str, 
        to_person: str, 
        description: str, 
        due_date: Optional[str] = None,
        conn: Optional[sqlite3.Connection] = None
    ) -> int:
        """Add a new commitment between two persons.
        
        Args:
            from_person: Who made the commitment
            to_person: Who it was made to
            description: What was promised
            due_date: Optional ISO date string
            conn: Optional existing connection to reuse
            
        Returns:
            commitment_id
        """
        commit = False
        if conn is None:
            conn = self._connect(reuse=False)
            commit = True
        cur = conn.cursor()
        now = datetime.utcnow().isoformat(timespec="seconds") + "Z"
        
        cur.execute(
            "INSERT INTO commitments(description, status, timestamp_promised, due_date, timestamp_updated) "
            "VALUES(?,?,?,?,?)",
            (description, "pending", now, due_date, now),
        )
        cid = cur.lastrowid
        
        maker_id = self.upsert_person(from_person, conn=conn)
        target_id = self.upsert_person(to_person, conn=conn)
        
        cur.execute(
            "INSERT OR IGNORE INTO commitment_parties(commitment_id, role, person_id) VALUES(?,?,?)",
            (cid, "maker", maker_id),
        )
        cur.execute(
            "INSERT OR IGNORE INTO commitment_parties(commitment_id, role, person_id) VALUES(?,?,?)",
            (cid, "target", target_id),
        )
        
        if commit:
            conn.commit()
            self._close(conn)
        return int(cid)
    
    def update_commitment_status(
        self, 
        commitment_id: int, 
        status: str, 
        fulfilled_by: Optional[str] = None,
        conn: Optional[sqlite3.Connection] = None
    ) -> Dict[str, Any]:
        """Update commitment status and adjust trust if needed.
        
        Args:
            commitment_id: ID of the commitment
            status: New status ('pending', 'fulfilled', 'broken')
            fulfilled_by: Optional name of who fulfilled it
            conn: Optional existing connection to reuse
            
        Returns:
            Updated commitment record with maker/target IDs
        """
        if status not in {"pending", "fulfilled", "broken"}:
            raise ValueError("invalid status")
        
        commit = False
        if conn is None:
            conn = self._connect(reuse=False)
            commit = True
        cur = conn.cursor()
        now = datetime.utcnow().isoformat(timespec="seconds") + "Z"
        
        cur.execute(
            "UPDATE commitments SET status = ?, timestamp_updated = ? WHERE commitment_id = ?",
            (status, now, commitment_id),
        )
        
        cur.execute(
            "SELECT commitment_id, description, status, timestamp_promised, due_date, timestamp_updated "
            "FROM commitments WHERE commitment_id = ?",
            (commitment_id,),
        )
        row = cur.fetchone()
        
        if not row:
            if commit:
                self._close(conn)
            raise ValueError("commitment not found")
        
        # Get parties involved
        cur.execute(
            "SELECT person_id, role FROM commitment_parties WHERE commitment_id = ?",
            (commitment_id,),
        )
        parties = cur.fetchall()
        maker_ids = [int(r[0]) for r in parties if r[1] == "maker"]
        target_ids = [int(r[0]) for r in parties if r[1] == "target"]
        
        if commit:
            conn.commit()
            self._close(conn)
        
        # Adjust trust based on outcome
        if status == "fulfilled":
            # Maker gains trust
            self.adjust_trust(maker_ids, 0.05)
        elif status == "broken":
            # Maker loses trust
            self.adjust_trust(maker_ids, -0.10)
        
        result = dict(row)
        result["maker_ids"] = maker_ids
        result["target_ids"] = target_ids
        return result
    
    def get_open_commitments_for_person(self, name: str, limit: int = 10, conn: Optional[sqlite3.Connection] = None) -> List[Dict[str, Any]]:
        """Get open commitments involving a person.
        
        Args:
            name: Person's name
            limit: Maximum number to return
            conn: Optional existing connection to reuse
            
        Returns:
            List of commitment dictionaries
        """
        commit = False
        if conn is None:
            conn = self._connect(reuse=False)
            commit = True
        cur = conn.cursor()
        
        cur.execute("SELECT person_id FROM persons WHERE name = ?", (name,))
        row = cur.fetchone()
        if not row:
            if commit:
                self._close(conn)
            return []
        
        pid = int(row[0])
        
        cur.execute(
            """SELECT c.commitment_id, c.description, c.status, c.timestamp_promised, c.due_date
            FROM commitments c
            JOIN commitment_parties cp ON cp.commitment_id = c.commitment_id
            WHERE cp.person_id = ? AND c.status IN ('pending', 'broken')
            ORDER BY c.timestamp_updated DESC
            LIMIT ?""",
            (pid, limit),
        )
        
        rows = [dict(r) for r in cur.fetchall()]
        if commit:
            self._close(conn)
        return rows
    
    def summarize_context_for_person(self, name: str, limit: int = 5, conn: Optional[sqlite3.Connection] = None) -> str:
        """Generate a social context summary for a person.
        
        Args:
            name: Person's name
            limit: Max recent events to include
            conn: Optional existing connection to reuse
            
        Returns:
            Formatted context string
        """
        person = self.get_person(name, conn=conn)
        events = self.get_recent_events_for_person(name, limit=limit, conn=conn)
        commitments = self.get_open_commitments_for_person(name, limit=limit, conn=conn)
        
        lines = []
        lines.append(f"Social memory for {name}:")
        
        if person:
            roles = person.get("roles") or ""
            roles_str = roles if roles else ""
            trust = float(person.get("trust_score", 0.5))
            last_active = person.get("last_active") or "unknown"
            
            if roles_str:
                lines.append(f"- Roles: {roles_str}.")
            lines.append(f"- Trust score: {trust:.2f} (0=low, 1=high).")
            lines.append(f"- Last active: {last_active}.")
        else:
            lines.append("- (No existing record; this person is new to the social graph.)")
        
        if events:
            lines.append("- Recent interactions:")
            for ev in events:
                ts = ev.get("timestamp", "?")
                kind = ev.get("kind") or "event"
                summary = (ev.get("summary") or "").strip()
                if len(summary) > 220:
                    summary = summary[:217] + "..."
                lines.append(f"  - [{ts}] ({kind}) {summary}")
        else:
            lines.append("- No recent interactions recorded.")
        
        if commitments:
            lines.append("- Notable commitments involving this person:")
            for c in commitments:
                cid = c.get("commitment_id")
                desc = (c.get("description") or "").strip()
                status = c.get("status")
                due = c.get("due_date") or "unspecified due date"
                lines.append(f"  - #{cid} [{status}] due {due}: {desc}")
        else:
            lines.append("- No pending or broken commitments recorded.")
        
        return "\n".join(lines)
