#!/usr/bin/env python3
"""
Hermes Social Tracking Plugin - Export to JSON
This script exports all social data to a JSON file.
"""

import sys
import sqlite3
import json
from pathlib import Path
from datetime import datetime

def export_to_json(output_file):
    """Export all social data to a JSON file."""
    db_path = Path.home() / ".hermes" / "data" / "social_tracking.db"
    
    if not db_path.exists():
        print(f"Database not found at: {db_path}")
        return False
    
    try:
        conn = sqlite3.connect(db_path)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()
        
        data = {
            "export_metadata": {
                "generated_at": datetime.now().isoformat(),
                "database_path": str(db_path),
            },
            "persons": [],
            "events": [],
            "commitments": [],
            "relationships": [],
        }
        
        # Export persons
        cursor.execute("SELECT * FROM persons")
        for row in cursor.fetchall():
            data["persons"].append(dict(row))
        
        # Export events
        cursor.execute("SELECT * FROM events")
        for row in cursor.fetchall():
            data["events"].append(dict(row))
        
        # Export commitments
        cursor.execute("SELECT * FROM commitments")
        for row in cursor.fetchall():
            data["commitments"].append(dict(row))
        
        # Export relationships
        cursor.execute("SELECT * FROM relationships")
        for row in cursor.fetchall():
            data["relationships"].append(dict(row))
        
        conn.close()
        
        # Write to JSON file
        with open(output_file, 'w') as f:
            json.dump(data, f, indent=2, default=str)
        
        print(f"✓ Exported social data to: {output_file}")
        print(f"✓ Persons: {len(data['persons'])}")
        print(f"✓ Events: {len(data['events'])}")
        print(f"✓ Commitments: {len(data['commitments'])}")
        print(f"✓ Relationships: {len(data['relationships'])}")
        print(f"✓ Total records: {len(data['persons']) + len(data['events']) + len(data['commitments']) + len(data['relationships'])}")
        
        return True
    except Exception as e:
        print(f"✗ Error exporting to JSON: {e}")
        return False

def main():
    print("Hermes Social Tracking Plugin - Export to JSON")
    print("=" * 60)
    
    if len(sys.argv) < 2:
        print("Usage: scripts/export_to_json.sh <output_file.json>")
        print("\nExample: scripts/export_to_json.sh social_data_export.json")
        return 1
    
    output_file = Path(sys.argv[1])
    success = export_to_json(output_file)
    
    if success:
        print("\n" + "=" * 60)
        print("✓✓✓ JSON export completed successfully! ✓✓✓")
        return 0
    else:
        print("\n" + "=" * 60)
        print("✗✗✗ JSON export failed ✗✗✗")
        return 1

if __name__ == "__main__":
    sys.exit(main())