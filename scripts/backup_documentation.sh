#!/usr/bin/env python3
"""
Hermes Social Tracking Plugin - Backup & Restore Documentation
This script generates backup and restore procedure documentation.
"""

import sys
from pathlib import Path
from datetime import datetime

def generate_backup_documentation():
    """Generate backup and restore documentation."""
    documentation = f"""# Social Tracking Plugin: Backup and Restore Procedures

Generated: {datetime.now().isoformat()}
Plugin Version: 0.3.0

## Overview

This document describes the procedures for backing up and restoring the Social Tracking Plugin for Hermes.

## Data Backed Up

The backup includes:
- Database: `~/.hermes/data/social_tracking.db`
- Configuration: `~/.hermes/plugins/social-tracking/config.py`
- Plugin metadata: `~/.hermes/plugins/social-tracking/plugin.yaml`

## Backup Procedures

### Full Backup

To create a full backup of the plugin:

```bash
scripts/full_backup.sh
```

This creates a compressed archive with all plugin data and configuration.

### Database Export

To export the database to a SQL file:

```bash
scripts/export_database.sh
```

### Individual File Backup

To backup specific files:

```bash
cp -r ~/.hermes/plugins/social-tracking /path/to/backup/location
cp ~/.hermes/data/social_tracking.db /path/to/backup/location
```

## Restore Procedures

### Full Restore

To restore from a full backup:

```bash
scripts/full_restore.sh /path/to/backup.tar.gz
```

### Database Import

To restore the database from an export:

```bash
scripts/import_database.sh /path/to/export.sql
```

### Individual File Restore

To restore specific files:

```bash
cp -r /path/to/backup/social-tracking ~/.hermes/plugins/
cp /path/to/backup/social_tracking.db ~/.hermes/data/
```

## Automation

### Cron Jobs

To automate backups, set up a cron job:

```bash
# Edit crontab
crontab -e

# Add line for daily backup at 2 AM
0 2 * * * /path/to/social_tracking/scripts/full_backup.sh
```

### Scheduled Backups

Use the Hermes scheduler to run regular backups:

```bash
hermes cronjob create --name="social_backup" --schedule="0 2 * * *" --script="scripts/full_backup.sh" --deliver="local"
```

## Best Practices

1. **Regular Backups**: Schedule daily backups
2. **Offsite Storage**: Keep backups in a separate location
3. **Test Restores**: Periodically test restoring from backups
4. **Multiple Copies**: Maintain at least 2 backup copies
5. **Monitor Backups**: Check backup logs regularly

## Recovery

If you need to recover from data loss:

1. Restore the most recent backup
2. Verify the plugin is working correctly
3. Check logs for any errors
4. Test core functionality
5. Notify users if necessary

## Troubleshooting

### Backup Fails
- Check disk space
- Verify file permissions
- Ensure database is not locked

### Restore Fails
- Check that the backup file is not corrupted
- Verify file permissions
- Ensure Hermes is not running during restore

## Support

For additional help, please consult the:
- [GitHub Issues](https://github.com/yourusername/hermes-social-tracking-plugin/issues)
- [Discord Community](https://discord.gg/yourdiscord)
- [Documentation](https://yourusername.github.io/hermes-social-tracking-plugin/)

---
**Note:** Always test backup and restore procedures in a non-production environment first.
"""
    return documentation

def main():
    print("Generating backup and restore documentation...")
    documentation = generate_backup_documentation()
    print(documentation)
    return 0

if __name__ == "__main__":
    sys.exit(main())