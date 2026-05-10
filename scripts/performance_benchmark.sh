#!/usr/bin/env python3
"""
Hermes Social Tracking Plugin - Performance Benchmark
This script runs performance benchmarks.
"""

import sys
import time
import sqlite3
from pathlib import Path
from datetime import datetime

def run_benchmark():
    """Run performance benchmarks."""
    db_path = Path.home() / ".hermes" / "data" / "social_tracking.db"
    
    if not db_path.exists():
        print(f"Database not found at: {db_path}")
        return False
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        print("Social Tracking Plugin Performance Benchmark")
        print("=" * 60)
        print("\nBenchmarking core operations...")
        print("-" * 60)
        
        results = []
        
        # Benchmark person operations
        start = time.time()
        cursor.execute("SELECT COUNT(*) FROM persons")
        person_count = cursor.fetchone()[0]
        elapsed = time.time() - start
        results.append(("Count persons", elapsed, person_count))
        print(f"✓ Count persons: {elapsed:.4f}s (found {person_count} persons)")
        
        # Benchmark event operations
        start = time.time()
        cursor.execute("SELECT COUNT(*) FROM events")
        event_count = cursor.fetchone()[0]
        elapsed = time.time() - start
        results.append(("Count events", elapsed, event_count))
        print(f"✓ Count events: {elapsed:.4f}s (found {event_count} events)")
        
        # Benchmark commitment operations
        start = time.time()
        cursor.execute("SELECT COUNT(*) FROM commitments")
        commitment_count = cursor.fetchone()[0]
        elapsed = time.time() - start
        results.append(("Count commitments", elapsed, commitment_count))
        print(f"✓ Count commitments: {elapsed:.4f}s (found {commitment_count} commitments)")
        
        # Benchmark trust score update (on a sample)
        start = time.time()
        cursor.execute("SELECT person_id FROM persons WHERE name = 'Marko' LIMIT 1")
        row = cursor.fetchone()
        if row:
            person_id = row[0]
            cursor.execute("UPDATE persons SET trust_score = trust_score + 0.1 WHERE person_id = ?", (person_id,))
            conn.commit()
            cursor.execute("UPDATE persons SET trust_score = trust_score - 0.1 WHERE person_id = ?", (person_id,))
            conn.commit()
        elapsed = time.time() - start
        results.append(("Trust score update", elapsed, 1 if row else 0))
        print(f"✓ Trust score update: {elapsed:.4f}s")
        
        conn.close()
        
        # Summary
        print("\n" + "=" * 60)
        print("Benchmark Summary:")
        print("-" * 60)
        for operation, elapsed, count in results:
            print(f"{operation}: {elapsed:.4f}s")
            if count > 0:
                print(f"  Throughput: {count/elapsed:.2f} ops/sec")
        
        # Overall grade
        total_time = sum(elapsed for _, elapsed, _ in results)
        print(f"\nTotal benchmark time: {total_time:.4f}s")
        
        if total_time < 1.0:
            grade = "A"
        elif total_time < 2.0:
            grade = "B"
        elif total_time < 5.0:
            grade = "C"
        else:
            grade = "D"
        
        print(f"Performance Grade: {grade}")
        
        return True
    except Exception as e:
        print(f"✗ Benchmark error: {e}")
        return False

def main():
    success = run_benchmark()
    return 0 if success else 1

if __name__ == "__main__":
    sys.exit(main())