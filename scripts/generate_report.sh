#!/usr/bin/env python3
"""
Hermes Social Tracking Plugin - Social Report Script
This script generates a social report/summary.
"""

import sys
import sqlite3
from pathlib import Path
from datetime import datetime, timedelta

def generate_social_report():
    """Generate a social report."""
    db_path = Path.home() / ".hermes" / "data" / "social_tracking.db"
    
    if not db_path.exists():
        print(f"Database not found at: {db_path}")
        return False
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        print("\n" + "=" * 60)
        print("Hermes Social Tracking Report")
        print("=" * 60)
        
        # Get primary user
        cursor.execute("SELECT value FROM meta WHERE key = 'primary_user_name'")
        primary_user_row = cursor.fetchone()
        primary_user = primary_user_row[0] if primary_user_row else "Unknown"
        
        print(f"\nPrimary User: {primary_user}")
        print(f"Report Generated: {datetime.now().isoformat()}")
        print("-" * 60)
        
        # Get person counts
        cursor.execute("SELECT COUNT(*) FROM persons")
        person_count = cursor.fetchone()[0]
        print(f"Total persons tracked: {person_count}")
        
        cursor.execute("SELECT COUNT(*) FROM persons WHERE trust_score >= 0.8")
        high_trust_count = cursor.fetchone()[0]
        print(f"High trust persons (>0.8): {high_trust_count}")
        
        cursor.execute("SELECT COUNT(*) FROM persons WHERE trust_score <= 0.3")
        low_trust_count = cursor.fetchone()[0]
        print(f"Low trust persons (≤0.3): {low_trust_count}")
        
        # Get recent activity
        one_week_ago = (datetime.now() - timedelta(days=7)).isoformat()
        cursor.execute(
            "SELECT COUNT(*) FROM events WHERE timestamp > ?",
            (one_week_ago,)
        )
        recent_events = cursor.fetchone()[0]
        print(f"Events in last 7 days: {recent_events}")
        
        # Get commitment stats
        cursor.execute(
            "SELECT COUNT(*) FROM commitments WHERE status = 'pending'"
        )
        pending_commitments = cursor.fetchone()[0]
        print(f"Pending commitments: {pending_commitments}")
        
        cursor.execute(
            "SELECT COUNT(*) FROM commitments WHERE status = 'fulfilled' AND timestamp_updated > ?",
            (one_week_ago,)
        )
        recent_fulfilled = cursor.fetchone()[0]
        print(f"Fulfilled in last 7 days: {recent_fulfilled}")
        
        cursor.execute(
            "SELECT COUNT(*) FROM commitments WHERE status = 'broken'"
        )
        broken_commitments = cursor.fetchone()[0]
        print(f"Broken commitments: {broken_commitments}")
        
        # Get top persons by activity
        cursor.execute("""
            SELECT p.name, COUNT(pe.event_id) as event_count
            FROM persons p
            JOIN person_events pe ON p.person_id = pe.person_id
            JOIN events e ON pe.event_id = e.event_id
            WHERE e.timestamp > ?
            GROUP BY p.person_id
            ORDER BY event_count DESC
            LIMIT 5
        """, (one_week_ago,))
        top_persons = cursor.fetchall()
        
        if top_persons:
            print("\nTop Persons by Activity (last 7 days):")
            for name, count in top_persons:
                print(f"  {name}: {count} events")
        
        conn.close()
        print("=" * 60)
        return True
    except Exception as e:
        print(f"✗ Error generating report: {e}")
        return False

def main():
    print("Hermes Social Tracking Plugin - Social Report")
    print("=" * 60)
    
    success = generate_social_report()
    
    if success:
        print("\n✓✓✓ Report generated successfully! ✓✓✓")
        return 0
    else:
        print("\n✗✗✗ Report generation failed ✗✗✗")
        return 1

if __name__ == "__main__":
    sys.exit(main())