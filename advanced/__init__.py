"""Advanced social tracking features - loaded conditionally."""

from __future__ import annotations
from typing import Dict, Any, Optional
import logging

# Import advanced modules
from .entity_extractor import extract_persons
from .trust_manager import TrustManager
from .commitment_tracker import CommitmentTracker
from .tompipeline import TheoryOfMindPipeline
from .consolidation import ConsolidationWorker


def register_advanced_tools() -> None:
    """Register advanced tools with Hermes."""
    # This would be called when the advanced module is enabled
    logging.info("Advanced social tracking modules registered")


def register_advanced_hooks() -> None:
    """Register advanced hooks with Hermes."""
    # This would be called when the advanced module is enabled
    logging.info("Advanced social tracking hooks registered")


__all__ = [
    "extract_persons",
    "TrustManager",
    "CommitmentTracker",
    "TheoryOfMindPipeline",
    "ConsolidationWorker",
    "register_advanced_tools",
    "register_advanced_hooks"
]
