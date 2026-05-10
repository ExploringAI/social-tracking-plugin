#!/usr/bin/env python3
"""
Hermes Social Tracking Plugin - Commitments Report
This script generates a report of commitments.
"""

import sys
import sqlite3
from pathlib import Path
from datetime import datetime, timedelta

def generate_commitments_report():
    """Generate a commitments report."""
    db_path = Path.home() / ".hermes" / "data" / "social_tracking.db"
    
    if not db_path.exists():
        print(f"Database not found at: {db_path}")
        return False
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        print("\n" + "=" * 60)
        print("Social Tracking Commitments Report")
        print("=" * 60)
        
        # Get commitment counts by status
        print(f"\nCommitments by Status:")
        print("-" * 60)
        
        cursor.execute("SELECT status, COUNT(*) FROM commitments GROUP BY status")
        status_counts = cursor.fetchall()
        
        for status, count in status_counts:
            print(f"{status.capitalize()}: {count}")
        
        # Get recent commitments
        one_week_ago = (datetime.now() - timedelta(days=7)).isoformat()
        
        cursor.execute("""
            SELECT c.description, c.status, c.timestamp_promised, c.due_date,
                   GROUP_CONCAT(p.name) as persons
            FROM commitments c
            JOIN commitment_parties cp ON c.commitment_id = cp.commitment_id
            JOIN persons p ON cp.person_id = p.person_id
            WHERE c.timestamp_updated > ?
            GROUP BY c.commitment_id
            ORDER BY c.timestamp_updated DESC
            LIMIT 10
        """, (one_week_ago,))
        
        recent_commitments = cursor.fetchall()
        
        if recent_commitments:
            print(f"\nRecent Commitments (last 7 days):")
            print("-" * 60)
            for desc, status, promised, due, persons in recent_commitments:
                print(f"Status: {status}")
                print(f"Description: {desc}")
                print(f"Persons: {persons}")
                print(f"Promised: {promised}")
                if due:
                    print(f"Due: {due}")
                print("-" * 30)
        
        # Get commitments needing attention
        cursor.execute("""
            SELECT c.commitment_id, c.description, c.due_date, c.status,
                   GROUP_CONCAT(p.name) as persons
            FROM commitments c
            JOIN commitment_parties cp ON c.commitment_id = cp.commitment_id
            JOIN persons p ON cp.person_id = p.person_id
            WHERE c.status = 'pending' AND c.due_date < ?
            GROUP BY c.commitment_id
            ORDER BY c.due_date
            LIMIT 5
        """, (datetime.now().isoformat(),))
        
        overdue_commitments = cursor.fetchall()
        if overdue_commitments:
            print(f"\nOverdue Commitments:")
            print("-" * 60)
            for cid, desc, due, status, persons in overdue_commitments:
                print(f"ID: {cid}")
                print(f"Description: {desc}")
                print(f"Due: {due}")
                print(f"Persons: {persons}")
                print("-" * 30)
        
        conn.close()
        
        # Commitments grade
        cursor.execute("SELECT COUNT(*) FROM commitments WHERE status = 'pending'")
        pending = cursor.fetchone()[0]
        cursor.execute("SELECT COUNT(*) FROM commitments WHERE status = 'fulfilled'")
        fulfilled = cursor.fetchone()[0]
        total = pending + fulfilled
        
        print(f"\nCommitments Grade:")
        if total > 0:
            fulfillment_rate = fulfilled / total
            if fulfillment_rate >= 0.8:
                print("  A - Excellent commitment management")
            elif fulfillment_rate >= 0.6:
                print("  B - Good commitment management")
            elif fulfillment_rate >= 0.4:
                print("  C - Moderate commitment management")
            else:
                print("  D - Needs improvement in commitment management")
        else:
            print("  N/A - No commitments tracked yet")
        
        return True
    except Exception as e:
        print(f"✗ Error generating commitments report: {e}")
        return False

def main():
    print("Hermes Social Tracking Plugin - Commitments Report")
    print("=" * 60)
    
    success = generate_commitments_report()
    
    if success:
        print("\n" + "=" * 60)
        print("✓✓✓ Commitments report generated successfully! ✓✓✓")
        return 0
    else:
        print("\n" + "=" * 60)
        print("✗✗✗ Failed to generate commitments report ✗✗✗")
        return 1

if __name__ == "__main__":
    sys.exit(main())