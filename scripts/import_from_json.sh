#!/usr/bin/env python3
"""
Hermes Social Tracking Plugin - Import from JSON
This script imports social data from a JSON export file.
"""

import sys
import sqlite3
import json
from pathlib import Path
from datetime import datetime

def import_from_json(input_file):
    """Import social data from a JSON file."""
    db_path = Path.home() / ".hermes" / "data" / "social_tracking.db"
    
    if not db_path.exists():
        print(f"Database not found at: {db_path}")
        return False
    
    try:
        # Read JSON file
        with open(input_file, 'r') as f:
            data = json.load(f)
        
        conn = sqlite3.connect(db_path)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()
        
        # Import persons
        cursor.executemany("""
            INSERT OR REPLACE INTO persons 
            (person_id, name, roles, last_active, trust_score, kind)
            VALUES (:person_id, :name, :roles, :last_active, :trust_score, :kind)
        """, data.get('persons', []))
        
        # Import events
        cursor.executemany("""
            INSERT OR REPLACE INTO events 
            (event_id, timestamp, kind, summary)
            VALUES (:event_id, :timestamp, :kind, :summary)
        """, data.get('events', []))
        
        # Import commitments
        cursor.executemany("""
            INSERT OR REPLACE INTO commitments 
            (commitment_id, description, status, timestamp_promised, due_date, timestamp_updated)
            VALUES (:commitment_id, :description, :status, :timestamp_promised, :due_date, :timestamp_updated)
        """, data.get('commitments', []))
        
        # Import relationships
        cursor.executemany("""
            INSERT OR REPLACE INTO relationships
            (relationship_id, person_a_id, person_b_id, rel_type, strength, status, 
             started_at, ended_at, source, confidence, notes, created_at, updated_at)
            VALUES (:relationship_id, :person_a_id, :person_b_id, :rel_type, :strength, :status,
                    :started_at, :ended_at, :source, :confidence, :notes, :created_at, :updated_at)
        """, data.get('relationships', []))
        
        conn.commit()
        conn.close()
        
        print(f"✓ Imported social data from: {input_file}")
        print(f"✓ Persons: {len(data.get('persons', []))}")
        print(f"✓ Events: {len(data.get('events', []))}")
        print(f"✓ Commitments: {len(data.get('commitments', []))}")
        print(f"✓ Relationships: {len(data.get('relationships', []))}")
        print(f"✓ Total records: {len(data.get('persons', [])) + len(data.get('events', [])) + len(data.get('commitments', [])) + len(data.get('relationships', []))}")
        
        return True
    except Exception as e:
        print(f"✗ Error importing from JSON: {e}")
        return False

def main():
    print("Hermes Social Tracking Plugin - Import from JSON")
    print("=" * 60)
    
    if len(sys.argv) < 2:
        print("Usage: scripts/import_from_json.sh <input_file.json>")
        print("\nExample: scripts/import_from_json.sh social_data_export.json")
        return 1
    
    input_file = Path(sys.argv[1])
    if not input_file.exists():
        print(f"✗ Input file not found: {input_file}")
        return 1
    
    success = import_from_json(input_file)
    
    if success:
        print("\n" + "=" * 60)
        print("✓✓✓ JSON import completed successfully! ✓✓✓")
        return 0
    else:
        print("\n" + "=" * 60)
        print("✗✗✗ JSON import failed ✗✗✗")
        return 1

if __name__ == "__main__":
    sys.exit(main())