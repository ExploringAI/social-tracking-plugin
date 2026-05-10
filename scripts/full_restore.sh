#!/usr/bin/env python3
"""
Hermes Social Tracking Plugin - Full Restore Script
This script restores the plugin from a full backup.
"""

import sys
import shutil
import yaml
from pathlib import Path

def full_restore(backup_archive):
    """Restore from a full backup archive."""
    # Extract archive
    extract_dir = Path.home() / ".hermes" / "backups" / "social_tracking_extract"
    extract_dir.mkdir(parents=True, exist_ok=True)
    
    try:
        # Extract tar.gz archive
        import tarfile
        with tarfile.open(backup_archive, "r:gz") as tar:
            tar.extractall(path=str(extract_dir))
        print(f"✓ Extracted archive to: {extract_dir}")
        
        # Find the backup directory (should be the only directory extracted)
        backup_dirs = list(extract_dir.glob("*/"))
        if not backup_dirs:
            print("✗ No backup directory found in archive")
            return False
        
        backup_path = backup_dirs[0]
        
        # Read manifest
        manifest_file = backup_path / "manifest.yaml"
        if not manifest_file.exists():
            print("✗ manifest.yaml not found in backup")
            return False
        
        with open(manifest_file, 'r') as f:
            manifest = yaml.safe_load(f)
        
        print(f"✓ Restoring from backup: {manifest['backup_name']}")
        
        # Restore files
        home = Path.home()
        restored_files = []
        
        # Restore config
        config_backup = backup_path / "config_backup.py"
        if config_backup.exists():
            config_dest = home / ".hermes" / "plugins" / "social-tracking" / "config.py"
            shutil.copy2(config_backup, config_dest)
            restored_files.append(str(config_dest))
            print(f"✓ Restored config: {config_dest}")
        
        # Restore database
        db_backup = backup_path / "database"
        if db_backup.exists():
            db_dest = home / ".hermes" / "data" / "social_tracking.db"
            shutil.copy2(db_backup, db_dest)
            restored_files.append(str(db_dest))
            print(f"✓ Restored database: {db_dest}")
        
        print(f"\n✓ Restore completed! Restored {len(restored_files)} files.")
        return True
    except Exception as e:
        print(f"✗ Error during restore: {e}")
        return False

def main():
    print("Hermes Social Tracking Plugin - Full Restore")
    print("=" * 60)
    
    if len(sys.argv) < 2:
        print("Usage: scripts/full_restore.sh <backup_archive.tar.gz>")
        print("\nExample: scripts/full_restore.sh ~/social_tracking_backup_20240101_120000.tar.gz")
        return 1
    
    backup_archive = Path(sys.argv[1])
    if not backup_archive.exists():
        print(f"✗ Backup archive not found: {backup_archive}")
        return 1
    
    success = full_restore(backup_archive)
    
    if success:
        print("\n✓✓✓ Restore completed successfully! ✓✓✓")
        print("\nNext steps:")
        print("1. Restart Hermes agent")
        print("2. Verify installation: scripts/verify_installation.py")
        return 0
    else:
        print("\n✗✗✗ Restore failed ✗✗✗")
        return 1

if __name__ == "__main__":
    sys.exit(main())