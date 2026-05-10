#!/usr/bin/env python3
"""
Hermes Social Tracking Plugin - Relationships Report
This script generates a report of relationships between persons.
"""

import sys
import sqlite3
from pathlib import Path
from datetime import datetime, timedelta

def generate_relationships_report():
    """Generate a relationships report."""
    db_path = Path.home() / ".hermes" / "data" / "social_tracking.db"
    
    if not db_path.exists():
        print(f"Database not found at: {db_path}")
        return False
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        print("\n" + "=" * 60)
        print("Social Tracking Relationships Report")
        print("=" * 60)
        
        # Relationship statistics
        print(f"\nRelationship Statistics:")
        print("-" * 60)
        
        cursor.execute("SELECT COUNT(*) FROM relationships")
        total_relationships = cursor.fetchone()[0]
        print(f"Total Relationships: {total_relationships}")
        
        cursor.execute("SELECT COUNT(*) FROM relationships WHERE status = 'active'")
        active_relationships = cursor.fetchone()[0]
        print(f"Active Relationships: {active_relationships}")
        
        cursor.execute("SELECT COUNT(*) FROM relationships WHERE status = 'ended'")
        ended_relationships = cursor.fetchone()[0]
        print(f"Ended Relationships: {ended_relationships}")
        
        # Relationships by type
        cursor.execute("SELECT rel_type, COUNT(*) FROM relationships GROUP BY rel_type")
        relationships_by_type = cursor.fetchall()
        
        if relationships_by_type:
            print(f"\nRelationships by Type:")
            for rel_type, count in relationships_by_type:
                print(f"  {rel_type}: {count}")
        
        # Strongest relationships
        cursor.execute("""
            SELECT p1.name, p2.name, r.strength, r.rel_type, r.status
            FROM relationships r
            JOIN persons p1 ON r.person_a_id = p1.person_id
            JOIN persons p2 ON r.person_b_id = p2.person_id
            WHERE r.status = 'active'
            ORDER BY r.strength DESC
            LIMIT 10
        """)
        
        strong_relationships = cursor.fetchall()
        if strong_relationships:
            print(f"\nStrongest Relationships (Active):")
            print("-" * 60)
            for p1, p2, strength, rel_type, status in strong_relationships:
                print(f"{p1} ↔ {p2} ({rel_type}): Strength {strength:.3f}")
        
        # Weakest relationships
        cursor.execute("""
            SELECT p1.name, p2.name, r.strength, r.rel_type, r.status
            FROM relationships r
            JOIN persons p1 ON r.person_a_id = p1.person_id
            JOIN persons p2 ON r.person_b_id = p2.person_id
            WHERE r.status = 'active'
            ORDER BY r.strength ASC
            LIMIT 10
        """)
        
        weak_relationships = cursor.fetchall()
        if weak_relationships:
            print(f"\nWeakest Relationships (Active):")
            print("-" * 60)
            for p1, p2, strength, rel_type, status in weak_relationships:
                print(f"{p1} ↔ {p2} ({rel_type}): Strength {strength:.3f}")
        
        conn.close()
        return True
    except Exception as e:
        print(f"✗ Error generating relationships report: {e}")
        return False

def main():
    print("Hermes Social Tracking Plugin - Relationships Report")
    print("=" * 60)
    
    success = generate_relationships_report()
    
    if success:
        print("\n" + "=" * 60)
        print("✓✓✓ Relationships report generated successfully! ✓✓✓")
        return 0
    else:
        print("\n" + "=" * 60)
        print("✗✗✗ Failed to generate relationships report ✗✗✗")
        return 1

if __name__ == "__main__":
    sys.exit(main())