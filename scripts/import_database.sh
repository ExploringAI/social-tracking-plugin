#!/usr/bin/env python3
"""
Hermes Social Tracking Plugin - Import Database Script
This script imports a social database from a backup file.
"""

import sys
import sqlite3
import shutil
from pathlib import Path

def import_database(export_file):
    """Import the database from a SQL export file."""
    db_path = Path.home() / ".hermes" / "data" / "social_tracking.db"
    backup_dir = Path.home() / ".hermes" / "backups" / "social_tracking"
    
    # Create backup directory if it doesn't exist
    backup_dir.mkdir(parents=True, exist_ok=True)
    
    # Backup current database if it exists
    if db_path.exists():
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_file = backup_dir / f"social_tracking_backup_{timestamp}.db"
        shutil.copy2(db_path, backup_file)
        print(f"✓ Current database backed up to: {backup_file}")
    
    try:
        # Read the export file
        with open(export_file, 'r') as f:
            sql_statements = f.read()
        
        # Recreate the database
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Execute all SQL statements
        cursor.executescript(sql_statements)
        
        conn.commit()
        conn.close()
        
        print(f"✓ Database imported successfully from: {export_file}")
        print(f"✓ Database size: {db_path.stat().st_size} bytes")
        return True
    except Exception as e:
        print(f"✗ Error importing database: {e}")
        return False

def main():
    print("Hermes Social Tracking Plugin - Import Database")
    print("=" * 50)
    
    if len(sys.argv) < 2:
        print("Usage: scripts/import_database.sh <export_file.sql>")
        print("\nExample: scripts/import_database.sh ~/.hermes/backups/social_tracking/social_tracking_export_20240101_120000.sql")
        return 1
    
    export_file = Path(sys.argv[1])
    if not export_file.exists():
        print(f"✗ Export file not found: {export_file}")
        return 1
    
    success = import_database(export_file)
    
    if success:
        print("\n✓✓✓ Import completed successfully! ✓✓✓")
        return 0
    else:
        print("\n✗✗✗ Import failed ✗✗✗")
        return 1

if __name__ == "__main__":
    sys.exit(main())