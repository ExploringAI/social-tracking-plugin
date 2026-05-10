#!/usr/bin/env python3
"""
Hermes Social Tracking Plugin - Installation Verification
This script checks if the plugin is installed correctly and working.
"""

import sys
import os
from pathlib import Path

def check_plugin_installed():
    """Check if plugin is installed in the expected location."""
    plugin_path = Path.home() / ".hermes" / "plugins" / "social-tracking"
    
    print("=== Installation Verification ===")
    print(f"Checking plugin at: {plugin_path}")
    
    if plugin_path.exists() and plugin_path.is_dir():
        print(f"✓ Plugin directory exists")
        files = list(plugin_path.glob("*.py"))
        if files:
            print(f"✓ Found {len(files)} Python files")
            return True
        else:
            print("✗ No Python files found in plugin directory")
            return False
    else:
        print("✗ Plugin directory not found")
        return False

def check_python_imports():
    """Check if Python imports work correctly."""
    print("\n=== Python Import Check ===")
    try:
        import social_tracking
        from social_tracking.config import SocialTrackingConfig
        
        # Test basic config
        config = SocialTrackingConfig()
        print(f"✓ Successfully imported social_tracking module")
        print(f"✓ Config class loaded")
        return True
    except ImportError as e:
        print(f"✗ Import failed: {e}")
        return False
    except Exception as e:
        print(f"✗ Unexpected error: {e}")
        return False

def check_dependencies():
    """Check if required dependencies are installed."""
    print("\n=== Dependency Check ===")
    dependencies = {
        "pydantic": "pydantic",
        "spacy": "spacy (optional)", 
    }
    
    missing = []
    for dep, desc in dependencies.items():
        try:
            if dep == "pydantic":
                import pydantic
                print(f"✓ {desc}")
            elif dep == "spacy":
                # spaCy is optional, so we just check if it's there
                try:
                    import spacy
                    print(f"✓ {desc}")
                except ImportError:
                    print(f"○ {desc} (not installed - optional)")
        except ImportError:
            missing.append(desc)
    
    if missing:
        print(f"✗ Missing dependencies: {', '.join(missing)}")
        return False
    else:
        print("✓ All required dependencies are installed")
        return True

def main():
    print("Hermes Social Tracking Plugin - Installation Verification")
    print("=" * 50)
    
    results = []
    results.append(check_plugin_installed())
    results.append(check_python_imports())
    results.append(check_dependencies())
    
    print("\n" + "=" * 50)
    if all(results):
        print("✓✓✓ Installation Verified Successfully! ✓✓✓")
        print("\nNext steps:")
        print("1. Add configuration to your Hermes config.yaml")
        print("2. Restart Hermes agent")
        print("3. Test with: /social_get_context")
        return 0
    else:
        print("✗✗✗ Installation Verification Failed ✗✗✗")
        print("\nPlease check the errors above and try again.")
        return 1

if __name__ == "__main__":
    sys.exit(main())