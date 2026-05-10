#!/usr/bin/env python3
"""
Hermes Social Tracking Plugin - Configuration Validator
This script validates the plugin configuration.
"""

import sys
import yaml
import re
from pathlib import Path

def validate_config():
    """Validate plugin configuration."""
    plugin_dir = Path.home() / ".hermes" / "plugins" / "social-tracking"
    config_file = plugin_dir / "config.py"
    plugin_yaml = plugin_dir / "plugin.yaml"
    
    issues = []
    
    print("Validating Social Tracking Plugin Configuration...")
    print("=" * 60)
    
    # Check if plugin directory exists
    if not plugin_dir.exists():
        print("✗ Plugin directory not found")
        return False
    
    # Check required files
    required_files = ["__init__.py", "config.py", "db.py", "plugin.yaml"]
    for file in required_files:
        if not (plugin_dir / file).exists():
            issues.append(f"Missing required file: {file}")
    
    if issues:
        for issue in issues:
            print(f"✗ {issue}")
        return False
    
    # Check plugin.yaml structure
    try:
        with open(plugin_yaml, 'r') as f:
            plugin_config = yaml.safe_load(f)
        
        required_keys = ['name', 'version', 'description', 'provides_tools', 'provides_hooks']
        for key in required_keys:
            if key not in plugin_config:
                issues.append(f"plugin.yaml missing required key: {key}")
        
        if 'provides_tools' not in plugin_config or not isinstance(plugin_config['provides_tools'], list):
            issues.append("provides_tools should be a list")
        
        if 'provides_hooks' not in plugin_config or not isinstance(plugin_config['provides_hooks'], list):
            issues.append("provides_hooks should be a list")
        
    except Exception as e:
        issues.append(f"Error parsing plugin.yaml: {str(e)}")
    
    # Check config.py for basic structure
    if config_file.exists():
        with open(config_file, 'r') as f:
            config_content = f.read()
        
        if "SocialTrackingConfig" not in config_content:
            issues.append("config.py missing SocialTrackingConfig class")
        
        # Check for required fields
        required_fields = [
            "db_path",
            "advanced_enabled",
            "entity_backend",
            "tom_pipeline_enabled",
            "consolidation_enabled",
            "trust_increment",
            "trust_decrement",
            "trust_clamp_min",
            "trust_clamp_max",
            "spacy_model",
            "top_k_recall",
            "consolidation_interval_s"
        ]
        
        for field in required_fields:
            if field not in config_content:
                issues.append(f"config.py missing field: {field}")
    
    # Check if plugin is properly installed in Hermes
    hermes_config = Path.home() / ".hermes" / "config.yaml"
    if hermes_config.exists():
        with open(hermes_config, 'r') as f:
            hermes_config_content = f.read()
        
        if "social_tracking:" not in hermes_config_content:
            issues.append("social_tracking section not found in Hermes config.yaml")
    else:
        issues.append("Hermes config.yaml not found")
    
    # Print validation results
    if issues:
        print("\nValidation Issues Found:")
        print("-" * 60)
        for issue in issues:
            print(f"✗ {issue}")
        print("\n" + "=" * 60)
        print("✗ Configuration Validation Failed")
        return False
    else:
        print("✓ All configuration checks passed!")
        print("=" * 60)
        return True

def main():
    success = validate_config()
    return 0 if success else 1

if __name__ == "__main__":
    sys.exit(main())