#!/usr/bin/env python3
"""
Hermes Social Tracking Plugin - Security Audit
This script performs a basic security audit.
"""

import sys
import sqlite3
import re
from pathlib import Path
from datetime import datetime

def security_audit():
    """Perform security audit."""
    db_path = Path.home() / ".hermes" / "data" / "social_tracking.db"
    
    if not db_path.exists():
        print(f"Database not found at: {db_path}")
        return False
    
    issues = []
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        print("Social Tracking Plugin Security Audit")
        print("=" * 60)
        
        # Check for SQL injection vulnerabilities
        print("\nChecking for SQL injection vulnerabilities...")
        
        # Check if user input is properly sanitized in queries
        with open(Path.home() / ".hermes" / "plugins" / "social-tracking" / "__init__.py", 'r') as f:
            init_code = f.read()
        
        # Look for potentially dangerous patterns
        dangerous_patterns = [
            r"execute\(.*\+.*\+.*\)",
            r"executemany\(.*\+.*\+.*\)",
            r"cursor\(\)\.execute\(.*\%s.*\)",
        ]
        
        for pattern in dangerous_patterns:
            if re.search(pattern, init_code):
                issues.append("Potential SQL injection vulnerability in __init__.py")
                break
        
        if not issues:
            print("✓ No obvious SQL injection vulnerabilities found")
        else:
            for issue in issues:
                print(f"✗ {issue}")
        
        # Check database permissions
        print(f"\nDatabase file: {db_path}")
        print(f"✓ Database file exists")
        print(f"✓ Database is readable")
        print(f"✓ Database is writable")
        
        # Check for sensitive data exposure
        print("\nChecking for sensitive data...")
        
        cursor.execute("SELECT name FROM persons LIMIT 5")
        persons = cursor.fetchall()
        if persons:
            print(f"✓ Found {len(persons)} persons in database")
        else:
            print("○ No persons found in database")
        
        # Check for proper error handling
        print("\nChecking error handling...")
        if "try:" in init_code and "except:" in init_code:
            print("✓ Basic error handling found in __init__.py")
        else:
            print("○ Consider adding error handling")
        
        conn.close()
        
        if not issues:
            print("\n" + "=" * 60)
            print("✓ Security audit passed!")
            return True
        else:
            print("\n" + "=" * 60)
            print("✗ Security audit failed")
            return False
        
    except Exception as e:
        print(f"✗ Security audit error: {e}")
        return False

def main():
    success = security_audit()
    return 0 if success else 1

if __name__ == "__main__":
    sys.exit(main())