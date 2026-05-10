#!/usr/bin/env python3
"""
Hermes Social Tracking Plugin - Export Database Script
This script exports the social database to a SQL file.
"""

import sys
import sqlite3
import shutil
from pathlib import Path
from datetime import datetime

def export_database():
    """Export the database to a SQL file."""
    db_path = Path.home() / ".hermes" / "data" / "social_tracking.db"
    export_dir = Path.home() / ".hermes" / "backups" / "social_tracking"
    
    if not db_path.exists():
        print(f"Database not found at: {db_path}")
        return False
    
    # Create export directory if it doesn't exist
    export_dir.mkdir(parents=True, exist_ok=True)
    
    # Create timestamped export filename
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    export_file = export_dir / f"social_tracking_export_{timestamp}.sql"
    
    try:
        # Use sqlite3 to dump the database
        with open(export_file, 'w') as f:
            # Connect to the database and export
            conn = sqlite3.connect(db_path)
            for line in conn.iterdump():
                f.write('%s\n' % line)
            conn.close()
        
        print(f"✓ Database exported to: {export_file}")
        print(f"✓ Size: {export_file.stat().st_size} bytes")
        return True
    except Exception as e:
        print(f"✗ Error exporting database: {e}")
        return False

def main():
    print("Hermes Social Tracking Plugin - Export Database")
    print("=" * 50)
    
    success = export_database()
    
    if success:
        print("\n✓✓✓ Export completed successfully! ✓✓✓")
        return 0
    else:
        print("\n✗✗✗ Export failed ✗✗✗")
        return 1

if __name__ == "__main__":
    sys.exit(main())