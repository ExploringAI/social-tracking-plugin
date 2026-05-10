#!/usr/bin/env python3
"""
Hermes Social Tracking Plugin - Comprehensive Summary Report
This script generates a comprehensive summary report combining multiple metrics.
"""

import sys
import sqlite3
from pathlib import Path
from datetime import datetime, timedelta

def generate_comprehensive_report():
    """Generate a comprehensive summary report."""
    db_path = Path.home() / ".hermes" / "data" / "social_tracking.db"
    
    if not db_path.exists():
        print(f"Database not found at: {db_path}")
        return False
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        print("\n" + "=" * 60)
        print("Hermes Social Tracking Comprehensive Summary")
        print("=" * 60)
        print(f"\nReport Generated: {datetime.now().isoformat()}")
        print(f"Database: {db_path}")
        print("-" * 60)
        
        # Basic statistics
        cursor.execute("SELECT COUNT(*) FROM persons")
        person_count = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM events")
        event_count = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM commitments")
        commitment_count = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM relationships")
        relationship_count = cursor.fetchone()[0]
        
        print(f"Social Graph Size:")
        print(f"  Persons: {person_count}")
        print(f"  Events: {event_count}")
        print(f"  Commitments: {commitment_count}")
        print(f"  Relationships: {relationship_count}")
        print(f"  Total Records: {person_count + event_count + commitment_count + relationship_count}")
        
        # Trust scores
        cursor.execute("SELECT AVG(trust_score) FROM persons")
        avg_trust = cursor.fetchone()[0] or 0.0
        print(f"\nAverage Trust Score: {avg_trust:.3f}")
        
        cursor.execute("SELECT COUNT(*) FROM persons WHERE trust_score >= 0.8")
        high_trust = cursor.fetchone()[0]
        print(f"High Trust Persons (≥0.8): {high_trust}")
        
        cursor.execute("SELECT COUNT(*) FROM persons WHERE trust_score <= 0.3")
        low_trust = cursor.fetchone()[0]
        print(f"Low Trust Persons (≤0.3): {low_trust}")
        
        # Recent activity (last 7 days)
        one_week_ago = (datetime.now() - timedelta(days=7)).isoformat()
        
        cursor.execute(
            "SELECT COUNT(*) FROM events WHERE timestamp > ?",
            (one_week_ago,)
        )
        recent_events = cursor.fetchone()[0]
        
        cursor.execute(
            "SELECT COUNT(*) FROM commitments WHERE timestamp_updated > ?",
            (one_week_ago,)
        )
        recent_commitments = cursor.fetchone()[0]
        
        print(f"\nRecent Activity (Last 7 Days):")
        print(f"  Events: {recent_events}")
        print(f"  Commitments Updated: {recent_commitments}")
        
        # Commitments status
        cursor.execute("SELECT status, COUNT(*) FROM commitments GROUP BY status")
        commitment_status = dict(cursor.fetchall())
        
        print(f"\nCommitments Status:")
        for status in ['pending', 'fulfilled', 'broken']:
            count = commitment_status.get(status, 0)
            print(f"  {status.capitalize()}: {count}")
        
        # Performance metrics
        print(f"\nPerformance Metrics:")
        if person_count > 0:
            cursor.execute("SELECT AVG(LENGTH(roles)) FROM persons")
            avg_roles = cursor.fetchone()[0] or 0
            print(f"  Average Roles per Person: {avg_roles:.2f}")
        
        # Data freshness
        cursor.execute("SELECT MAX(timestamp) FROM events")
        last_event = cursor.fetchone()[0]
        if last_event:
            last_event_time = datetime.fromisoformat(last_event.replace('Z', '+00:00'))
            time_since_last_event = datetime.now() - last_event_time
            print(f"\nData Freshness:")
            print(f"  Last Event: {last_event_time.isoformat()}")
            print(f"  Time Since Last Event: {time_since_last_event.days}d {time_since_last_event.seconds//3600}h")
        
        # Overall health grade
        print(f"\nOverall Health Grade:")
        grade = "A"
        if recent_events < 5:
            grade = "D"
        elif recent_events < 10:
            grade = "C"
        elif recent_events < 20:
            grade = "B"
        
        print(f"  Grade: {grade}")
        
        # Recommendations
        print(f"\nRecommendations:")
        if recent_events < 10:
            print("  • Increase social interactions to improve tracking")
        if person_count < 10:
            print("  • Add more persons to expand social graph")
        if avg_trust < 0.5:
            print("  • Focus on building trust with key persons")
        if commitment_count > 0 and recent_commitments == 0:
            print("  • Review pending commitments regularly")
        
        conn.close()
        return True
    except Exception as e:
        print(f"✗ Error generating comprehensive report: {e}")
        return False

def main():
    print("Hermes Social Tracking Plugin - Comprehensive Summary Report")
    print("=" * 60)
    
    success = generate_comprehensive_report()
    
    if success:
        print("\n" + "=" * 60)
        print("✓✓✓ Comprehensive summary generated successfully! ✓✓✓")
        return 0
    else:
        print("\n" + "=" * 60)
        print("✗✗✗ Failed to generate comprehensive summary ✗✗✗")
        return 1

if __name__ == "__main__":
    sys.exit(main())