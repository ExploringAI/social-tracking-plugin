#!/usr/bin/env python3
"""
Hermes Social Tracking Plugin - Update Script
This script updates the plugin from GitHub.
"""

import subprocess
import sys
from pathlib import Path

def backup_plugin():
    """Create a backup before updating."""
    plugin_dir = Path.home() / ".hermes" / "plugins" / "social-tracking"
    
    if plugin_dir.exists():
        print("Creating backup before update...")
        subprocess.run(["scripts/backup_before_update.sh"], check=True)
    else:
        print("No existing plugin found, skipping backup.")

def update_from_github():
    """Update the plugin from GitHub repository."""
    print("Updating social tracking plugin from GitHub...")
    
    # Clone or pull the latest version
    repo_url = "https://github.com/yourusername/hermes-social-tracking-plugin.git"
    plugin_dest = Path.home() / ".hermes" / "plugins" / "social-tracking"
    
    try:
        if plugin_dest.exists():
            # Pull the latest changes
            print("Pulling latest changes from GitHub...")
            subprocess.run(["git", "pull"], cwd=plugin_dest, check=True, capture_output=True)
        else:
            # Clone the repository
            print("Cloning repository from GitHub...")
            subprocess.run(["git", "clone", repo_url, str(plugin_dest)], check=True, capture_output=True)
        
        print("✓ Plugin updated successfully!")
        return True
    except subprocess.CalledProcessError as e:
        print(f"✗ Error updating plugin: {e.stderr.decode() if e.stderr else 'Unknown error'}")
        return False

def main():
    print("Hermes Social Tracking Plugin - Update Script")
    print("=" * 50)
    
    # Create backup
    backup_plugin()
    
    # Update from GitHub
    success = update_from_github()
    
    if success:
        print("\n✓✓✓ Plugin updated successfully! ✓✓✓")
        print("\nNext steps:")
        print("1. Restart Hermes agent")
        print("2. Verify installation: scripts/verify_installation.py")
        return 0
    else:
        print("\n✗✗✗ Update failed ✗✗✗")
        return 1

if __name__ == "__main__":
    sys.exit(main())