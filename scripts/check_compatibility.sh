#!/usr/bin/env python3
"""
Hermes Social Tracking Plugin - Compatibility Check
This script checks if the plugin is compatible with the current Hermes version.
"""

import sys
import re
from pathlib import Path

def check_hermes_version():
    """Check Hermes version compatibility."""
    # Try to get Hermes version from config or environment
    hermes_version = "unknown"
    
    # Check if Hermes is installed
    try:
        import hermes
        hermes_version = hermes.__version__
        print(f"✓ Hermes found: version {hermes_version}")
    except ImportError:
        print("○ Hermes not found in Python environment")
        return False
    
    # Check compatibility
    # This is a simple version check - in reality you'd want more sophisticated parsing
    version_pattern = r"^\d+\.\d+\.\d+"
    match = re.match(version_pattern, hermes_version)
    
    if match:
        major_version = int(hermes_version.split('.')[0])
        minor_version = int(hermes_version.split('.')[1])
        
        # Social tracking plugin requires Hermes 1.0+
        if major_version >= 1 and minor_version >= 0:
            print(f"✓ Hermes version {hermes_version} is compatible")
            return True
        else:
            print(f"✗ Hermes version {hermes_version} may not be compatible")
            print("  Social tracking plugin requires Hermes 1.0 or higher")
            return False
    else:
        print(f"○ Unknown Hermes version format: {hermes_version}")
        return False

def check_plugin_structure():
    """Check if plugin has the expected structure."""
    plugin_dir = Path.home() / ".hermes" / "plugins" / "social-tracking"
    
    required_files = [
        "__init__.py",
        "config.py",
        "db.py",
        "plugin.yaml",
    ]
    
    missing_files = []
    for file in required_files:
        if not (plugin_dir / file).exists():
            missing_files.append(file)
    
    if missing_files:
        print(f"✗ Missing required files: {', '.join(missing_files)}")
        return False
    else:
        print("✓ All required plugin files exist")
        return True

def check_dependencies():
    """Check if required Python packages are installed."""
    required_packages = ["pydantic"]
    missing_packages = []
    
    for package in required_packages:
        try:
            __import__(package)
            print(f"✓ {package} is installed")
        except ImportError:
            missing_packages.append(package)
    
    if missing_packages:
        print(f"✗ Missing required packages: {', '.join(missing_packages)}")
        print(f"  Install with: pip install {', '.join(missing_packages)}")
        return False
    else:
        print("✓ All required packages are installed")
        return True

def main():
    print("Hermes Social Tracking Plugin - Compatibility Check")
    print("=" * 60)
    
    checks = [
        check_hermes_version,
        check_plugin_structure,
        check_dependencies,
    ]
    
    results = [check() for check in checks]
    
    print("\n" + "=" * 60)
    if all(results):
        print("✓✓✓ Compatibility Check Passed! ✓✓✓")
        print("\nThe social tracking plugin should work correctly with your Hermes installation.")
        return 0
    else:
        print("✗✗✗ Compatibility Check Failed ✗✗✗")
        print("\nPlease review the issues above and fix them before using the plugin.")
        return 1

if __name__ == "__main__":
    sys.exit(main())