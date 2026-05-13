"""Core SQLite schema and operations for social tracking."""

from __future__ import annotations
from typing import Optional, List, Dict, Any, Tuple
import sqlite3
from pathlib import Path
from datetime import datetime


class CoreDB:
    """Thin wrapper around SQLite with social tracking schema."""
    
    def __init__(self, db_path: str | Path):
        self.db_path = str(Path(db_path).expanduser())
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
    
    def connect(self) -> None:
        """Open DB and initialize schema. Public API for plugin register()."""
        self._connect(reuse=False)
        self.init_db()

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
            trust_score  REAL NOT NULL DEFAULT 0.5,
            kind         TEXT NOT NULL DEFAULT 'human'
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
        
        CREATE TABLE IF NOT EXISTS relationships (
            relationship_id INTEGER PRIMARY KEY AUTOINCREMENT,
            person_a_id     INTEGER NOT NULL,
            person_b_id     INTEGER NOT NULL,
            rel_type        TEXT NOT NULL,
            strength        REAL NOT NULL DEFAULT 0.5,
            status          TEXT NOT NULL DEFAULT 'active',
            started_at      TEXT,
            ended_at        TEXT,
            source          TEXT DEFAULT 'conversation',
            confidence      REAL NOT NULL DEFAULT 0.5,
            notes           TEXT,
            created_at      TEXT NOT NULL,
            updated_at      TEXT NOT NULL,
            FOREIGN KEY (person_a_id) REFERENCES persons(person_id) ON DELETE CASCADE,
            FOREIGN KEY (person_b_id) REFERENCES persons(person_id) ON DELETE CASCADE
        );
        CREATE INDEX IF NOT EXISTS idx_rel_persons ON relationships(person_a_id, person_b_id);
        CREATE INDEX IF NOT EXISTS idx_rel_status ON relationships(status);
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

    def create_event(self, kind: str, context_notes: str = "",
                     persons: Optional[List[str]] = None,
                     conn: Optional[sqlite3.Connection] = None) -> int:
        """Backward-compatible alias for :meth:`record_event`.

        Older plugin revisions call ``create_event(kind, context_notes=...)``.
        We map that to ``record_event`` while preserving the event ``kind``
        and embedding any ``context_notes`` into the summary payload.
        """

        summary = context_notes or kind
        return self.record_event(summary=summary, kind=kind,
                                 persons=persons, conn=conn)

    # --- Person helpers ---

    def upsert_person(self, name: str, roles: Optional[List[str]] = None,
                       kind: str = "human", conn: Optional[sqlite3.Connection] = None) -> int:
        """Insert or update a person, returning their ID.
        
        Args:
            name: Person's name
            roles: Optional list of role labels (e.g., ['friend', 'coworker'])
            kind: Entity kind — 'human', 'agent', or 'user'
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
            "INSERT INTO persons(name, roles, last_active, kind) VALUES(?,?,?,?) "
            "ON CONFLICT(name) DO UPDATE SET "
            "roles=COALESCE(?, persons.roles), "
            "last_active=?, "
            "kind=CASE WHEN persons.kind = 'human' AND ? != 'human' THEN ? ELSE persons.kind END",
            (name, roles_str, now, kind, roles_str, now, kind, kind),
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

    def upsert_edge(self, source_id: Any, target_id: Any,
                    edge_type: str, weight: float = 1.0,
                    conn: Optional[sqlite3.Connection] = None) -> None:
        """Compatibility shim for legacy graph edges.

        The current schema does not persist arbitrary edges between
        memories/events and persons.  Treat the call as a no-op so
        upstream plugin logic continues to run without raising.
        """

        return None

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

        # V3: Include relationships
        rels = self.get_relationships_for_person(name, status="active", limit=5, conn=conn)
        if rels:
            lines.append("- Active relationships:")
            for r in rels:
                other = r["person_b_name"] if r["person_a_name"] == name else r["person_a_name"]
                lines.append(f"  - {r['rel_type']} with {other} (strength: {r['strength']:.2f}, confidence: {r['confidence']:.2f})")
        
        return "\n".join(lines)

    # --- Relationship helpers ---

    def upsert_relationship(
        self,
        person_a: str,
        person_b: str,
        rel_type: str,
        strength: float = 0.5,
        confidence: float = 0.5,
        source: str = "conversation",
        notes: str = "",
        conn: Optional[sqlite3.Connection] = None
    ) -> int:
        """Create or update a relationship between two persons.

        When new info contradicts an existing relationship (same persons,
        different type), the old one is marked 'ended' and a new one is
        created. Same-type relationships are updated (strength/confidence).

        Returns: relationship_id
        """
        if person_a.lower() == person_b.lower():
            raise ValueError("Cannot create self-relationship")

        commit = False
        if conn is None:
            conn = self._connect(reuse=False)
            commit = True
        cur = conn.cursor()
        now = datetime.utcnow().isoformat(timespec="seconds") + "Z"

        # Resolve person IDs (order doesn't matter — normalize)
        pid_a = self.upsert_person(person_a, conn=conn)
        pid_b = self.upsert_person(person_b, conn=conn)

        # Normalize: always store lower ID as person_a
        if pid_a > pid_b:
            pid_a, pid_b = pid_b, pid_a
            person_a, person_b = person_b, person_a

        # Check for existing active relationship of SAME type
        cur.execute(
            """SELECT relationship_id, rel_type, status, confidence
               FROM relationships
               WHERE person_a_id = ? AND person_b_id = ? AND rel_type = ? AND status = 'active'""",
            (pid_a, pid_b, rel_type)
        )
        existing = cur.fetchone()

        if existing:
            # Update existing — bump confidence if new info agrees
            new_conf = min(1.0, float(existing["confidence"]) + 0.1)
            cur.execute(
                """UPDATE relationships
                   SET strength = ?, confidence = ?, notes = ?, updated_at = ?
                   WHERE relationship_id = ?""",
                (strength, max(float(existing["confidence"]), confidence),
                 notes, now, existing["relationship_id"])
            )
            rid = existing["relationship_id"]
        else:
            # Check for CONTRADICTING active relationship (different type)
            cur.execute(
                """SELECT relationship_id, rel_type
                   FROM relationships
                   WHERE person_a_id = ? AND person_b_id = ?
                     AND status = 'active'
                     AND rel_type != ?""",
                (pid_a, pid_b, rel_type)
            )
            contradictions = cur.fetchall()

            for cont in contradictions:
                # End the old relationship — new info supersedes it
                cur.execute(
                    """UPDATE relationships
                       SET status = 'ended', ended_at = ?, updated_at = ?
                       WHERE relationship_id = ?""",
                    (now, now, cont["relationship_id"])
                )

            # Create new relationship
            cur.execute(
                """INSERT INTO relationships
                   (person_a_id, person_b_id, rel_type, strength, status,
                    started_at, source, confidence, notes, created_at, updated_at)
                   VALUES (?, ?, ?, ?, 'active', ?, ?, ?, ?, ?, ?)""",
                (pid_a, pid_b, rel_type, strength, now, source, confidence, notes, now, now)
            )
            rid = cur.lastrowid

        if commit:
            conn.commit()
            self._close(conn)
        return int(rid)

    def end_relationship(
        self,
        person_a: str,
        person_b: str,
        rel_type: Optional[str] = None,
        reason: str = "",
        conn: Optional[sqlite3.Connection] = None
    ) -> int:
        """End a relationship. If rel_type is None, ends all active relationships
        between these two persons. Returns count of ended relationships."""
        commit = False
        if conn is None:
            conn = self._connect(reuse=False)
            commit = True
        cur = conn.cursor()
        now = datetime.utcnow().isoformat(timespec="seconds") + "Z"

        pa = self.get_person(person_a)
        pb = self.get_person(person_b)
        if not pa or not pb:
            if commit: self._close(conn)
            return 0

        pid_a, pid_b = pa["person_id"], pb["person_id"]
        if pid_a > pid_b:
            pid_a, pid_b = pid_b, pid_a

        if rel_type:
            cur.execute(
                """UPDATE relationships
                   SET status = 'ended', ended_at = ?, updated_at = ?, notes = ?
                   WHERE person_a_id = ? AND person_b_id = ?
                     AND rel_type = ? AND status = 'active'""",
                (now, now, f"ended: {reason}" if reason else "ended", pid_a, pid_b, rel_type)
            )
        else:
            cur.execute(
                """UPDATE relationships
                   SET status = 'ended', ended_at = ?, updated_at = ?, notes = ?
                   WHERE person_a_id = ? AND person_b_id = ?
                     AND status = 'active'""",
                (now, now, f"ended: {reason}" if reason else "ended", pid_a, pid_b)
            )

        count = cur.rowcount
        if commit:
            conn.commit()
            self._close(conn)
        return count

    def get_relationships_for_person(
        self,
        name: str,
        status: str = "active",
        limit: int = 10,
        conn: Optional[sqlite3.Connection] = None
    ) -> List[Dict[str, Any]]:
        """Get relationships involving a person."""
        commit = False
        if conn is None:
            conn = self._connect(reuse=False)
            commit = True
        cur = conn.cursor()

        person = self.get_person(name, conn=conn)
        if not person:
            if commit: self._close(conn)
            return []

        pid = person["person_id"]

        cur.execute(
            """SELECT r.relationship_id, r.rel_type, r.strength, r.status,
                      r.confidence, r.notes, r.started_at, r.ended_at,
                      p_a.name as person_a_name, p_b.name as person_b_name,
                      p_a.kind as person_a_kind, p_b.kind as person_b_kind
               FROM relationships r
               JOIN persons p_a ON r.person_a_id = p_a.person_id
               JOIN persons p_b ON r.person_b_id = p_b.person_id
               WHERE (r.person_a_id = ? OR r.person_b_id = ?)
                 AND r.status = ?
               ORDER BY r.strength DESC, r.updated_at DESC
               LIMIT ?""",
            (pid, pid, status, limit)
        )

        rows = [dict(r) for r in cur.fetchall()]
        if commit:
            self._close(conn)
        return rows

    def get_relationship_history(
        self,
        person_a: str,
        person_b: str,
        conn: Optional[sqlite3.Connection] = None
    ) -> List[Dict[str, Any]]:
        """Get full relationship history between two persons (including ended)."""
        commit = False
        if conn is None:
            conn = self._connect(reuse=False)
            commit = True
        cur = conn.cursor()

        pa = self.get_person(person_a)
        pb = self.get_person(person_b)
        if not pa or not pb:
            if commit: self._close(conn)
            return []

        pid_a, pid_b = pa["person_id"], pb["person_id"]
        if pid_a > pid_b:
            pid_a, pid_b = pid_b, pid_a

        cur.execute(
            """SELECT r.*, p_a.name as person_a_name, p_b.name as person_b_name
               FROM relationships r
               JOIN persons p_a ON r.person_a_id = p_a.person_id
               JOIN persons p_b ON r.person_b_id = p_b.person_id
               WHERE r.person_a_id = ? AND r.person_b_id = ?
               ORDER BY r.started_at DESC""",
            (pid_a, pid_b)
        )

        rows = [dict(r) for r in cur.fetchall()]
        if commit:
            self._close(conn)
        return rows

# Alias for compatibility
SocialDB = CoreDB
