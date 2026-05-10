#!/usr/bin/env python3
"""
Hermes Social Tracking Plugin - CSV Export
This script exports social data to CSV files.
"""

import sys
import sqlite3
import csv
from pathlib import Path
from datetime import datetime

def export_to_csv(output_dir):
    """Export all social data to CSV files."""
    db_path = Path.home() / ".hermes" / "data" / "social_tracking.db"
    
    if not db_path.exists():
        print(f"Database not found at: {db_path}")
        return False
    
    try:
        conn = sqlite3.connect(db_path)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()
        
        output_dir = Path(output_dir)
        output_dir.mkdir(parents=True, exist_ok=True)
        
        # Export persons
        persons_file = output_dir / "persons.csv"
        cursor.execute("SELECT * FROM persons")
        with open(persons_file, 'w', newline='') as f:
            writer = csv.writer(f)
            writer.writerow([desc[0] for desc in cursor.description])
            writer.writerows(cursor.fetchall())
        
        # Export events
        events_file = output_dir / "events.csv"
        cursor.execute("SELECT * FROM events")
        with open(events_file, 'w', newline='') as f:
            writer = csv.writer(f)
            writer.writerow([desc[0] for desc in cursor.description])
            writer.writerows(cursor.fetchall())
        
        # Export commitments
        commitments_file = output_dir / "commitments.csv"
        cursor.execute("SELECT * FROM commitments")
        with open(commitments_file, 'w', newline='') as f:
            writer = csv.writer(f)
            writer.writerow([desc[0] for desc in cursor.description])
            writer.writerows(cursor.fetchall())
        
        # Export relationships
        relationships_file = output_dir / "relationships.csv"
        cursor.execute("SELECT * FROM relationships")
        with open(relationships_file, 'w', newline='') as f:
            writer = csv.writer(f)
            writer.writerow([desc[0] for desc in cursor.description])
            writer.writerows(cursor.fetchall())
        
        conn.close()
        
        print(f"✓ Exported social data to: {output_dir}")
        print(f"✓ Persons: {sum(1 for _ in open(persons_file)) - 1} rows")
        print(f"✓ Events: {sum(1 for _ in open(events_file)) - 1} rows")
        print(f"✓ Commitments: {sum(1 for _ in open(commitments_file)) - 1} rows")
        print(f"✓ Relationships: {sum(1 for _ in open(relationships_file)) - 1} rows")
        return True
    except Exception as e:
        print(f"✗ Error exporting to CSV: {e}")
        return False

def main():
    print("Hermes Social Tracking Plugin - CSV Export")
    print("=" * 60)
    
    if len(sys.argv) < 2:
        print("Usage: scripts/export_to_csv.sh <output_directory>")
        print("\nExample: scripts/export_to_csv.sh ./exports")
        return 1
    
    output_dir = sys.argv[1]
    success = export_to_json(output_dir)
    
    if success:
        print("\n" + "=" * 60)
        print("✓✓✓ CSV export completed successfully! ✓✓✓")
        return 0
    else:
        print("\n" + "=" * 60)
        print("✗✗✗ CSV export failed ✗✗✗")
        return 1

if __name__ == "__main__":
    sys.exit(main())