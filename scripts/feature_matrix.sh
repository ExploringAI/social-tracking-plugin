#!/usr/bin/env python3
"""
Hermes Social Tracking Plugin - Feature Matrix Generator
This script generates a feature matrix showing which features are enabled.
"""

import sys
import yaml
from pathlib import Path

def generate_feature_matrix():
    """Generate a feature matrix."""
    plugin_dir = Path.home() / ".hermes" / "plugins" / "social-tracking"
    config_file = plugin_dir / "config.py"
    plugin_yaml = plugin_dir / "plugin.yaml"
    hermes_config = Path.home() / ".hermes" / "config.yaml"
    
    print("Social Tracking Plugin Feature Matrix")
    print("=" * 60)
    
    # Get plugin information
    with open(plugin_yaml, 'r') as f:
        plugin_config = yaml.safe_load(f)
    
    print(f"\nPlugin: {plugin_config.get('name', 'Unknown')}")
    print(f"Version: {plugin_config.get('version', 'Unknown')}")
    print(f"Description: {plugin_config.get('description', 'Unknown')}")
    
    # Check which features are enabled
    print("\nFeature Status:")
    print("-" * 60)
    
    # Check if plugin is configured in Hermes
    hermes_configured = False
    if hermes_config.exists():
        with open(hermes_config, 'r') as f:
            hermes_config_content = f.read()
        hermes_configured = "social_tracking:" in hermes_config_content
    
    print(f"✓ Plugin Configured in Hermes: {hermes_configured}")
    
    # Check config.py
    if config_file.exists():
        with open(config_file, 'r') as f:
            config_content = f.read()
        
        print(f"\nConfiguration File: {config_file.name}")
        print("-" * 60)
        
        # Core features
        print("Core Features (always enabled):")
        print("  ✓ Lightweight SQLite social graph")
        print("  ✓ 15+ specialized tools")
        print("  ✓ Seamless hooks integration")
        print("  ✓ Auto-person-discovery")
        print("  ✓ Passive awareness")
        
        # Advanced features
        print("\nAdvanced Features (configurable):")
        
        if "advanced_enabled = True" in config_content:
            print("  ✓ Advanced Features Enabled")
            
            if "entity_backend = \"spacy\"" in config_content:
                print("    ✓ Using spaCy for entity extraction")
            else:
                print("    ○ Using regex for entity extraction (default)")
            
            if "tom_pipeline_enabled = True" in config_content:
                print("    ✓ ToM pipeline enabled")
            else:
                print("    ○ ToM pipeline disabled (default)")
            
            if "consolidation_enabled = True" in config_content:
                print("    ✓ Background consolidation enabled")
            else:
                print("    ○ Background consolidation disabled (default)")
            
            # Extract other settings
            import re
            pattern = r"(trust_increment|trust_decrement|trust_clamp_min|trust_clamp_max|consolidation_interval_s)\s*=\s*([\d.]+)"
            matches = re.findall(pattern, config_content)
            for key, value in matches:
                print(f"    {key}: {value}")
        else:
            print("  ○ Advanced Features Disabled (default)")
            print("    ○ Entity extraction: regex")
            print("    ○ ToM pipeline: disabled")
            print("    ○ Background consolidation: disabled")
            print("    ○ Trust increment: 0.10")
            print("    ○ Trust decrement: 0.20")
            print("    ○ Consolidation interval: 300s")
    else:
        print(f"✗ Configuration file not found: {config_file}")
    
    # Check tools
    print(f"\nTools Provided ({len(plugin_config.get('provides_tools', []))}):")
    print("-" * 60)
    for tool in plugin_config.get('provides_tools', []):
        print(f"  ✓ {tool}")
    
    # Check hooks
    print(f"\nHooks Provided ({len(plugin_config.get('provides_hooks', []))}):")
    print("-" * 60)
    for hook in plugin_config.get('provides_hooks', []):
        print(f"  ✓ {hook}")
    
    return True

def main():
    success = generate_feature_matrix()
    return 0 if success else 1

if __name__ == "__main__":
    sys.exit(main())