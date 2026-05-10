"""Entity extraction stub for social_tracking v2."""
import re
from typing import List

# Common English stop-words that look like names
_NON_PERSON_WORDS = {
    "The", "And", "For", "With", "From", "This", "That", "What",
    "When", "Where", "Which", "Would", "Could", "Should", "There",
    "Their", "They", "Then", "Than", "Just", "Like", "Some", "Any",
    "But", "Not", "Are", "Was", "Were", "Been", "Being", "Have",
    "Has", "Had", "Does", "Did", "Will", "Can", "May", "Might",
    "Must", "Shall", "About", "Above", "After", "Again", "Also",
    "Always", "Because", "Before", "Between", "Both", "Each", "Even",
    "Every", "First", "Here", "How", "Into", "Its", "Last", "More",
    "Most", "Much", "Never", "Next", "Now", "Only", "Other", "Our",
    "Over", "Same", "Since", "Still", "Such", "Take", "These",
    "Those", "Through", "Under", "Until", "Very", "Well", "While",
    "Your", "Yeah", "Yes", "Okay", "Hey", "Hi", "Hello", "Please",
    "Thanks", "Thank", "Sorry", "Great",
}


def extract_persons(text: str, backend: str = "regex", spacy_model: str = "") -> List[str]:
    """Extract person names from text.

    In v2, this uses a smarter regex + known-person lookup.
    Falls back to simple capitalization pattern.
    """
    if not text or not isinstance(text, str):
        return []

    # Try known names from the DB first if available
    try:
        from .db import SocialDB
        db = SocialDB._instance
        known = set()
        try:
            conn = db._connect()
            cur = conn.cursor()
            cur.execute("SELECT name FROM persons")
            known = {r[0] for r in cur.fetchall()}
            db._close(conn)
        except Exception:
            pass

        # Find known names in text (case insensitive)
        found = []
        text_lower = text.lower()
        for name in known:
            if name.lower() in text_lower:
                found.append(name)
        if found:
            return found
    except Exception:
        pass

    # Fallback: regex for capitalized words (2+ letter sequences)
    pattern = r'\b[A-Z][a-z]{1,}(?:\s+[A-Z][a-z]{1,})*\b'
    names = re.findall(pattern, text)

    # Filter non-person words
    names = [n for n in names if n not in _NON_PERSON_WORDS]

    # Deduplicate preserving order
    seen = set()
    result = []
    for n in names:
        if n.lower() not in seen:
            seen.add(n.lower())
            result.append(n)

    return result
