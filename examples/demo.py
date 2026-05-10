#!/usr/bin/env python3
"""
Example usage of the social_tracking plugin.
This script demonstrates how to interact with the plugin programmatically.
"""

from social_tracking.db import SocialDB
from social_tracking.entity import extract_persons
from social_tracking.trust import TrustManager

def example_basic_operations():
    """Basic operations: create persons, record events, track commitments."""
    # Initialize database
    db = SocialDB("social_tracking.db")
    db.connect()
    db.init_db()
    
    print("=== Basic Operations ===")
    
    # Add a person
    marko_id = db.upsert_person("Marko", roles=["developer", "user"])
    print(f"Added Marko with ID: {marko_id}")
    
    # Add another person
    alice_id = db.upsert_person("Alice", roles=["friend", "coworker"])
    print(f"Added Alice with ID: {alice_id}")
    
    # Record an event
    event_id = db.record_event(
        summary="Had lunch with Alice to discuss project",
        kind="meeting",
        persons=["Marko", "Alice"]
    )
    print(f"Recorded event: {event_id}")
    
    # Add a commitment
    commitment_id = db.add_commitment(
        from_person="Alice",
        to_person="Marko",
        description="Will send design files by Friday",
        due_date="2024-12-20"
    )
    print(f"Added commitment: {commitment_id}")
    
    db._close(db._connect(), commit=True)
    print("Database operations completed!")

def example_trust_management():
    """Example of trust management operations."""
    # Initialize database and trust manager
    db = SocialDB("social_tracking.db")
    trust_mgr = TrustManager(db, increment=0.1, decrement=0.2)
    
    print("\n=== Trust Management ===")
    
    # Get trust score
    trust = trust_mgr.get_trust("Alice")
    print(f"Alice's trust score: {trust}")
    
    # Get trust summary
    summary = trust_mgr.trust_summary("Alice")
    print(f"Trust summary: {summary}")
    
    # Adjust trust
    db.adjust_trust([db.upsert_person("Bob")], 0.3)
    print("Trust adjusted for Bob")
    
    db._close(db._connect(), commit=True)

def example_entity_extraction():
    """Example of entity extraction from text."""
    text = "Marko and Alice had a meeting with Bob to discuss the project. John was also there."
    
    print("\n=== Entity Extraction ===")
    print(f"Input text: {text}")
    
    persons = extract_persons(text)
    print(f"Detected persons: {persons}")

if __name__ == "__main__":
    print("Hermes Social Tracking Plugin - Example Usage\n")
    example_basic_operations()
    example_trust_management()
    example_entity_extraction()
    print("\nAll examples completed successfully!")