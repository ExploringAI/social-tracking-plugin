#!/usr/bin/env python3
"""
Hermes Social Tracking Plugin - Batch Trust Update
This script performs batch updates to trust scores.
"""

import sys
import sqlite3
from pathlib import Path
from datetime import datetime, timedelta

def batch_update_trust(criteria, delta):
    """Batch update trust scores based on criteria."""
    db_path = Path.home() / ".hermes" / "data" / "social_tracking.db"
    
    if not db_path.exists():
        print(f"Database not found at: {db_path}")
        return False
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Build query based on criteria
        query = "UPDATE persons SET trust_score = trust_score + ?"
        conditions = []
        
        if criteria == "high_activity":
            # Persons with many recent events
            one_week_ago = (datetime.now() - timedelta(days=7)).isoformat()
            cursor.execute("""
                SELECT p.person_id, COUNT(*) as event_count
                FROM persons p
                JOIN person_events pe ON p.person_id = pe.person_id
                JOIN events e ON pe.event_id = e.event_id
                WHERE e.timestamp > ?
                GROUP BY p.person_id
                HAVING COUNT(*) >= 5
            """, (one_week_ago,))
            
            person_ids = [row[0] for row in cursor.fetchall()]
            if person_ids:
                placeholders = ","join('?' for _ in person_ids)
                query += f" WHERE person_id IN ({placeholders})"
                cursor.execute(query, [delta] + person_ids)
                updated = cursor.rowcount
                print(f"✓ Updated {updated} persons with high activity (+{delta})")
            else:
                print("No persons with high activity found")
        
        elif criteria == "low_activity":
            # Persons with no recent events
            one_week_ago = (datetime.now() - timedelta(days=7)).isoformat()
            cursor.execute("""
                SELECT p.person_id
                FROM persons p
                LEFT JOIN person_events pe ON p.person_id = pe.person_id
                LEFT JOIN events e ON pe.event_id = e.event_id AND e.timestamp > ?
                WHERE e.event_id IS NULL
            """, (one_week_ago,))
            
            person_ids = [row[0] for row in cursor.fetchall()]
            if person_ids:
                placeholders = ","join('?' for _ in person_ids)
                query += f" WHERE person_id IN ({placeholders})"
                cursor.execute(query, [delta] + person_ids)
                updated = cursor.rowcount
                print(f"✓ Updated {updated} persons with low activity (-{abs(delta)})")
            else:
                print("No persons with low activity found")
        
        elif criteria == "positive_sentiment":
            # Persons with recent positive interactions (simplified)
            one_week_ago = (datetime.now() - timedelta(days=7)).isoformat()
            cursor.execute("""
                SELECT DISTINCT p.person_id
                FROM persons p
                JOIN person_events pe ON p.person_id = pe.person_id
                JOIN events e ON pe.event_id = e.event_id
                WHERE e.timestamp > ? AND e.summary LIKE '%great%' OR e.summary LIKE '%awesome%' OR e.summary LIKE '%thank%'
            """, (one_week_ago,))
            
            person_ids = [row[0] for row in cursor.fetchall()]
            if person_ids:
                placeholders = ","join('?' for _ in person_ids)
                query += f" WHERE person_id IN ({placeholders})"
                cursor.execute(query, [delta] + person_ids)
                updated = cursor.rowcount
                print(f"✓ Updated {updated} persons with positive sentiment (+{delta})")
            else:
                print("No persons with positive sentiment found")
        
        elif criteria == "negative_sentiment":
            # Persons with recent negative interactions (simplified)
            one_week_ago = (datetime.now() - timedelta(days=7)).isoformat()
            cursor.execute("""
                SELECT DISTINCT p.person_id
                FROM persons p
                JOIN person_events pe ON p.person_id = pe.person_id
                JOIN events e ON pe.event_id = e.event_id
                WHERE e.timestamp > ? AND e.summary LIKE '%problem%' OR e.summary LIKE '%issue%' OR e.summary LIKE '%sorry%'
            """, (one_week_ago,))
            
            person_ids = [row[0] for row in cursor.fetchall()]
            if person_ids:
                placeholders = ","join('?' for _ in person_ids)
                query += f" WHERE person_id IN ({placeholders})"
                cursor.execute(query, [delta] + person_ids)
                updated = cursor.rowcount
                print(f"✓ Updated {updated} persons with negative sentiment (-{abs(delta)})")
            else:
                print("No persons with negative sentiment found")
        
        else:
            print(f"Unknown criteria: {criteria}")
            print("Valid criteria: high_activity, low_activity, positive_sentiment, negative_sentiment")
            return False
        
        conn.commit()
        conn.close()
        return True
    except Exception as e:
        print(f"✗ Error in batch trust update: {e}")
        return False

def main():
    print("Hermes Social Tracking Plugin - Batch Trust Update")
    print("=" * 60)
    
    if len(sys.argv) < 3:
        print("Usage: scripts/batch_trust_update.sh <criteria> <delta>")
        print("\nCriteria options:")
        print("  high_activity      - Persons with 5+ events in last week")
        print("  low_activity       - Persons with no events in last week")
        print("  positive_sentiment - Persons with positive interactions")
        print("  negative_sentiment - Persons with negative interactions")
        print("\nExample: scripts/batch_trust_update.sh high_activity 0.1")
        print("         scripts/batch_trust_update.sh low_activity -0.1")
        return 1
    
    criteria = sys.argv[1]
    try:
        delta = float(sys.argv[2])
    except ValueError:
        print("Delta must be a number (e.g., 0.1 or -0.1)")
        return 1
    
    print(f"Updating trust scores with criteria: {criteria}, delta: {delta}")
    
    success = batch_update_trust(criteria, delta)
    
    if success:
        print("\n" + "=" * 60)
        print("✓✓✓ Batch trust update completed! ✓✓✓")
        return 0
    else:
        print("\n" + "=" * 60)
        print("✗✗✗ Batch trust update failed ✗✗✗")
        return 1

if __name__ == "__main__":
    sys.exit(main())