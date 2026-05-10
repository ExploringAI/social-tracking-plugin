#!/usr/bin/env python3
"""
Hermes Social Tracking Plugin - Database Cleanup Script
This script cleans up old database entries.
"""

import sys
import sqlite3
from datetime import datetime, timedelta
from pathlib import Path

def cleanup_old_entries():
    """Clean up old database entries."""
    db_path = Path.home() / ".hermes" / "data" / "social_tracking.db"
    
    if not db_path.exists():
        print(f"Database not found at: {db_path}")
        return False
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Clean up events older than 1 year
        one_year_ago = (datetime.now() - timedelta(days=365)).isoformat()
        cursor.execute(
            "DELETE FROM events WHERE timestamp < ?",
            (one_year_ago,)
        )
        deleted_events = cursor.rowcount
        print(f"✓ Deleted {deleted_events} old events")
        
        # Clean up expired commitments (older than 5 years)
        five_years_ago = (datetime.now() - timedelta(days=5*365)).isoformat()
        cursor.execute(
            "DELETE FROM commitments WHERE timestamp_updated < ? AND status = 'fulfilled'",
            (five_years_ago,)
        )
        deleted_commitments = cursor.rowrowcount
        print(f"✓ Deleted {deleted_commitments} old fulfilled commitments")
        
        conn.commit()
        conn.close()
        
        print("✓ Database cleanup completed")
        return True
    except Exception as e:
        print(f"✗ Error cleaning up database: {e}")
        return False

def main():
    print("Hermes Social Tracking Plugin - Database Cleanup")
    print("=" * 50)
    
    response = input("Are you sure you want to clean up old database entries? (y/n): ")
    if response.lower() == 'y':
        success = cleanup_old_entries()
        if success:
            print("\n✓✓✓ Cleanup completed successfully! ✓✓✓")
            return 0
        else:
            print("\n✗✗✗ Cleanup failed ✗✗✗")
            return 1
    else:
        print("Cleanup cancelled.")
        return 0

if __name__ == "__main__":
    sys.exit(main())