#!/usr/bin/env python3
"""
Hermes Social Tracking Plugin - Scripts Overview
This script lists all available scripts and their purposes.
"""

import sys
import json
from pathlib import Path

def list_scripts():
    """List all available scripts with descriptions."""
    scripts_dir = Path(__file__).parent / "scripts"
    
    if not scripts_dir.exists():
        print("Scripts directory not found")
        return False
    
    scripts = []
    for script_file in scripts_dir.glob("*.sh"):
        script_name = script_file.name
        description = ""
        
        # Get description from script header comments
        with open(script_file, 'r') as f:
            lines = f.readlines()
            in_description = False
            description_lines = []
            
            for line in lines:
                if line.startswith('"""'):
                    if not in_description:
                        in_description = True
                    else:
                        break
                elif in_description and line.strip():
                    description_lines.append(line.strip())
        
        if description_lines:
            description = " ".join(description_lines)
        else:
            description = "No description available"
        
        scripts.append({
            "name": script_name,
            "description": description,
            "path": str(script_file)
        })
    
    if not scripts:
        print("No scripts found in scripts directory")
        return False
    
    print("Hermes Social Tracking Plugin - Available Scripts")
    print("=" * 60)
    print()
    
    for script in scripts:
        print(f"### {script['name']}")
        print(f"{script['description']}")
        print(f"```\n./scripts/{script['name']}\n```")
        print()
    
    print("=" * 60)
    print(f"Found {len(scripts)} scripts")
    return True

def main():
    print("Hermes Social Tracking Plugin - Scripts Overview")
    print("=" * 60)
    
    success = list_scripts()
    
    if success:
        print("\n✓✓✓ Scripts overview generated successfully! ✓✓✓")
        return 0
    else:
        print("\n✗✗✗ Failed to list scripts ✗✗✗")
        return 1

if __name__ == "__main__":
    sys.exit(main())