#!/usr/bin/env python3
"""
Hermes Social Tracking Plugin - Health Check Script
This script checks the plugin's health and status.
"""

import sys
import sqlite3
from pathlib import Path
from datetime import datetime, timedelta

def check_database():
    """Check if the database is accessible and recent."""
    db_path = Path.home() / ".hermes" / "data" / "social_tracking.db"
    
    if not db_path.exists():
        print("✗ Database not found")
        return False
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Check when database was last modified
        mod_time = db_path.stat().st_mtime
        time_since_mod = datetime.now() - datetime.fromtimestamp(mod_time)
        
        if time_since_mod < timedelta(hours=1):
            print("✓ Database is recent (modified within last hour)")
        else:
            print(f"○ Database last modified: {time_since_mod}")
        
        # Check if tables exist
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
        tables = cursor.fetchall()
        expected_tables = {'persons', 'events', 'commitments', 'meta', 'relationships', 'person_events', 'commitment_parties'}
        found_tables = {t[0] for t in tables}
        
        missing_tables = expected_tables - found_tables
        if missing_tables:
            print(f"✗ Missing tables: {missing_tables}")
            return False
        else:
            print("✓ All expected tables exist")
        
        conn.close()
        return True
    except Exception as e:
        print(f"✗ Database error: {e}")
        return False

def check_tools():
    """Check if tools are available."""
    print("\n=== Tools Check ===")
    # This would need to interact with Hermes to check actual tool availability
    # For now, we'll just check that plugin.yaml exists and has tools
    plugin_yaml = Path.home() / ".hermes" / "plugins" / "social-tracking" / "plugin.yaml"
    
    if plugin_yaml.exists():
        import yaml
        with open(plugin_yaml, 'r') as f:
            config = yaml.safe_load(f)
        
        tools = config.get('provides_tools', [])
        hooks = config.get('provides_hooks', [])
        
        if tools:
            print(f"✓ Plugin provides {len(tools)} tools")
            for tool in tools:
                print(f"  - {tool}")
        else:
            print("○ No tools defined in plugin.yaml")
        
        if hooks:
            print(f"✓ Plugin provides {len(hooks)} hooks")
        else:
            print("○ No hooks defined in plugin.yaml")
        
        return True
    else:
        print("✗ plugin.yaml not found")
        return False

def check_consistency():
    """Check basic data consistency."""
    print("\n=== Data Consistency Check ===")
    db_path = Path.home() / ".hermes" / "data" / "social_tracking.db"
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Check for primary user
        cursor.execute("SELECT value FROM meta WHERE key = 'primary_user_name'")
        primary_user = cursor.fetchone()
        if primary_user:
            print(f"✓ Primary user set: {primary_user[0]}")
        else:
            print("○ No primary user set")
        
        # Check for persons
        cursor.execute("SELECT COUNT(*) FROM persons")
        person_count = cursor.fetchone()[0]
        print(f"✓ {person_count} persons in database")
        
        # Check for events
        cursor.execute("SELECT COUNT(*) FROM events")
        event_count = cursor.fetchone()[0]
        print(f"✓ {event_count} events in database")
        
        # Check for commitments
        cursor.execute("SELECT COUNT(*) FROM commitments")
        commitment_count = cursor.fetchone()[0]
        print(f"✓ {commitment_count} commitments in database")
        
        conn.close()
        return True
    except Exception as e:
        print(f"✗ Consistency check error: {e}")
        return False

def main():
    print("Hermes Social Tracking Plugin - Health Check")
    print("=" * 50)
    
    checks = [
        check_database,
        check_tools,
        check_consistency,
    ]
    
    results = [check() for check in checks]
    
    print("\n" + "=" * 50)
    if all(results):
        print("✓✓✓ Health Check Passed! ✓✓✓")
        return 0
    else:
        print("✗✗✗ Health Check Failed ✗✗✗")
        return 1

if __name__ == "__main__":
    sys.exit(main())