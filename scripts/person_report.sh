#!/usr/bin/env python3
"""
Hermes Social Tracking Plugin - Person Report
This script generates a report for a specific person.
"""

import sys
import sqlite3
from pathlib import Path
from datetime import datetime, timedelta

def generate_person_report(person_name):
    """Generate a report for a specific person."""
    db_path = Path.home() / ".hermes" / "data" / "social_tracking.db"
    
    if not db_path.exists():
        print(f"Database not found at: {db_path}")
        return False
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        print("\n" + "=" * 60)
        print(f"Social Tracking Report: {person_name}")
        print("=" * 60)
        
        # Get person info
        cursor.execute("SELECT * FROM persons WHERE name = ?", (person_name,))
        person_row = cursor.fetchone()
        
        if not person_row:
            print(f"✗ Person '{person_name}' not found in database")
            return False
        
        person_data = dict(zip([
            "person_id", "name", "roles", "last_active", 
            "trust_score", "kind"
        ], person_row))
        
        print(f"\nBasic Information:")
        print(f"  Name: {person_data['name']}")
        print(f"  Roles: {person_data['roles'] or 'None'}")
        print(f"  Last Active: {person_data['last_active']}")
        print(f"  Trust Score: {person_data['trust_score']:.3f}")
        print(f"  Kind: {person_data['kind']}")
        
        # Get recent events
        one_week_ago = (datetime.now() - timedelta(days=7)).isoformat()
        
        cursor.execute("""
            SELECT e.kind, e.summary, e.timestamp
            FROM events e
            JOIN person_events pe ON e.event_id = pe.event_id
            JOIN persons p ON pe.person_id = p.person_id
            WHERE p.name = ? AND e.timestamp > ?
            ORDER BY e.timestamp DESC
            LIMIT 5
        """, (person_name, one_week_ago))
        
        recent_events = cursor.fetchall()
        if recent_events:
            print(f"\nRecent Events (last 7 days):")
            for kind, summary, timestamp in recent_events:
                print(f"  [{timestamp}] {kind}: {summary}")
        else:
            print(f"\nNo recent events for {person_name}")
        
        # Get commitments
        cursor.execute("""
            SELECT c.description, c.status, c.timestamp_promised, c.due_date
            FROM commitments c
            JOIN commitment_parties cp ON c.commitment_id = cp.commitment_id
            JOIN persons p ON cp.person_id = p.person_id
            WHERE p.name = ?
            ORDER BY c.timestamp_updated DESC
            LIMIT 5
        """, (person_name,))
        
        commitments = cursor.fetchall()
        if commitments:
            print(f"\nRecent Commitments:")
            for desc, status, promised, due in commitments:
                print(f"  {status}: {desc}")
                if due:
                    print(f"    Due: {due}")
                else:
                    print(f"    Promised: {promised}")
        
        conn.close()
        return True
    except Exception as e:
        print(f"✗ Error generating person report: {e}")
        return False

def main():
    print("Hermes Social Tracking Plugin - Person Report")
    print("=" * 60)
    
    if len(sys.argv) < 2:
        print("Usage: scripts/person_report.sh <person_name>")
        print("\nExample: scripts/person_report.sh \"Alice\"")
        return 1
    
    person_name = sys.argv[1]
    success = generate_person_report(person_name)
    
    if success:
        print("\n" + "=" * 60)
        print("✓✓✓ Person report generated successfully! ✓✓✓")
        return 0
    else:
        print("\n" + "=" * 60)
        print("✗✗✗ Failed to generate person report ✗✗✗")
        return 1

if __name__ == "__main__":
    sys.exit(main())