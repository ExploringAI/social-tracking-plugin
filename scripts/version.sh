#!/usr/bin/env python3
"""
Hermes Social Tracking Plugin - Version Check Script
This script displays the current version of the plugin.
"""

import sys
import json
from pathlib import Path

def get_plugin_version():
    """Get the plugin version from plugin.yaml."""
    plugin_yaml = Path.home() / ".hermes" / "plugins" / "social-tracking" / "plugin.yaml"
    
    if plugin_yaml.exists():
        import yaml
        with open(plugin_yaml, 'r') as f:
            config = yaml.safe_load(f)
        return config.get('version', 'Unknown')
    else:
        return "Not installed"

def main():
    print("Hermes Social Tracking Plugin - Version Check")
    print("=" * 50)
    print(f"Current version: {get_plugin_version()}")
    print("=" * 50)

if __name__ == "__main__":
    main()