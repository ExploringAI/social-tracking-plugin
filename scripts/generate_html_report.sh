#!/usr/bin/env python3
"""
Hermes Social Tracking Plugin - HTML Report Generator
This script generates an HTML report with visualizations.
"""

import sys
import sqlite3
import json
from pathlib import Path
from datetime import datetime, timedelta

def generate_html_report(output_file):
    """Generate an HTML report with visualizations."""
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
        
        # Generate HTML
        html_content = f"""
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Social Tracking Report</title>
    <style>
        body {{ font-family: Arial, sans-serif; margin: 40px; }}
        h1 {{ color: #333; border-bottom: 2px solid #eee; padding-bottom: 10px; }}
        h2 {{ color: #555; margin-top: 30px; }}
        table {{ border-collapse: collapse; width: 100%; margin: 20px 0; }}
        th, td {{ border: 1px solid #ddd; padding: 12px; text-align: left; }}
        th {{ background-color: #f4f4f4; }}
        tr:nth-child(even) {{ background-color: #f9f9f9; }}
        .stat-box {{ 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
            color: white; 
            padding: 20px; 
            border-radius: 10px; 
            margin: 10px 0; 
            display: inline-block; 
            min-width: 150px; 
        }}
        .high-trust {{ background: linear-gradient(135deg, #4CAF50 0%, #45a049 100%); }}
        .moderate-trust {{ background: linear-gradient(135deg, #FFC107 0%, #FF9800 100%); }}
        .low-trust {{ background: linear-gradient(135deg, #f44336 0%, #d32f2f 100%); }}
    </style>
</head>
<body>
    <h1>Social Tracking Report</h1>
    <p>Generated: {datetime.now().isoformat()}</p>
    <p>Database: {db_path}</p>
    
    <h2>Summary Statistics</h2>
    <div class="stat-box">
        <h3>Total Persons</h3>
        <p style="font-size: 2em; font-weight: bold;">{person_count}</p>
    </div>
    <div class="stat-box">
        <h3>Total Events</h3>
        <p style="font-size: 2em; font-weight: bold;">{event_count}</p>
    </div>
    <div class="stat-box">
        <h3>Total Commitments</h3>
        <p style="font-size: 2em; font-weight: bold;">{commitment_count}</p>
    </div>
    <div class="stat-box">
        <h3>Avg Trust Score</h3>
        <p style="font-size: 2em; font-weight: bold;">{avg_trust:.3f}</p>
    </div>
    
    <h2>Top Persons by Trust</h2>
    <table>
        <thead>
            <tr>
                <th>Rank</th>
                <th>Name</th>
                <th>Trust Score</th>
                <th>Roles</th>
                <th>Last Active</th>
            </tr>
        </thead>
        <tbody>
    """
        
        for idx, (name, trust_score, roles, last_active) in enumerate(top_persons, 1):
            trust_class = "high-trust" if trust_score >= 0.8 else "moderate-trust" if trust_score >= 0.5 else "low-trust"
            html_content += f"""
            <tr>
                <td>{idx}</td>
                <td>{name}</td>
                <td class="{trust_class}">{trust_score:.3f}</td>
                <td>{roles or 'None'}</td>
                <td>{last_active}</td>
            </tr>
            """
        
        html_content += """
        </tbody>
    </table>
    
    <h2>Recent Activity (Last 7 Days)</h2>
    <table>
        <thead>
            <tr>
                <th>Event Type</th>
                <th>Summary</th>
                <th>Timestamp</th>
                <th>Persons Involved</th>
            </tr>
        </thead>
        <tbody>
    """
        
        for kind, summary, timestamp, persons in recent_events_data:
            html_content += f"""
            <tr>
                <td>{kind}</td>
                <td>{summary}</td>
                <td>{timestamp}</td>
                <td>{persons}</td>
            </tr>
            """
        
        html_content += """
        </tbody>
    </table>
    
    <h2>Recent Performance</h2>
    <div style="margin: 20px 0;">
        <p>Events in last 7 days: <strong>{recent_events}</strong></p>
        <p>Commitments updated in last 7 days: <strong>{recent_commitments}</strong></p>
    </div>
    
    <h2>Trust Score Distribution</h2>
    <div style="margin: 20px 0;">
        <p>High Trust (≥0.8): <strong>"""
        
        cursor.execute("SELECT COUNT(*) FROM persons WHERE trust_score >= 0.8")
        high_trust = cursor.fetchone()[0]
        html_content += f"{high_trust}</strong> persons"
        
        cursor.execute("SELECT COUNT(*) FROM persons WHERE trust_score >= 0.6 AND trust_score < 0.8")
        moderate_trust = cursor.fetchone()[0]
        html_content += f"<p>Moderate Trust (0.6-0.8): <strong>{moderate_trust}</strong> persons"
        
        cursor.execute("SELECT COUNT(*) FROM persons WHERE trust_score >= 0.4 AND trust_score < 0.6")
        neutral_trust = cursor.fetchone()[0]
        html_content += f"<p>Neutral Trust (0.4-0.6): <strong>{neutral_trust}</strong> persons"
        
        cursor.execute("SELECT COUNT(*) FROM persons WHERE trust_score >= 0.2 AND trust_score < 0.4")
        low_trust = cursor.fetchone()[0]
        html_content += f"<p>Low Trust (0.2-0.4): <strong>{low_trust}</strong> persons"
        
        cursor.execute("SELECT COUNT(*) FROM persons WHERE trust_score < 0.2")
        very_low_trust = cursor.fetchone()[0]
        html_content += f"<p>Very Low Trust (<0.2): <strong>{very_low_trust}</strong> persons"
        
        html_content += f"""
    </div>
    
    <h2>Recommendations</h2>
    <ul>
    """
        
        if recent_events < 10:
            html_content += "<li>Increase social interactions to improve tracking</li>"
        if person_count < 10:
            html_content += "<li>Add more persons to expand social graph</li>"
        if avg_trust < 0.5:
            html_content += "<li>Focus on building trust with key persons</li>"
        if commitment_count > 0 and recent_commitments == 0:
            html_content += "<li>Review pending commitments regularly</li>"
        
        html_content += """
    </ul>
    
    <hr>
    <p style="margin-top: 40px; color: #666;">
        Generated by Hermes Social Tracking Plugin v0.3.0<br>
        https://github.com/yourusername/hermes-social-tracking-plugin
    </p>
</body>
</html>
"""
        
        # Write HTML to file
        with open(output_file, 'w') as f:
            f.write(html_content)
        
        print(f"✓ HTML report generated: {output_file}")
        print(f"✓ Persons: {person_count}")
        print(f"✓ Events: {event_count}")
        print(f"✓ Commitments: {commitment_count}")
        print(f"✓ Top persons: {len(top_persons)}")
        return True
    except Exception as e:
        print(f"✗ Error generating HTML report: {e}")
        return False

def main():
    print("Hermes Social Tracking Plugin - HTML Report Generator")
    print("=" * 60)
    
    if len(sys.argv) < 2:
        print("Usage: scripts/generate_html_report.sh <output_file.html>")
        print("\nExample: scripts/generate_html_report.sh social_report.html")
        return 1
    
    output_file = Path(sys.argv[1])
    success = generate_html_report(output_file)
    
    if success:
        print("\n" + "=" * 60)
        print("✓✓✓ HTML report generated successfully! ✓✓✓")
        return 0
    else:
        print("\n" + "=" * 60)
        print("✗✗✗ Failed to generate HTML report ✗✗✗")
        return 1

if __name__ == "__main__":
    sys.exit(main())