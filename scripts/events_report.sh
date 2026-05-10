#!/usr/bin/env python3
"""
Hermes Social Tracking Plugin - Events Report
This script generates a report of events.
"""

import sys
import sqlite3
from pathlib import Path
from datetime import datetime, timedelta

def generate_events_report():
    """Generate an events report."""
    db_path = Path.home() / ".hermes" / "data" / "social_tracking.db"
    
    if not db_path.exists():
        print(f"Database not found at: {db_path}")
        return False
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        print("\n" + "=" * 60)
        print("Social Tracking Events Report")
        print("=" * 60)
        
        # Event statistics
        print(f"\nEvent Statistics:")
        print("-" * 60)
        
        cursor.execute("SELECT COUNT(*) FROM events")
        total_events = cursor.fetchone()[0]
        print(f"Total Events: {total_events}")
        
        one_week_ago = (datetime.now() - timedelta(days=7)).isoformat()
        cursor.execute(
            "SELECT COUNT(*) FROM events WHERE timestamp > ?",
            (one_week_ago,)
        )
        recent_events = cursor.fetchone()[0]
        print(f"Events (Last 7 Days): {recent_events}")
        
        # Events by type
        cursor.execute("SELECT kind, COUNT(*) FROM events GROUP BY kind ORDER BY COUNT(*) DESC")
        events_by_type = cursor.fetchall()
        
        if events_by_type:
            print(f"\nEvents by Type:")
            for kind, count in events_by_type:
                print(f"  {kind}: {count}")
        
        # Recent events
        cursor.execute("""
            SELECT e.kind, e.summary, e.timestamp, GROUP_CONCAT(p.name)
            FROM events e
            JOIN person_events pe ON e.event_id = pe.event_id
            JOIN persons p ON pe.person_id = p.person_id
            WHERE e.timestamp > ?
            GROUP BY e.event_id
            ORDER BY e.timestamp DESC
            LIMIT 10
        """, (one_week_ago,))
        
        recent_events = cursor.fetchall()
        if recent_events:
            print(f"\nRecent Events (Last 7 Days):")
            print("-" * 60)
            for kind, summary, timestamp, persons in recent_events:
                print(f"[{timestamp}] {kind}")
                print(f"  Summary: {summary}")
                print(f"  Persons: {persons}")
                print("-" * 30)
        
        # Activity patterns
        print(f"\nActivity Patterns:")
        print("-" * 60)
        
        # Events by day of week (last 30 days)
        thirty_days_ago = (datetime.now() - timedelta(days=30)).isoformat()
        
        cursor.execute("""
            SELECT strftime('%w', timestamp) as day_of_week, COUNT(*)
            FROM events
            WHERE timestamp > ?
            GROUP BY day_of_week
            ORDER BY COUNT(*) DESC
        """, (thirty_days_ago,))
        
        day_counts = cursor.fetchall()
        if day_counts:
            days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            print("  Events by Day of Week (Last 30 days):")
            for day_idx, count in day_counts:
                print(f"    {days[int(day_idx)]}: {count} events")
        
        conn.close()
        return True
    except Exception as e:
        print(f"✗ Error generating events report: {e}")
        return False

def main():
    print("Hermes Social Tracking Plugin - Events Report")
    print("=" * 60)
    
    success = generate_events_report()
    
    if success:
        print("\n" + "=" * 60)
        print("✓✓✓ Events report generated successfully! ✓✓✓")
        return 0
    else:
        print("\n" + "=" * 60)
        print("✗✗✗ Failed to generate events report ✗✗✗")
        return 1

if __name__ == "__main__":
    sys.exit(main())