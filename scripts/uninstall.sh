#!/usr/bin/env python3
"""
Hermes Social Tracking Plugin - Uninstall Script
This script removes the plugin from the Hermes plugins directory.
"""

import shutil
import sys
from pathlib import Path

def uninstall_plugin():
    """Uninstall the social tracking plugin."""
    plugin_dir = Path.home() / ".hermes" / "plugins" / "social-tracking"
    
    print("=== Social Tracking Plugin Uninstall ===")
    print(f"Checking for plugin at: {plugin_dir}")
    
    if plugin_dir.exists() and plugin_dir.is_dir():
        try:
            shutil.rmtree(plugin_dir)
            print(f"✓ Successfully removed plugin from {plugin_dir}")
            return True
        except Exception as e:
            print(f"✗ Error removing plugin: {e}")
            return False
    else:
        print("✗ Plugin not found at the specified location")
        return False

def main():
    print("Hermes Social Tracking Plugin - Uninstall Script")
    print("=" * 50)
    
    response = input("Are you sure you want to uninstall the social tracking plugin? (y/n): ")
    if response.lower() == 'y':
        success = uninstall_plugin()
        if success:
            print("\n✓✓✓ Plugin uninstalled successfully! ✓✓✓")
            print("\nNote: The database file at ~/.hermes/data/social_tracking.db")
            print("will not be removed automatically.")
        else:
            print("\n✗✗✗ Uninstallation failed ✗✗✗")
            return 1
    else:
        print("Uninstall cancelled.")
    
    return 0

if __name__ == "__main__":
    sys.exit(main())