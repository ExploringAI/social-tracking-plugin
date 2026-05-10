#!/usr/bin/env python3
"""
Hermes Social Tracking Plugin - Dependency Report
This script generates a dependency report.
"""

import sys
import pkg_resources
from pathlib import Path

def generate_dependency_report():
    """Generate a dependency report."""
    plugin_dir = Path.home() / ".hermes" / "plugins" / "social-tracking"
    requirements_file = plugin_dir / "requirements.txt"
    
    print("Social Tracking Plugin Dependency Report")
    print("=" * 60)
    
    # Check if requirements.txt exists
    if requirements_file.exists():
        with open(requirements_file, 'r') as f:
            requirements = [line.strip() for line in f if line.strip() and not line.startswith('#')]
        
        print(f"\nRequired Dependencies ({len(requirements)}):")
        print("-" * 60)
        
        missing = []
        for req in requirements:
            try:
                # Try to import the package
                package_name = req.split('==')[0] if '==' in req else req
                __import__(package_name)
                print(f"✓ {package_name}")
            except ImportError:
                missing.append(package_name)
                print(f"✗ {package_name} (NOT INSTALLED)")
        
        if missing:
            print(f"\n✗ Missing Dependencies ({len(missing)}):")
            for pkg in missing:
                print(f"  - {pkg}")
            print(f"\nInstall with: pip install {' '.join(missing)}")
        else:
            print("\n✓ All required dependencies are installed")
    else:
        print("✗ requirements.txt not found in plugin directory")
        return False
    
    # Check optional dependencies
    print(f"\nOptional Dependencies:")
    print("-" * 60)
    
    # Check for spaCy
    try:
        import spacy
        print("✓ spaCy (optional, for advanced entity extraction)")
    except ImportError:
        print("○ spaCy (optional, not installed)")
    
    return True

def main():
    success = generate_dependency_report()
    return 0 if success else 1

if __name__ == "__main__":
    sys.exit(main())