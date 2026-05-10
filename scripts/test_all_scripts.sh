#!/usr/bin/env python3
"""
Hermes Social Tracking Plugin - Test All Scripts
This script tests all other scripts to ensure they're working.
"""

import subprocess
import sys
from pathlib import Path

def test_script(script_path):
    """Test a single script."""
    print(f"\nTesting: {script_path.name}")
    print("-" * 40)
    
    try:
        result = subprocess.run(
            ["python", str(script_path)],
            capture_output=True,
            text=True,
            timeout=30
        )
        
        if result.returncode == 0:
            print("✓ Script executed successfully")
            if result.stdout:
                print(result.stdout)
            return True
        else:
            print("✗ Script failed")
            if result.stderr:
                print("Error output:")
                print(result.stderr)
            return False
    except subprocess.TimeoutExpired:
        print("✗ Script timeout")
        return False
    except Exception as e:
        print(f"✗ Error running script: {e}")
        return False

def test_all_scripts():
    """Test all scripts in the scripts directory."""
    scripts_dir = Path(__file__).parent / "scripts"
    scripts = list(scripts_dir.glob("*.sh"))
    
    if not scripts:
        print("No scripts found to test")
        return False
    
    results = []
    for script in scripts:
        # Skip this script
        if script.name == "test_all_scripts.sh":
            continue
        results.append(test_script(script))
    
    return all(results)

def main():
    print("Hermes Social Tracking Plugin - Test All Scripts")
    print("=" * 60)
    
    success = test_all_scripts()
    
    if success:
        print("\n" + "=" * 60)
        print("✓✓✓ All scripts tested successfully! ✓✓✓")
        return 0
    else:
        print("\n" + "=" * 60)
        print("✗✗✗ Some scripts failed ✗✗✗")
        return 1

if __name__ == "__main__":
    sys.exit(main())