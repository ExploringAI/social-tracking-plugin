#!/usr/bin/env python3
"""
Hermes Social Tracking Plugin - Trust Report
This script generates a trust score report for all persons.
"""

import sys
import sqlite3
from pathlib import Path
from datetime import datetime, timedelta

def generate_trust_report():
    """Generate a trust score report."""
    db_path = Path.home() / ".hermes" / "data" / "social_tracking.db"
    
    if not db_path.exists():
        print(f"Database not found at: {db_path}")
        return False
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        print("\n" + "=" * 60)
        print("Social Tracking Trust Report")
        print("=" * 60)
        
        # Get all persons with trust scores
        cursor.execute("""
            SELECT name, roles, last_active, trust_score, kind
            FROM persons
            ORDER BY trust_score DESC
        """)
        
        persons = cursor.fetchall()
        
        print(f"\nTrust Scores (Top 20):")
        print("-" * 60)
        print(f"{'Name':<20} {'Trust':<6} {'Roles':<20} {'Last Active':<20}")
        print("-" * 60)
        
        for name, roles, last_active, trust_score, kind in persons[:20]:
            print(f"{name:<20} {trust_score:<6.3f} {roles:<20} {last_active:<20}")
        
        # Trust score distribution
        print(f"\nTrust Score Distribution:")
        cursor.execute("SELECT COUNT(*) FROM persons WHERE trust_score >= 0.8")
        high_trust = cursor.fetchone()[0]
        print(f"  High Trust (≥0.8): {high_trust} persons")
        
        cursor.execute("SELECT COUNT(*) FROM persons WHERE trust_score >= 0.6 AND trust_score < 0.8")
        moderate_trust = cursor.fetchone()[0]
        print(f"  Moderate Trust (0.6-0.8): {moderate_trust} persons")
        
        cursor.execute("SELECT COUNT(*) FROM persons WHERE trust_score >= 0.4 AND trust_score < 0.6")
        neutral_trust = cursor.fetchone()[0]
        print(f"  Neutral Trust (0.4-0.6): {neutral_trust} persons")
        
        cursor.execute("SELECT COUNT(*) FROM persons WHERE trust_score >= 0.2 AND trust_score < 0.4")
        low_trust = cursor.fetchone()[0]
        print(f"  Low Trust (0.2-0.4): {low_trust} persons")
        
        cursor.execute("SELECT COUNT(*) FROM persons WHERE trust_score < 0.2")
        very_low_trust = cursor.fetchone()[0]
        print(f"  Very Low Trust (<0.2): {very_low_trust} persons")
        
        # Average trust score
        cursor.execute("SELECT AVG(trust_score) FROM persons")
        avg_trust = cursor.fetchone()[0]
        print(f"\nAverage Trust Score: {avg_trust:.3f}")
        
        # Trust trends
        one_week_ago = (datetime.now() - timedelta(days=7)).isoformat()
        
        cursor.execute("""
            SELECT AVG(p.trust_score)
            FROM persons p
            JOIN person_events pe ON p.person_id = pe.person_id
            JOIN events e ON pe.event_id = e.event_id
            WHERE e.timestamp > ?
        """, (one_week_ago,))
        
        recent_avg_trust = cursor.fetchone()[0] or 0
        print(f"Average Trust (Last 7 days): {recent_avg_trust:.3f}")
        
        conn.close()
        
        # Trust grade
        print(f"\nTrust Grade: ")
        if avg_trust >= 0.7:
            print("  A - High Trust Environment")
        elif avg_trust >= 0.5:
            print("  B - Moderate Trust Environment")
        elif avg_trust >= 0.3:
            print("  C - Low Trust Environment")
        else:
            print("  D - Very Low Trust Environment")
        
        return True
    except Exception as e:
        print(f"✗ Error generating trust report: {e}")
        return False

def main():
    print("Hermes Social Tracking Plugin - Trust Report")
    print("=" * 60)
    
    success = generate_trust_report()
    
    if success:
        print("\n" + "=" * 60)
        print("✓✓✓ Trust report generated successfully! ✓✓✓")
        return 0
    else:
        print("\n" + "=" * 60)
        print("✗✗✗ Failed to generate trust report ✗✗✗")
        return 1

if __name__ == "__main__":
    sys.exit(main())