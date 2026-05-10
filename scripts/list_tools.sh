#!/usr/bin/env python3
"""
Hermes Social Tracking Plugin - Tools List Script
This script lists all tools provided by the plugin.
"""

import sys
import yaml
from pathlib import Path

def list_plugin_tools():
    """List all tools provided by the plugin."""
    plugin_yaml = Path.home() / ".hermes" / "plugins" / "social-tracking" / "plugin.yaml"
    
    if plugin_yaml.exists():
        with open(plugin_yaml, 'r') as f:
            config = yaml.safe_load(f)
        
        provides_tools = config.get('provides_tools', [])
        
        print("Hermes Social Tracking Plugin - Available Tools")
        print("=" * 50)
        if provides_tools:
            for i, tool in enumerate(provides_tools, 1):
                print(f"{i}. {tool}")
        else:
            print("No tools defined in plugin.yaml")
    else:
        print("Plugin not installed or plugin.yaml not found")
        print("Install the plugin first:")
        print("  scripts/install.sh")
        return False
    
    return True

def main():
    print("Hermes Social Tracking Plugin - Tools List")
    print("=" * 50)
    success = list_plugin_tools()
    print("=" * 50)
    return 0 if success else 1

if __name__ == "__main__":
    sys.exit(main())