#!/usr/bin/env python3
"""
Hermes Social Tracking Plugin - Migration Guide
This script generates a migration guide for upgrading.
"""

import sys
from pathlib import Path

def generate_migration_guide():
    """Generate a migration guide."""
    guide = f"""# Social Tracking Plugin Migration Guide

Generated: {datetime.now().isoformat()}
Current Version: 0.3.0

This guide helps you migrate between versions of the Social Tracking Plugin.

## Migrating to v0.3.0

### New Features
- **Enhanced Security**: Improved SQL injection protection
- **Better Performance**: Optimized database queries
- **New Reports**: Additional reporting capabilities
- **Improved Hooks**: Better integration with Hermes

### Breaking Changes
- **Database Schema**: Updated relationships table
- **Configuration**: Changed default values for trust settings

### Upgrade Procedure

1. **Backup Your Data**
   ```bash
   scripts/full_backup.sh
   ```

2. **Stop Hermes Agent**
   ```bash
   hermes stop
   ```

3. **Install New Version**
   ```bash
   # If using GitHub installation
   scripts/update_from_github.sh
   
   # Or manual installation
   scripts/uninstall.sh  # Remove old version
   scripts/install.sh     # Install new version
   ```

4. **Restore Configuration**
   - Review config.py changes
   - Update Hermes config.yaml if needed

5. **Start Hermes Agent**
   ```bash
   hermes start
   ```

6. **Verify Installation**
   ```bash
   scripts/validate_config.sh
   scripts/health_check.sh
   ```

### Rollback Procedure

If you encounter issues, you can roll back to the previous version:

1. **Restore from Backup**
   ```bash
   scripts/full_restore.sh /path/to/backup.tar.gz
   ```

2. **Restart Hermes**
   ```bash
   hermes restart
   ```

3. **Verify Rollback**
   ```bash
   scripts/validate_config.sh
   scripts/health_check.sh
   ```

## Migrating to v0.2.0

### New Features
- **Theory-of-Mind Pipeline**: Social reasoning capabilities
- **Advanced Entity Extraction**: spaCy integration
- **Dynamic Trust Management**: Automated trust adjustments

### Breaking Changes
- **Configuration Structure**: New config.py format
- **Database Schema**: Added relationships table

### Upgrade Notes
...

## Common Issues

### Database Errors After Upgrade
- Ensure you've restored from a backup
- Run database migrations if needed
- Check that all required tables exist

### Plugin Not Loading
- Verify plugin is in `~/.hermes/plugins/social-tracking/`
- Check Hermes logs for errors
- Ensure no syntax errors in config.py

### Missing Data
- Confirm backup was restored correctly
- Check if data was stored in old format
- Run data migration scripts if available

## Support

For additional help, please contact:
- [GitHub Issues](https://github.com/yourusername/hermes-social-tracking-plugin/issues)
- [Discord Community](https://discord.gg/yourdiscord)
- Email: support@example.com

---
**Note:** Always backup your data before upgrading.
"""
    return guide

def main():
    print("Generating migration guide...")
    guide = generate_migration_guide()
    print(guide)
    return 0

if __name__ == "__main__":
    sys.exit(main())