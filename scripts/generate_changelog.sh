#!/usr/bin/env python3
"""
Hermes Social Tracking Plugin - Changelog Generator
This script generates a changelog from git history.
"""

import sys
import subprocess
from pathlib import Path
from datetime import datetime

def generate_changelog():
    """Generate changelog from git history."""
    plugin_dir = Path.home() / ".hermes" / "plugins" / "social-tracking"
    
    if not plugin_dir.exists():
        print(f"Plugin directory not found: {plugin_dir}")
        return False
    
    try:
        # Get git log
        result = subprocess.run(
            ["git", "log", "--oneline", "--all", "--no-merges", "--since=\"30 days ago\""],
            cwd=plugin_dir,
            capture_output=True,
            text=True,
            timeout=30
        )
        
        commits = result.stdout.strip().split('\n')
        
        changelog = f"""# Social Tracking Plugin Changelog

Generated: {datetime.now().isoformat()}
Plugin Version: 0.3.0

## Recent Changes (Last 30 Days)

"""
        
        for commit in commits:
            if commit.strip():
                changelog += f"- {commit.strip()}\n"
        
        return changelog
    except Exception as e:
        print(f"✗ Error generating changelog: {e}")
        return False

def main():
    print("Hermes Social Tracking Plugin - Changelog Generator")
    print("=" * 60)
    
    changelog = generate_changelog()
    
    if changelog:
        print(changelog)
        return 0
    else:
        print("\n" + "=" * 60)
        print("✗✗✗ Failed to generate changelog ✗✗✗")
        return 1

if __name__ == "__main__":
    sys.exit(main())