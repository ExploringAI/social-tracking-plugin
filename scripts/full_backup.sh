#!/usr/bin/env python3
"""
Hermes Social Tracking Plugin - Full Backup Script
This script creates a full backup of plugin configuration and data.
"""

import sys
import shutil
import yaml
from pathlib import Path
from datetime import datetime

def full_backup():
    """Create a full backup of plugin configuration and data."""
    home = Path.home()
    
    # Define what to backup
    backup_items = {
        "config": home / ".hermes" / "plugins" / "social-tracking" / "config.py",
        "plugin_yaml": home / ".hermes" / "plugins" / "social-tracking" / "plugin.yaml",
        "database": home / ".hermes" / "data" / "social_tracking.db",
    }
    
    # Create backup directory
    backup_dir = home / ".hermes" / "backups" / "social_tracking_full"
    backup_dir.mkdir(parents=True, exist_ok=True)
    
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_name = f"social_tracking_full_backup_{timestamp}"
    backup_path = backup_dir / backup_name
    
    try:
        # Create backup directory
        backup_path.mkdir()
        print(f"✓ Created backup directory: {backup_path}")
        
        # Copy configuration files
        for name, item in backup_items.items():
            if item.exists():
                dest = backup_path / f"{name}_{timestamp}{item.suffix}"
                shutil.copy2(item, dest)
                print(f"✓ Backed up {name}: {dest}")
            else:
                print(f"○ {name} not found, skipping")
        
        # Create a manifest file
        manifest = {
            "backup_name": backup_name,
            "timestamp": timestamp,
            "created_at": datetime.now().isoformat(),
            "contents": {name: str(item) for name, item in backup_items.items() if item.exists()},
        }
        
        manifest_file = backup_path / "manifest.yaml"
        with open(manifest_file, 'w') as f:
            yaml.dump(manifest, f, default_flow_style=False, sort_keys=False)
        
        print(f"✓ Created manifest: {manifest_file}")
        
        # Create a compressed archive
        archive_file = Path.home() / f"social_tracking_backup_{timestamp}.tar.gz"
        shutil.make_archive(str(archive_file.with_suffix('')), 'tar.gz', backup_path)
        
        print(f"✓ Created compressed archive: {archive_file}")
        print(f"✓ Archive size: {archive_file.stat().st_size} bytes")
        
        print("\n✓✓✓ Full backup completed successfully! ✓✓✓")
        return True
    except Exception as e:
        print(f"✗ Error creating full backup: {e}")
        return False

def main():
    print("Hermes Social Tracking Plugin - Full Backup")
    print("=" * 60)
    
    success = full_backup()
    
    if success:
        return 0
    else:
        return 1

if __name__ == "__main__":
    sys.exit(main())