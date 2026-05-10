"""Entity extraction for social tracking."""

from __future__ import annotations
import re
from typing import List

def extract_persons(text: str) -> List[str]:
    """Extract person names from text using regex patterns.
    
    Args:
        text: Input text to analyze
        
    Returns:
        List of person names found in the text
    """
    # Simple pattern for common Western names
    # This is a basic implementation - in production, use spaCy or similar
    pattern = r'\b[A-Z][a-z]+(?:\s+[A-Z][a-z]+)*\b'
    names = re.findall(pattern, text)
    
    # Filter out common non-person words
    common_words = {"The", "And", "For", "With", "From", "This", "That"}
    names = [name for name in names if name not in common_words]
    
    return names
