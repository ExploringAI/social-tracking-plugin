# Hermes Social Tracking Plugin Documentation

## Table of Contents

1. [Architecture](#architecture)
2. [Database Schema](#database-schema)
3. [API Reference](#api-reference)
4. [Configuration Options](#configuration-options)
5. [Advanced Features](#advanced-features)
6. [Troubleshooting](#troubleshooting)

## Architecture

The social_tracking plugin follows a modular architecture designed for extensibility and performance:

```
┌─────────────────┐
│   Hermes        │
│   Agent Core    │
│                 │
│   ┌───────────┐ │
│   │ LLM Call  │◄──┐
│   └───────────┘ │   ┌─────────────────┐
└─────────────────┘   │ Pre-LLM Hook    │
    │               │ (social_context) │
    ▼               └────────┬────────┘
┌─────────┐                    │
│  Tools  │◄───────────────────┘
└─────────┘
    │
    ▼
┌─────────────────┐    ┌─────────────────┐
│  Social Memory  │◄───┤   Post-LLM      │
│   (SQLite)      │    │   Hook         │
└─────────────────┘    └─────────────────┘
         ▲
         │
┌─────────────────┐
│   Background    │
│   Workers       │
└─────────────────┘
```

### Core Components

1. **SocialDB**: SQLite wrapper with social tracking schema
2. **MemoryClient**: Integrates with Mazemaker's neural memory
3. **TrustManager**: Dynamic trust scoring system
4. **CommitmentTracker**: Promise lifecycle management
5. **ToMPipeline**: Lightweight Theory-of-Mind analysis
6. **EntityExtractor**: Person name detection and extraction

## Database Schema

The plugin maintains a separate SQLite database with these tables:

### persons
```sql
CREATE TABLE persons (
    person_id    INTEGER PRIMARY KEY AUTOINCREMENT,
    name         TEXT NOT NULL UNIQUE,
    roles        TEXT,
    last_active  TEXT,
    trust_score  REAL NOT NULL DEFAULT 0.5,
    kind         TEXT NOT NULL DEFAULT 'human'
);
```

### events
```sql
CREATE TABLE events (
    event_id   INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp  TEXT NOT NULL,
    kind       TEXT,
    summary    TEXT
);
```

### person_events (junction table)
```sql
CREATE TABLE person_events (
    person_id  INTEGER NOT NULL,
    event_id   INTEGER NOT NULL,
    PRIMARY KEY (person_id, event_id),
    FOREIGN KEY (person_id) REFERENCES persons(person_id) ON DELETE CASCADE,
    FOREIGN KEY (event_id) REFERENCES events(event_id)   ON DELETE CASCADE
);
```

### commitments
```sql
CREATE TABLE commitments (
    commitment_id      INTEGER PRIMARY KEY AUTOINCREMENT,
    description        TEXT NOT NULL,
    status             TEXT NOT NULL CHECK(status IN ('pending','fulfilled','broken')),
    timestamp_promised TEXT NOT NULL,
    due_date           TEXT,
    timestamp_updated  TEXT NOT NULL
);
```

### commitment_parties
```sql
CREATE TABLE commitment_parties (
    commitment_id  INTEGER NOT NULL,
    role           TEXT NOT NULL, -- 'maker' or 'target' or 'other'
    person_id      INTEGER NOT NULL,
    PRIMARY KEY (commitment_id, role, person_id),
    FOREIGN KEY (commitment_id) REFERENCES commitments(commitment_id) ON DELETE CASCADE,
    FOREIGN KEY (person_id) REFERENCES persons(person_id) ON DELETE CASCADE
);
```

### relationships
```sql
CREATE TABLE relationships (
    relationship_id INTEGER PRIMARY KEY AUTOINCREMENT,
    person_a_id     INTEGER NOT NULL,
    person_b_id     INTEGER NOT NULL,
    rel_type        TEXT NOT NULL,
    strength        REAL NOT NULL DEFAULT 0.5,
    status          TEXT NOT NULL DEFAULT 'active',
    started_at      TEXT,
    ended_at        TEXT,
    source          TEXT DEFAULT 'conversation',
    confidence      REAL NOT NULL DEFAULT 0.5,
    notes           TEXT,
    created_at      TEXT NOT NULL,
    updated_at      TEXT NOT NULL,
    FOREIGN KEY (person_a_id) REFERENCES persons(person_id) ON DELETE CASCADE,
    FOREIGN KEY (person_b_id) REFERENCES persons(person_id) ON DELETE CASCADE
);
```

### meta
```sql
CREATE TABLE meta (
    key    TEXT PRIMARY KEY,
    value  TEXT
);
```

## API Reference

### Core Functions

#### SocialDB Module

```python
class SocialDB:
    def __init__(self, db_path: str | Path)
    def connect(self) -> None
    def init_db(self) -> None
    def upsert_person(self, name: str, roles: Optional[List[str]] = None, 
                     kind: str = "human") -> int
    def get_person(self, name: str) -> Optional[Dict[str, Any]]
    def adjust_trust(self, person_ids: List[int], delta: float) -> None
    def record_event(self, summary: str, kind: str = "chat_turn", 
                    persons: Optional[List[str]] = None) -> int
    def get_recent_events_for_person(self, name: str, limit: int = 5) -> List[Dict[str, Any]]
    def add_commitment(self, from_person: str, to_person: str, description: str,
                      due_date: Optional[str] = None) -> int
    def update_commitment_status(self, commitment_id: int, status: str,
                                fulfilled_by: Optional[str] = None) -> Dict[str, Any]
    def get_open_commitments_for_person(self, name: str, limit: int = 10) -> List[Dict[str, Any]]
```

#### TrustManager Module

```python
class TrustManager:
    def __init__(self, db, increment: float = 0.05, decrement: float = 0.05,
                 clamp_min: float = 0.0, clamp_max: float = 1.0)
    def get_trust(self, name: str) -> float
    def trust_summary(self, name: str) -> str
    def adjust(self, person_id: int, delta: float) -> None
    def reward(self, person_id: int) -> None
    def penalize(self, person_id: int) -> None
```

#### EntityExtractor Module

```python
def extract_persons(text: str, backend: str = "regex", 
                   spacy_model: str = "") -> List[str]
```

## Configuration Options

### Main Configuration

```yaml
social_tracking:
  db_path: "~/.hermes/data/social_tracking.db"
  advanced_enabled: false  # Enable advanced features
```

### Advanced Configuration (when advanced_enabled=true)

```yaml
  # Entity extraction
  entity_backend: "regex"  # or "spacy"
  spacy_model: "en_core_web_sm"
  
  # ToM pipeline
  tom_pipeline_enabled: false
  tom_model: null
  domain_norms: null
  
  # Trust management
  trust_increment: 0.10
  trust_decrement: 0.20
  trust_clamp_min: -1.0
  trust_clamp_max: 1.0
  
  # Background consolidation
  consolidation_enabled: false
  consolidation_interval_s: 300
  
  # Memory recall
  top_k_recall: 10
```

## Advanced Features

### Entity Extraction

When `entity_backend: "spacy"` is configured, the plugin uses spaCy's NER capabilities for more accurate person detection. This is particularly useful for:

- Detecting persons in complex sentences
- Handling pronouns and references
- Extracting multiple persons from a single sentence
- Filtering out non-person entities

### Theory-of-Mind Pipeline

The ToM pipeline provides lightweight social reasoning without external LLM calls:

1. **Emotion Detection** - Identifies user emotion from message content
2. **Intent Recognition** - Determines user intent (question, request, commitment, etc.)
3. **Domain Analysis** - Suggests appropriate tone and social norms
4. **Context Injection** - Injects social context into LLM prompts

### Trust Management

Dynamic trust scoring system that automatically adjusts based on:

- **Positive interactions** - Trust increases for helpful/positive exchanges
- **Commitments** - Trust adjusts based on promise fulfillment
- **Sentiment analysis** - Trust responds to emotional tone
- **Time decay** - Inactive relationships slowly lose trust

### Commitment Tracking

Automatic detection and management of commitments:

- **Promise detection** - Identifies "I will", "I'll", "I promise" statements
- **Expiry handling** - Tracks due dates and sends reminders
- **Breach detection** - Automatically detects broken commitments
- **Trust adjustment** - Adjusts trust based on commitment outcomes

## Troubleshooting

### Common Issues

#### "Plugin not found" error
- Ensure the plugin is installed in `~/.hermes/plugins/social-tracking/`
- Check that the directory name matches exactly (case-sensitive)
- Restart Hermes after installation

#### Database connection errors
- Verify that the database path is writable
- Check that SQLite is installed
- Ensure no other process is locking the database

#### Entity extraction not working
- If using spaCy, ensure it's installed: `pip install spacy`
- Download the spaCy model: `python -m spacy download en_core_web_sm`
- Set `entity_backend: "spacy"` in config

#### Trust scores not updating
- Check that `consolidation_enabled: true` is set in config
- Verify that commitments are being properly recorded
- Ensure the background worker is running

### Debugging Tips

1. **Enable debug logging**:
   ```yaml
   logging:
     plugins.social_tracking: DEBUG
   ```

2. **Check database directly**:
   ```bash
   sqlite3 ~/.hermes/data/social_tracking.db
   ```

3. **Test tools individually**:
   ```bash
   /social_get_context
   /social_add_person name=Test
   ```

4. **View plugin logs**:
   ```bash
   tail -f ~/.hermes/logs/hermes-agent.log | grep social
   ```

### Performance Optimization

- **Database indexing**: Ensure proper indexes on frequently queried columns
- **Batch operations**: Use bulk operations when processing multiple persons
- **Caching**: Cache frequently accessed person data
- **Consolidation interval**: Adjust based on your usage patterns

## Support

For additional help, please:

- Check the [GitHub Issues](https://github.com/yourusername/hermes-social-tracking-plugin/issues)
- Join our [Discord Community](https://discord.gg/yourdiscord)
- Read the [full documentation](https://yourusername.github.io/hermes-social-tracking-plugin/)

## Contributing

We welcome contributions! Please read our [CONTRIBUTING.md](CONTRIBUTING.md) guide.