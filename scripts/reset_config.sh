#!/usr/bin/env python3
"""
Hermes Social Tracking Plugin - Reset Configuration Script
This script resets the plugin configuration to defaults.
"""

import sys
import shutil
from pathlib import Path

def reset_to_defaults():
    """Reset plugin configuration to defaults."""
    plugin_dir = Path.home() / ".hermes" / "plugins" / "social-tracking"
    default_config = plugin_dir / "config.py"
    
    if default_config.exists():
        # Create a backup of current config
        backup_path = plugin_dir / "config_backup.py"
        shutil.copy2(default_config, backup_path)
        print(f"✓ Current config backed up to: {backup_path}")
        
        # Reset to default config
        default_config_content = """\"\"\"Configuration defaults for social tracking plugin.

These can be overridden in the Hermes config.yaml or environment variables.
\"\"\"

from __future__ import annotations
from pydantic import BaseModel, Field
from typing import Optional

class SocialTrackingConfig(BaseModel):
    \"\"\"Main configuration for social tracking plugin.\"\"\"

    db_path: Optional[str] = "~/.hermes/data/social_tracking.db"
    advanced_enabled: bool = False

    # Advanced settings (only used if advanced_enabled=True)
    entity_backend: str = "regex"
    tom_pipeline_enabled: bool = False
    consolidation_enabled: bool = False
    trust_increment: float = 0.10
    trust_decrement: float = 0.20
    trust_clamp_min: float = -1.0
    trust_clamp_max: float = 1.0
    tom_model: Optional[str] = None
    domain_norms: Optional[str] = None
    spacy_model: str = "en_core_web_sm"
    top_k_recall: int = 10
    consolidation_interval_s: int = 300
"""
        with open(default_config, 'w') as f:
            f.write(default_config_content)
        
        print("✓ Configuration reset to defaults")
        return True
    else:
        print("✗ config.py not found in plugin directory")
        return False

def main():
    print("Hermes Social Tracking Plugin - Reset Configuration")
    print("=" * 50)
    
    response = input("Are you sure you want to reset the plugin configuration to defaults? (y/n): ")
    if response.lower() == 'y':
        success = reset_to_defaults()
        if success:
            print("\n✓✓✓ Configuration reset successfully! ✓✓✓")
            print("\nNext steps:")
            print("1. Review the default configuration")
            print("2. Update your Hermes config.yaml if needed")
            print("3. Restart Hermes agent")
            return 0
        else:
            print("\n✗✗✗ Reset failed ✗✗✗")
            return 1
    else:
        print("Reset cancelled.")
        return 0

if __name__ == "__main__":
    sys.exit(main())