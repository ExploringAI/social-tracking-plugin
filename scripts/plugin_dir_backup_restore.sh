#!/usr/bin/env python3
"""
Hermes Social Tracking Plugin - Directory Backup/Restore
This script backs up and restores the entire plugin directory.
"""

import sys
import shutil
import tarfile
from pathlib import Path
from datetime import datetime

def backup_plugin():
    """Backup the entire plugin directory."""
    plugin_dir = Path.home() / ".hermes" / "plugins" / "social-tracking"
    backup_dir = Path.home() / ".hermes" / "backups" / "social_tracking_plugin"
    
    if not plugin_dir.exists():
        print(f"Plugin directory not found: {plugin_dir}")
        return False
    
    backup_dir.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_file = backup_dir / f"social_tracking_plugin_backup_{timestamp}.tar.gz"
    
    try:
        with tarfile.open(backup_file, "w:gz") as tar:
            tar.add(plugin_dir, arcname="social-tracking")
        print(f"✓ Plugin directory backed up to: {backup_file}")
        print(f"✓ Backup size: {backup_file.stat().st_size} bytes")
        return True
    except Exception as e:
        print(f"✗ Error backing up plugin directory: {e}")
        return False

def restore_plugin(backup_file):
    """Restore the plugin directory from a backup."""
    backup_file = Path(backup_file)
    if not backup_file.exists():
        print(f"Backup file not found: {backup_file}")
        return False
    
    plugin_dir = Path.home() / ".hermes" / "plugins" / "social-tracking"
    
    try:
        # Extract backup
        with tarfile.open(backup_file, "r:gz") as tar:
            tar.extractall(path=plugin_dir.parent)
        
        print(f"✓ Plugin directory restored from: {backup_file}")
        print(f"✓ Restored to: {plugin_dir}")
        return True
    except Exception as e:
        print(f"✗ Error restoring plugin directory: {e}")
        return False

def main():
    print("Hermes Social Tracking Plugin - Directory Backup/Restore")
    print("=" * 60)
    
    if len(sys.argv) < 2:
        print("Usage: scripts/plugin_dir_backup_restore.sh <backup|restore> [backup_file]")
        print("\nExamples:")
        print("  scripts/plugin_dir_backup_restore.sh backup")
        print("  scripts/plugin_dir_backup_restore.sh restore /path/to/backup.tar.gz")
        return 1
    
    action = sys.argv[1]
    
    if action == "backup":
        success = backup_plugin()
    elif action == "restore":
        if len(sys.argv) < 3:
            print("Please provide backup file path for restore")
            return 1
        success = restore_plugin(sys.argv[2])
    else:
        print(f"Unknown action: {action}")
        print("Use 'backup' or 'restore'")
        return 1
    
    if success:
        print("\n" + "=" * 60)
        print("✓✓✓ Operation completed successfully! ✓✓✓")
        return 0
    else:
        print("\n" + "=" * 60)
        print("✗✗✗ Operation failed ✗✗✗")
        return 1

if __name__ == "__main__":
    sys.exit(main())