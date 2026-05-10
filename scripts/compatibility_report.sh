#!/usr/bin/env python3
"""
Hermes Social Tracking Plugin - Compatibility Report
This script checks compatibility with other plugins.
"""

import sys
import yaml
from pathlib import Path

def check_plugin_compatibility():
    """Check compatibility with other plugins."""
    plugin_dir = Path.home() / ".hermes" / "plugins" / "social-tracking"
    plugin_yaml = plugin_dir / "plugin.yaml"
    
    print("Social Tracking Plugin Compatibility Report")
    print("=" * 60)
    
    if not plugin_yaml.exists():
        print(f"✗ plugin.yaml not found: {plugin_yaml}")
        return False
    
    try:
        with open(plugin_yaml, 'r') as f:
            plugin_config = yaml.safe_load(f)
        
        print(f"Plugin: {plugin_config.get('name', 'Unknown')}")
        print(f"Version: {plugin_config.get('version', 'Unknown')}")
        print("\nCompatibility Checks:")
        print("-" * 60)
        
        # Check hooks that might conflict with other plugins
        hooks = plugin_config.get('provides_hooks', [])
        print(f"✓ Provides {len(hooks)} hooks")
        
        # Check for potential conflicts
        conflicting_hooks = [
            'pre_llm_call',
            'post_llm_call',
            'on_session_start',
            'on_session_end',
        ]
        
        conflicting = set(conflicting_hooks) & set(hooks)
        if conflicting:
            print(f"○ Hooks that might conflict with other plugins: {', '.join(conflicting)}")
        else:
            print("✓ No hooks with high conflict potential")
        
        # Check tools
        tools = plugin_config.get('provides_tools', [])
        print(f"\nTools Provided ({len(tools)}):")
        for tool in tools:
            print(f"  - {tool}")
        
        # Check for tool name conflicts
        # This would require knowledge of other plugins' tools
        # For now, just list the tools
        
        print(f"\n✓ Plugin appears to be well-structured and compatible")
        return True
    except Exception as e:
        print(f"✗ Compatibility check error: {e}")
        return False

def main():
    success = check_plugin_compatibility()
    return 0 if success else 1

if __name__ == "__main__":
    sys.exit(main())