#!/usr/bin/env python3
"""
Hermes Social Tracking Plugin - Social Graph Visualization
This script generates a text-based visualization of the social graph.
"""

import sys
import sqlite3
from pathlib import Path
from datetime import datetime, timedelta

def generate_social_graph():
    """Generate a text-based social graph visualization."""
    db_path = Path.home() / ".hermes" / "data" / "social_tracking.db"
    
    if not db_path.exists():
        print(f"Database not found at: {db_path}")
        return False
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        print("\n" + "=" * 80)
        print("Social Tracking Social Graph Visualization")
        print("=" * 80)
        
        # Get all persons
        cursor.execute("SELECT person_id, name, roles, trust_score, kind FROM persons ORDER BY trust_score DESC")
        persons = cursor.fetchall()
        
        # Create a mapping from person ID to index
        person_ids = {}
        for idx, (person_id, name, roles, trust_score, kind) in enumerate(persons):
            person_ids[person_id] = idx
        
        # Create adjacency matrix for relationships
        n = len(persons)
        if n == 0:
            print("No persons found in database")
            return False
        
        # Initialize adjacency matrix
        relationships = [[0.0] * n for _ in range(n)]
        
        # Get relationships
        cursor.execute("""
            SELECT ra.person_id, rb.person_id, r.strength, r.rel_type, r.status
            FROM relationships r
            JOIN persons ra ON r.person_a_id = ra.person_id
            JOIN persons rb ON r.person_b_id = rb.person_id
            WHERE r.status = 'active'
        """)
        
        for person_a_id, person_b_id, strength, rel_type, status in cursor.fetchall():
            i = person_ids[person_a_id]
            j = person_ids[person_b_id]
            relationships[i][j] = strength
            relationships[j][i] = strength  # Undirected graph
        
        # Print persons
        print(f"\nPersons ({len(persons)}):")
        print("-" * 80)
        for idx, (person_id, name, roles, trust_score, kind) in enumerate(persons):
            print(f"{idx:3d}. {name:<20} Trust: {trust_score:>5.3f} Roles: {roles or 'None'}")
        
        # Print relationships summary
        print(f"\nRelationships ({len([r for row in relationships for r in row if r > 0]) // 2} active):")
        print("-" * 80)
        
        for i in range(n):
            for j in range(i + 1, n):
                if relationships[i][j] > 0:
                    name_i = persons[i][1]
                    name_j = persons[j][1]
                    strength = relationships[i][j]
                    print(f"{name_i} ↔ {name_j}: Strength {strength:.3f}")
        
        # Print graph statistics
        print(f"\nGraph Statistics:")
        print(f"  Nodes (Persons): {n}")
        print(f"  Edges (Relationships): {sum(1 for row in relationships for r in row if r > 0) // 2}")
        print(f"  Density: {sum(1 for row in relationships for r in row if r > 0) / (n * (n - 1)):.3f}")
        
        # Print trust distribution
        print(f"\nTrust Distribution:")
        cursor.execute("SELECT COUNT(*) FROM persons WHERE trust_score >= 0.8")
        high_trust = cursor.fetchone()[0]
        print(f"  High Trust (≥0.8): {high_trust} persons")
        
        cursor.execute("SELECT COUNT(*) FROM persons WHERE trust_score >= 0.6 AND trust_score < 0.8")
        moderate_trust = cursor.fetchone()[0]
        print(f"  Moderate Trust (0.6-0.8): {moderate_trust} persons")
        
        cursor.execute("SELECT COUNT(*) FROM persons WHERE trust_score >= 0.4 AND trust_score < 0.6")
        neutral_trust = cursor.fetchone()[0]
        print(f"  Neutral Trust (0.4-0.6): {neutral_trust} persons")
        
        cursor.execute("SELECT COUNT(*) FROM persons WHERE trust_score >= 0.2 AND trust_score < 0.4")
        low_trust = cursor.fetchone()[0]
        print(f"  Low Trust (0.2-0.4): {low_trust} persons")
        
        cursor.execute("SELECT COUNT(*) FROM persons WHERE trust_score < 0.2")
        very_low_trust = cursor.fetchone()[0]
        print(f"  Very Low Trust (<0.2): {very_low_trust} persons")
        
        conn.close()
        return True
    except Exception as e:
        print(f"✗ Error generating social graph: {e}")
        return False

def main():
    print("Hermes Social Tracking Plugin - Social Graph Visualization")
    print("=" * 80)
    
    success = generate_social_graph()
    
    if success:
        print("\n" + "=" * 80)
        print("✓✓✓ Social graph visualization generated successfully! ✓✓✓")
        return 0
    else:
        print("\n" + "=" * 80)
        print("✗✗✗ Failed to generate social graph ✗✗✗")
        return 1

if __name__ == "__main__":
    sys.exit(main())