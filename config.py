"""Configuration defaults for social tracking plugin.

These can be overridden in the Hermes config.yaml or environment variables.
"""

from __future__ import annotations
from pydantic import BaseModel, Field
from typing import Optional


class SocialTrackingConfig(BaseModel):
    """Main configuration for social tracking plugin."""

    db_path: Optional[str] = "~/.hermes/data/social_tracking.db"
    advanced_enabled: bool = False

    # Advanced settings (only used if advanced_enabled=True)
    entity_backend: str = "regex"
    tom_pipeline_enabled: bool = False
    consolidation_enabled: bool = False
    trust_increment: float = 0.10
    trust_decrement: float = 0.20
    trust_clamp_min: float = -1.0
    trust_clamp_max: float = 1.0
    tom_model: Optional[str] = None
    domain_norms: Optional[str] = None
    spacy_model: str = "en_core_web_sm"
    top_k_recall: int = 10
    consolidation_interval_s: int = 300
