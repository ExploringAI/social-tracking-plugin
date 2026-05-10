#!/usr/bin/env python3
"""
Hermes Social Tracking Plugin - Configuration Report
This script generates a report of current configuration settings.
"""

import sys
import yaml
from pathlib import Path

def generate_config_report():
    """Generate a configuration report."""
    plugin_dir = Path.home() / ".hermes" / "plugins" / "social-tracking"
    config_file = plugin_dir / "config.py"
    plugin_yaml = plugin_dir / "plugin.yaml"
    
    if not plugin_dir.exists():
        print(f"Plugin directory not found: {plugin_dir}")
        return False
    
    print("\n" + "=" * 60)
    print("Social Tracking Plugin Configuration Report")
    print("=" * 60)
    
    # Read plugin.yaml for basic info
    if plugin_yaml.exists():
        with open(plugin_yaml, 'r') as f:
            plugin_config = yaml.safe_load(f)
        
        print(f"\nPlugin Information:")
        print(f"  Name: {plugin_config.get('name', 'Unknown')}")
        print(f"  Version: {plugin_config.get('version', 'Unknown')}")
        print(f"  Description: {plugin_config.get('description', 'Unknown')}")
    
    # Check if config is using defaults or custom
    if config_file.exists():
        # Try to parse config file to see if it's been customized
        with open(config_file, 'r') as f:
            config_content = f.read()
        
        # Look for customizations beyond the default config
        is_custom = "SocialTrackingConfig" in config_content and any(
            keyword in config_content for keyword in 
            ["advanced_enabled", "entity_backend", "tom_pipeline_enabled", 
             "trust_increment", "consolidation_enabled"]
        )
        
        if is_custom:
            print("\nConfiguration Status:")
            print("  ✓ Custom configuration detected")
            
            # Try to extract some key settings
            if "advanced_enabled = True" in config_content:
                print("  ✓ Advanced features enabled")
            if "entity_backend = \"spacy\"" in config_content:
                print("  ✓ Using spaCy for entity extraction")
            if "tom_pipeline_enabled = True" in config_content:
                print("  ✓ ToM pipeline is enabled")
            if "consolidation_enabled = True" in config_content:
                print("  ✓ Background consolidation is enabled")
        else:
            print("\nConfiguration Status:")
            print("  ○ Using default configuration")
            print("  Tips:")
            print("    - Set advanced_enabled: true to enable advanced features")
            print("    - Configure entity_backend for better person extraction")
            print("    - Enable tom_pipeline_enabled for social reasoning")
    
    # Check Hermes config for social_tracking settings
    hermes_config = Path.home() / ".hermes" / "config.yaml"
    if hermes_config.exists():
        with open(hermes_config, 'r') as f:
            hermes_config_content = f.read()
        
        if "social_tracking:" in hermes_config_content:
            print("\nHermes Configuration:")
            # Extract social_tracking section
            in_section = False
            for line in hermes_config_content.split('\n'):
                if "social_tracking:" in line:
                    in_section = True
                    print(f"  {line.strip()}")
                elif in_section and line.strip() and not line.strip().startswith('#'):
                    if line.strip().startswith('-') or line.strip().startswith('}'):
                        in_section = False
                    else:
                        print(f"  {line.strip()}")
                elif in_section and line.strip().startswith('}'):
                    in_section = False
            
            print("  ✓ social_tracking section found in Hermes config")
        else:
            print("\nHermes Configuration:")
            print("  ○ social_tracking section not found in Hermes config")
            print("  Tips:")
            print("    - Add social_tracking configuration to enable the plugin")
            print("    - See README.md for configuration examples")
    
    return True

def main():
    print("Hermes Social Tracking Plugin - Configuration Report")
    print("=" * 60)
    
    success = generate_config_report()
    
    if success:
        print("\n" + "=" * 60)
        print("✓✓✓ Configuration report generated successfully! ✓✓✓")
        return 0
    else:
        print("\n" + "=" * 60)
        print("✗✗✗ Failed to generate configuration report ✗✗✗")
        return 1

if __name__ == "__main__":
    sys.exit(main())