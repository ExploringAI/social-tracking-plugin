"""Core hooks for the social tracking plugin."""

from __future__ import annotations
from typing import Any, Dict, List, Optional

from .tools import social_summarize_context, social_record_event
from .db import CoreDB


def pre_llm_call(prompt: str, context: Dict[str, Any]) -> str:
    """Hook to run before LLM call.
    
    Args:
        prompt: The prompt to be sent to the LLM
        context: Additional context including social information
        
    Returns:
        Modified prompt with social context injected
    """
    # Check if we should inject social context
    if context.get("inject_social_context", False):
        person_name = context.get("current_person")
        if person_name:
            social_summary = social_summarize_context(person_name)
            prompt = social_summary + "\n\n" + prompt
    return prompt


def post_llm_call(response: str, context: Dict[str, Any]) -> str:
    """Hook to run after LLM call.
    
    Args:
        response: The LLM's response
        context: Additional context
        
    Returns:
        Modified response (unchanged by default)
    """
    # Record the interaction in social memory
    db = _get_db()
    
    # Get conversation summary from context
    conversation_summary = context.get("conversation_summary", "General interaction")
    
    # Record the event
    db.record_event(
        summary=f"Interaction with AI: {conversation_summary}",
        kind="ai_interaction",
        persons=["Marko"]  # Assume primary user is Marko
    )
    
    return response


def social_tracking_hook(hook_type: str, **kwargs) -> Optional[str]:
    """Main hook entry point for social tracking.
    
    Args:
        hook_type: Type of hook ('pre_llm' or 'post_llm')
        **kwargs: Additional arguments passed to the hook
        
    Returns:
        Modified prompt/response or None
    """
    if hook_type == "pre_llm":
        return pre_llm_call(kwargs.get("prompt", ""), kwargs.get("context", {}))
    elif hook_type == "post_llm":
        return post_llm_call(kwargs.get("response", ""), kwargs.get("context", {}))
    return None


def _get_db() -> CoreDB:
    """Get database connection."""
    import os
    db_path = os.path.join(os.path.expanduser("~"), ".hermes", "social_tracking.db")
    return CoreDB(db_path)
