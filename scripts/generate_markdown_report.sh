#!/usr/bin/env python3
"""
Hermes Social Tracking Plugin - Markdown Report Generator
This script generates a markdown report.
"""

import sys
import sqlite3
from pathlib import Path
from datetime import datetime, timedelta

def generate_markdown_report(output_file):
    """Generate a markdown report."""
    db_path = Path.home() / ".hermes" / "data" / "social_tracking.db"
    
    if not db_path.exists():
        print(f"Database not found at: {db_path}")
        return False
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Get data for report
        cursor.execute("SELECT COUNT(*) FROM persons")
        person_count = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM events")
        event_count = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM commitments")
        commitment_count = cursor.fetchone()[0]
        
        cursor.execute("SELECT AVG(trust_score) FROM persons")
        avg_trust = cursor.fetchone()[0] or 0.0
        
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
        
        # Get top persons by trust
        cursor.execute("""
            SELECT name, trust_score, roles, last_active
            FROM persons
            ORDER BY trust_score DESC
            LIMIT 10
        """)
        top_persons = cursor.fetchall()
        
        # Get recent events
        cursor.execute("""
            SELECT e.kind, e.summary, e.timestamp, GROUP_CONCAT(p.name)
            FROM events e
            JOIN person_events pe ON e.event_id = pe.event_id
            JOIN persons p ON pe.person_id = p.person_id
            WHERE e.timestamp > ?
            GROUP BY e.event_id
            ORDER BY e.timestamp DESC
            LIMIT 5
        """, (one_week_ago,))
        
        recent_events_data = cursor.fetchall()
        
        conn.close()
        
        # Generate markdown
        markdown_content = f"""# Social Tracking Report

Generated: {datetime.now().isoformat()}
Database: {db_path}

## Summary Statistics

| Metric | Count |
|--------|-------|
| Total Persons | {person_count} |
| Total Events | {event_count} |
| Total Commitments | {commitment_count} |
| Average Trust Score | {avg_trust:.3f} |

## Top Persons by Trust

| Rank | Name | Trust Score | Roles | Last Active |
|------|------|-------------|-------|-------------|
"""
        
        for idx, (name, trust_score, roles, last_active) in enumerate(top_persons, 1):
            markdown_content += f"| {idx} | {name} | {trust_score:.3f} | {roles or 'None'} | {last_active} |\n"
        
        markdown_content += "\n## Recent Activity (Last 7 Days)

| Event Type | Summary | Timestamp | Persons Involved |
|------------|---------|-----------|------------------|
"""
        
        for kind, summary, timestamp, persons in recent_events_data:
            markdown_content += f"| {kind} | {summary} | {timestamp} | {persons} |\n"
        
        markdown_content += f"""

## Recent Performance

- Events in last 7 days: {recent_events}
- Commitments updated in last 7 days: {recent_commitments}

## Trust Score Distribution

- High Trust (≥0.8): 
- Moderate Trust (0.6-0.8): 
- Neutral Trust (0.4-0.6): 
- Low Trust (0.2-0.4): 
- Very Low Trust (<0.2): 

## Recommendations

"""
        
        if recent_events < 10:
            markdown_content += "* Increase social interactions to improve tracking\n"
        if person_count < 10:
            markdown_content += "* Add more persons to expand social graph\n"
        if avg_trust < 0.5:
            markdown_content += "* Focus on building trust with key persons\n"
        if commitment_count > 0 and recent_commitments == 0:
            markdown_content += "* Review pending commitments regularly\n"
        
        # Write markdown to file
        with open(output_file, 'w') as f:
            f.write(markdown_content)
        
        print(f"✓ Markdown report generated: {output_file}")
        print(f"✓ Persons: {person_count}")
        print(f"✓ Events: {event_count}")
        print(f"✓ Commitments: {commitment_count}")
        print(f"✓ Top persons: {len(top_persons)}")
        return True
    except Exception as e:
        print(f"✗ Error generating markdown report: {e}")
        return False

def main():
    print("Hermes Social Tracking Plugin - Markdown Report Generator")
    print("=" * 60)
    
    if len(sys.argv) < 2:
        print("Usage: scripts/generate_markdown_report.sh <output_file.md>")
        print("\nExample: scripts/generate_markdown_report.sh social_report.md")
        return 1
    
    output_file = Path(sys.argv[1])
    success = generate_markdown_report(output_file)
    
    if success:
        print("\n" + "=" * 60)
        print("✓✓✓ Markdown report generated successfully! ✓✓✓")
        return 0
    else:
        print("\n" + "=" * 60)
        print("✗✗✗ Failed to generate markdown report ✗✗✗")
        return 1

if __name__ == "__main__":
    sys.exit(main())