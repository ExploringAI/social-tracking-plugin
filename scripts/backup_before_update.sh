#!/usr/bin/env python3
"""
Hermes Social Tracking Plugin - Backup Script
This script creates a backup of the plugin before updating.
"""

import shutil
import sys
from pathlib import Path
from datetime import datetime

def backup_plugin():
    """Create a backup of the plugin."""
    plugin_dir = Path.home() / ".hermes" / "plugins" / "social-tracking"
    backup_dir = Path.home() / ".hermes" / "plugins" / "social_tracking_backups"
    
    if not plugin_dir.exists():
        print(f"Plugin not found at {plugin_dir}")
        return False
    
    # Create backup directory if it doesn't exist
    backup_dir.mkdir(parents=True, exist_ok=True)
    
    # Create timestamped backup filename
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_name = f"social_tracking_backup_{timestamp}"
    backup_path = backup_dir / backup_name
    
    try:
        shutil.copytree(plugin_dir, backup_path)
        print(f"✓ Created backup at: {backup_path}")
        return True
    except Exception as e:
        print(f"✗ Error creating backup: {e}")
        return False

def main():
    print("Hermes Social Tracking Plugin - Backup Script")
    print("=" * 50)
    
    success = backup_plugin()
    
    if success:
        print("\n✓✓✓ Backup created successfully! ✓✓✓")
        return 0
    else:
        print("\n✗✗✗ Backup failed ✗✗✗")
        return 1

if __name__ == "__main__":
    sys.exit(main())