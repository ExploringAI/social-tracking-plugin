#!/usr/bin/env python3
"""
Hermes Social Tracking Plugin - Import from CSV
This script imports social data from CSV files.
"""

import sys
import sqlite3
import csv
from pathlib import Path
from datetime import datetime

def import_from_csv(input_dir):
    """Import social data from CSV files."""
    db_path = Path.home() / ".hermes" / "data" / "social_tracking.db"
    
    if not db_path.exists():
        print(f"Database not found at: {db_path}")
        return False
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        input_dir = Path(input_dir)
        
        # Import persons
        persons_file = input_dir / "persons.csv"
        if persons_file.exists():
            with open(persons_file, 'r') as f:
                reader = csv.reader(f)
                columns = next(reader)
                cursor.executemany(
                    f"INSERT OR REPLACE INTO persons ({','.join(columns)}) VALUES ({','.join(['?']*len(columns))})",
                    [tuple(row) for row in reader]
                )
            print(f"✓ Imported persons: {sum(1 for _ in open(persons_file)) - 1} rows")
        
        # Import events
        events_file = input_dir / "events.csv"
        if events_file.exists():
            with open(events_file, 'r') as f:
                reader = csv.reader(f)
                columns = next(reader)
                cursor.executemany(
                    f"INSERT OR REPLACE INTO events ({','.join(columns)}) VALUES ({','.join(['?']*len(columns))})",
                    [tuple(row) for row in reader]
                )
            print(f"✓ Imported events: {sum(1 for _ in open(events_file)) - 1} rows")
        
        # Import commitments
        commitments_file = input_dir / "commitments.csv"
        if commitments_file.exists():
            with open(commitments_file, 'r') as f:
                reader = csv.reader(f)
                columns = next(reader)
                cursor.executemany(
                    f"INSERT OR REPLACE INTO commitments ({','.join(columns)}) VALUES ({','.join(['?']*len(columns))})",
                    [tuple(row) for row in reader]
                )
            print(f"✓ Imported commitments: {sum(1 for _ in open(commitments_file)) - 1} rows")
        
        # Import relationships
        relationships_file = input_dir / "relationships.csv"
        if relationships_file.exists():
            with open(relationships_file, 'r') as f:
                reader = csv.reader(f)
                columns = next(reader)
                cursor.executemany(
                    f"INSERT OR REPLACE INTO relationships ({','.join(columns)}) VALUES ({','.join(['?']*len(columns))})",
                    [tuple(row) for row in reader]
                )
            print(f"✓ Imported relationships: {sum(1 for _ in open(relationships_file)) - 1} rows")
        
        conn.commit()
        conn.close()
        
        print(f"✓ Imported social data from: {input_dir}")
        return True
    except Exception as e:
        print(f"✗ Error importing from CSV: {e}")
        return False

def main():
    print("Hermes Social Tracking Plugin - Import from CSV")
    print("=" * 60)
    
    if len(sys.argv) < 2:
        print("Usage: scripts/import_from_csv.sh <input_directory>")
        print("\nExample: scripts/import_from_csv.sh ./exports")
        return 1
    
    input_dir = sys.argv[1]
    success = import_from_csv(input_dir)
    
    if success:
        print("\n" + "=" * 60)
        print("✓✓✓ CSV import completed successfully! ✓✓✓")
        return 0
    else:
        print("\n" + "=" * 60)
        print("✗✗✗ CSV import failed ✗✗✗")
        return 1

if __name__ == "__main__":
    sys.exit(main())