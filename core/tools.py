"""Core social tracking tools for Hermes Agent."""

from __future__ import annotations
import json
from typing import Any, Dict, List, Optional

from .db import CoreDB


def social_set_primary_user(name: str) -> str:
    """Define the primary user for the social tracking system.
    
    Args:
        name: Name of the primary user
        
    Returns:
        Confirmation message
    """
    db = _get_db()
    db.set_primary_user_name(name)
    return f"Primary user set to: {name}"


def social_add_person(name: str, roles: Optional[List[str]] = None) -> str:
    """Add a new person to the social graph.
    
    Args:
        name: Person's name
        roles: Optional list of role labels (e.g., ['friend', 'coworker'])
        
    Returns:
        Confirmation message
    """
    db = _get_db()
    db.upsert_person(name, roles)
    return f"Person added: {name}"


def social_upsert_person(name: str, roles: Optional[List[str]] = None) -> str:
    """Upsert (update or insert) a person.
    
    Args:
        name: Person's name
        roles: Optional list of role labels
        
    Returns:
        Confirmation message
    """
    db = _get_db()
    db.upsert_person(name, roles)
    return f"Person upserted: {name}"


def social_record_event(
    summary: str, 
    kind: str = "chat_turn", 
    persons: Optional[List[str]] = None
) -> str:
    """Record a social event.
    
    Args:
        summary: Brief description of the event
        kind: Event type label (e.g., 'chat', 'meeting', 'conflict')
        persons: Optional list of person names to associate
        
    Returns:
        Confirmation message with event ID
    """
    db = _get_db()
    event_id = db.record_event(summary, kind, persons)
    return f"Event recorded: {event_id}"


def social_summarize_context(name: str) -> str:
    """Generate a social context summary for a person.
    
    Args:
        name: Person's name
        
    Returns:
        Formatted context string
    """
    db = _get_db()
    return db.summarize_context_for_person(name)


def social_get_person(name: str) -> Optional[Dict[str, Any]]:
    """Get person information.
    
    Args:
        name: Person's name
        
    Returns:
        Person dictionary or None if not found
    """
    db = _get_db()
    return db.get_person(name)


def social_adjust_trust(names: List[str], delta: float) -> str:
    """Adjust trust for one or more persons.
    
    Args:
        names: List of person names
        delta: Amount to adjust trust (can be positive or negative)
        
    Returns:
        Confirmation message
    """
    db = _get_db()
    # Get person IDs
    person_ids = []
    for name in names:
        person = db.get_person(name)
        if person:
            person_ids.append(person["person_id"])
    if person_ids:
        db.adjust_trust(person_ids, delta)
    return f"Trust adjusted for {len(names)} persons"


def social_add_commitment(
    from_person: str, 
    to_person: str, 
    description: str, 
    due_date: Optional[str] = None
) -> str:
    """Add a commitment.
    
    Args:
        from_person: Who made the commitment
        to_person: Who it was made to
        description: What was promised
        due_date: Optional ISO date string
        
    Returns:
        Confirmation message with commitment ID
    """
    db = _get_db()
    cid = db.add_commitment(from_person, to_person, description, due_date)
    return f"Commitment added: {cid}"


def social_update_commitment_status(commitment_id: int, status: str) -> str:
    """Update commitment status.
    
    Args:
        commitment_id: ID of the commitment
        status: New status ('pending', 'fulfilled', 'broken')
        
    Returns:
        Confirmation message
    """
    db = _get_db()
    try:
        result = db.update_commitment_status(commitment_id, status)
        return f"Commitment {commitment_id} marked {status}"
    except ValueError as e:
        return f"Error: {e}"


def social_get_open_commitments(name: str) -> List[Dict[str, Any]]:
    """Get open commitments for a person.
    
    Args:
        name: Person's name
        
    Returns:
        List of commitment dictionaries
    """
    db = _get_db()
    return db.get_open_commitments_for_person(name)


# Helper function to get database connection
def _get_db() -> CoreDB:
    """Get a database connection using the default path."""
    import os
    db_path = os.path.join(os.path.expanduser("~"), ".hermes", "social_tracking.db")
    return CoreDB(db_path)


__all__ = [
    "social_set_primary_user",
    "social_add_person",
    "social_upsert_person",
    "social_record_event",
    "social_summarize_context",
    "social_get_person",
    "social_adjust_trust",
    "social_add_commitment",
    "social_update_commitment_status",
    "social_get_open_commitments",
]
