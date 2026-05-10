#!/usr/bin/env python3
"""
Hermes Social Tracking Plugin - Performance Monitor
This script monitors plugin performance and generates metrics.
"""

import sys
import sqlite3
import time
from pathlib import Path
from datetime import datetime, timedelta

def get_performance_metrics():
    """Get performance metrics from the database."""
    db_path = Path.home() / ".hermes" / "data" / "social_tracking.db"
    
    if not db_path.exists():
        print(f"Database not found at: {db_path}")
        return False
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        print("\n" + "=" * 60)
        print("Social Tracking Plugin Performance Metrics")
        print("=" * 60)
        
        # Database size
        db_size = db_path.stat().st_size / 1024 / 1024  # Convert to MB
        print(f"Database size: {db_size:.2f} MB")
        
        # Record counts
        cursor.execute("SELECT COUNT(*) FROM persons")
        person_count = cursor.fetchone()[0]
        print(f"Persons tracked: {person_count}")
        
        cursor.execute("SELECT COUNT(*) FROM events")
        event_count = cursor.fetchone()[0]
        print(f"Events recorded: {event_count}")
        
        cursor.execute("SELECT COUNT(*) FROM commitments")
        commitment_count = cursor.fetchone()[0]
        print(f"Commitments tracked: {commitment_count}")
        
        # Average trust score
        cursor.execute("SELECT AVG(trust_score) FROM persons")
        avg_trust = cursor.fetchone()[0]
        print(f"Average trust score: {avg_trust:.3f}")
        
        # Recent activity (last 24 hours)
        one_day_ago = (datetime.now() - timedelta(days=1)).isoformat()
        
        cursor.execute(
            "SELECT COUNT(*) FROM events WHERE timestamp > ?",
            (one_day_ago,)
        )
        recent_events = cursor.fetchone()[0]
        print(f"Events in last 24 hours: {recent_events}")
        
        # Recent commitments
        cursor.execute(
            "SELECT COUNT(*) FROM commitments WHERE timestamp_updated > ?",
            (one_day_ago,)
        )
        recent_commitments = cursor.fetchone()[0]
        print(f"Commitments updated in last 24 hours: {recent_commitments}")
        
        conn.close()
        
        # Performance grade
        grade = "A"
        if recent_events < 10:
            grade = "C"
        elif recent_events < 5:
            grade = "D"
        
        print(f"\nPerformance Grade: {grade}")
        
        # Recommendations
        print("\nRecommendations:")
        if recent_events < 10:
            print("  • Increase social interactions to improve tracking")
        if person_count < 5:
            print("  • Add more persons to the social graph")
        if avg_trust < 0.5:
            print("  • Focus on building trust with key persons")
        
        return True
    except Exception as e:
        print(f"✗ Error getting metrics: {e}")
        return False

def main():
    print("Hermes Social Tracking Plugin - Performance Monitor")
    print("=" * 60)
    
    success = get_performance_metrics()
    
    if success:
        print("\n" + "=" * 60)
        print("✓✓✓ Performance metrics collected successfully! ✓✓✓")
        return 0
    else:
        print("\n" + "=" * 60)
        print("✗✗✗ Failed to collect metrics ✗✗✗")
        return 1

if __name__ == "__main__":
    sys.exit(main())