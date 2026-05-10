"""Test configuration and basic imports."""
import pytest
from social_tracking.config import SocialTrackingConfig

def test_config_parsing():
    """Test that config can be parsed correctly."""
    config = SocialTrackingConfig(
        db_path="~/.hermes/data/social_tracking.db",
        advanced_enabled=True,
        entity_backend="regex",
        trust_increment=0.1
    )
    
    assert config.db_path == "~/.hermes/data/social_tracking.db"
    assert config.advanced_enabled is True
    assert config.entity_backend == "regex"
    assert config.trust_increment == 0.1

if __name__ == "__main__":
    test_config_parsing()
    print("Config tests passed!")