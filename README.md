# Hermes Social Tracking Plugin

[![Version](https://img.shields.io/badge/version-0.3.0-blue.svg)](https://github.com/yourusername/hermes-social-tracking-plugin)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE.md)

**Human-like social awareness layer for Hermes AI agents** - This plugin adds sophisticated social tracking capabilities including person/relationship management, dynamic trust scoring, commitment tracking, and Theory-of-Mind analysis.

## Features

### Core Features (always enabled)
- **Lightweight SQLite social graph** - Track persons, interactions, commitments, and trust scores
- **15+ specialized tools** for social memory operations
- **Seamless hooks integration** - `pre_llm_call`, `post_llm_call`, `on_session_start`, `on_session_end`, `pre_tool_call`, `post_tool_call`
- **Auto-person-discovery** - Automatically extract and track named entities from conversations
- **Passive awareness** - The agent never needs to consciously call social tools; awareness is fully passive

### Advanced Features (optional - enable in config)
- **Entity extraction** - Automatic person name extraction with spaCy or regex fallback
- **Dynamic trust management** - Trust scores updated based on fulfilled/broken promises
- **Commitment lifecycle tracking** - Promise detection, expiry, and breach handling
- **Theory-of-Mind pipeline** - MetaMind-style ToM → Domain → Response reasoning
- **Background consolidation** - Periodic trust updates and memory summaries

## Installation

### Prerequisites
- Hermes Agent with Mazemaker memory provider
- Python 3.10+
- pip package manager

### Installation Methods

#### Method 1: Manual Installation (Recommended for production)

```bash
# 1. Install Python dependencies
pip install pydantic

# 2. Copy plugin to Hermes plugins directory
mkdir -p ~/.hermes/plugins/social-tracking
cp -r /path/to/social-tracking/* ~/.hermes/plugins/social-tracking/

# 3. Restart Hermes Agent
hermes restart
```

#### Method 2: Automated Installation Script

```bash
# Download and run the installation script
curl -fsSL https://raw.githubusercontent.com/yourusername/hermes-social-tracking-plugin/main/scripts/install.sh | bash
```

Or if you have the repository cloned:

```bash
cd /path/to/social-tracking
chmod +x scripts/install.sh
./scripts/install.sh
```

#### Method 3: Docker Installation

If you're running Hermes in Docker, add this to your docker-compose.yml:

```yaml
version: '3.8'

services:
  hermes:
    image: your-hermes-image
    volumes:
      - ./plugins/social-tracking:/home/hermes/.hermes/plugins/social-tracking
    environment:
      - SOCIAL_TRACKING_ADVANCED_ENABLED=true
    # ... other configuration
```

### Configuration

Add the following to your Hermes `config.yaml`:

```yaml
social_tracking:
  db_path: "~/.hermes/data/social_tracking.db"
  advanced_enabled: false  # Set to true to enable advanced features
  
  # Advanced settings (only used if advanced_enabled=True)
  entity_backend: "regex"  # or "spacy"
  tom_pipeline_enabled: false
  consolidation_enabled: false
  trust_increment: 0.10
  trust_decrement: 0.20
  consolidation_interval_s: 300
```

## Usage Examples

### Basic Commands

```bash
# Set primary user
/social_set_primary_user name=Marko

# Add a person
/social_add_person name=Alice roles=['friend', 'coworker']

# Log an interaction
/social_add_interaction summary="Had lunch with Alice and discussed the project" persons=['Alice', 'Bob'] kind=meeting

# Record a commitment
/social_add_commitment from_person=Alice to_person=Marko description="Will send the design files" due_date="2024-12-01"

# Update commitment status
/social_update_commitment_status commitment_id=1 status=fulfilled

# Get social context
/social_get_context  # Returns summary for primary user
/social_get_context person=Alice limit=3  # Focus on Alice
```

### Advanced Usage

When advanced features are enabled, additional tools become available:

- `social_query` - Query trust scores and commitments
- `social_commit` - Explicitly record promises
- `social_fulfill` - Mark commitments as fulfilled

The ToM pipeline can be invoked via `delegate_task` or integrated into prompts for sophisticated social reasoning.

## Database Schema

The plugin maintains a separate SQLite database with these tables:

- `persons` - People with trust scores and roles
- `events` - Social interactions and events
- `commitments` - Promises and expectations
- `meta` - Configuration like primary user name
- `relationships` - Relationship types and strengths between persons

## Technical Architecture

### Core Components

1. **SocialDB** - SQLite wrapper with social tracking schema
2. **MemoryClient** - Integrates with Mazemaker's neural memory
3. **TrustManager** - Dynamic trust scoring system
4. **CommitmentTracker** - Promise lifecycle management
5. **ToMPipeline** - Lightweight Theory-of-Mind analysis
6. **EntityExtractor** - Person name detection and extraction

### Integration Points

- **Hermes Hooks** - pre_llm_call, post_llm_call, on_session_start, on_session_end
- **Mazemaker Memory** - Uses neural_remember and neural_recall for context injection
- **Tool Registry** - Provides 15+ specialized social tools

## Development & Testing

### Setup Development Environment

```bash
# Clone the repository
git clone https://github.com/yourusername/hermes-social-tracking-plugin.git
cd hermes-social-tracking-plugin

# Create virtual environment
python -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
pip install -e .  # Install plugin in development mode
```

### Run Tests

```bash
# Unit tests
pytest tests/

# Integration tests
pytest tests/integration/

# Performance benchmarks
python -m benchmarks.run_benchmark
```

### Code Quality

We use:
- Black for code formatting
- isort for import sorting
- flake8 for linting
- mypy for type checking

## Contributing

We welcome contributions! Please follow these steps:

1. Fork the repository
2. Create a feature branch
3. Make your changes with appropriate tests
4. Submit a pull request

### Code of Conduct

All contributors must adhere to our [Code of Conduct](CODE_OF_CONDUCT.md).

## License

MIT License - see [LICENSE](LICENSE.md) for details.

## Support

- [Documentation](https://yourusername.github.io/hermes-social-tracking-plugin/)
- [GitHub Issues](https://github.com/yourusername/hermes-social-tracking-plugin/issues)
- [Discord Community](https://discord.gg/yourdiscord)

## Security

If you discover a security vulnerability, please review our [Security Policy](SECURITY.md).