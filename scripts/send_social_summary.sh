#!/usr/bin/env python3
"""
Hermes Social Tracking Plugin - Send Social Summary
This script sends a social summary to a specified endpoint.
"""

import sys
import sqlite3
import json
import requests
from pathlib import Path
from datetime import datetime, timedelta

def send_social_summary(endpoint_url, api_key=None):
    """Send a social summary to a specified endpoint."""
    db_path = Path.home() / ".hermes" / "data" / "social_tracking.db"
    
    if not db_path.exists():
        print(f"Database not found at: {db_path}")
        return False
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Collect summary data
        summary = {
            "generated_at": datetime.now().isoformat(),
            "plugin_version": "0.3.0",
            "summary": {}
        }
        
        # Basic statistics
        cursor.execute("SELECT COUNT(*) FROM persons")
        summary["summary"]["person_count"] = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM events")
        summary["summary"]["event_count"] = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM commitments")
        summary["summary"]["commitment_count"] = cursor.fetchone()[0]
        
        cursor.execute("SELECT AVG(trust_score) FROM persons")
        summary["summary"]["avg_trust_score"] = cursor.fetchone()[0] or 0.0
        
        # Recent activity
        one_day_ago = (datetime.now() - timedelta(days=1)).isoformat()
        
        cursor.execute(
            "SELECT COUNT(*) FROM events WHERE timestamp > ?",
            (one_day_ago,)
        )
        summary["summary"]["events_last_24h"] = cursor.fetchone()[0]
        
        cursor.execute(
            "SELECT COUNT(*) FROM commitments WHERE timestamp_updated > ?",
            (one_day_ago,)
        )
        summary["summary"]["commitments_updated_last_24h"] = cursor.fetchone()[0]
        
        # Commitments status
        cursor.execute("SELECT status, COUNT(*) FROM commitments GROUP BY status")
        summary["summary"]["commitments_by_status"] = dict(cursor.fetchall())
        
        conn.close()
        
        # Send to endpoint
        headers = {"Content-Type": "application/json"}
        if api_key:
            headers["Authorization"] = f"Bearer {api_key}"
        
        response = requests.post(endpoint_url, json=summary, headers=headers, timeout=30)
        
        if response.status_code == 200:
            print(f"✓ Successfully sent social summary to {endpoint_url}")
            print(f"✓ Status code: {response.status_code}")
            return True
        else:
            print(f"✗ Failed to send social summary")
            print(f"  Status code: {response.status_code}")
            print(f"  Response: {response.text}")
            return False
    except Exception as e:
        print(f"✗ Error sending social summary: {e}")
        return False

def main():
    print("Hermes Social Tracking Plugin - Send Social Summary")
    print("=" * 60)
    
    if len(sys.argv) < 2:
        print("Usage: scripts/send_social_summary.sh <endpoint_url> [api_key]")
        print("\nExample: scripts/send_social_summary.sh https://api.example.com/social_summary")
        print("         scripts/send_social_summary.sh https://api.example.com/social_summary my_api_key")
        return 1
    
    endpoint_url = sys.argv[1]
    api_key = sys.argv[2] if len(sys.argv) > 2 else None
    
    success = send_social_summary(endpoint_url, api_key)
    
    if success:
        print("\n" + "=" * 60)
        print("✓✓✓ Social summary sent successfully! ✓✓✓")
        return 0
    else:
        print("\n" + "=" * 60)
        print("✗✗✗ Failed to send social summary ✗✗✗")
        return 1

if __name__ == "__main__":
    sys.exit(main())