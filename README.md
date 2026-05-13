# Social Tracking Plugin for Hermes Agent

**Version:** 0.3.0
**Compatibility:** Hermes Agent with `neural-memory` (Mazemaker) provider

> Add human-like social awareness to your Hermes agent — automatically track people, relationships, commitments, trust dynamics, and social context across every conversation.

---

## What It Does

This plugin sits silently inside your Hermes agent and provides a **passive social awareness layer**. It intercepts every LLM call and tool call to:

- **Auto-discover people** — any named entity in messages automatically gets a person record
- **Track relationships** — "Alice is my coworker" → recorded automatically
- **Detect commitments** — "I'll send the files tomorrow" → tracked with status
- **Adjust trust scores** — sentiment-aware scoring with time-based decay
- **Proactively remind** — outstanding commitments are injected into context
- **Classify interactions** — categorizes conversations for social memory

The agent never needs to consciously call social tools — awareness is fully passive.

---

## Architecture

```
pre_llm_call                          post_llm_call
     │                                     │
     ├─ detect person names                ├─ extract from BOTH messages
     ├─ upsert person records              ├─ LLM social NLP (primary)
     ├─ recall social memories             ├─ regex fallback detection
     ├─ run ToM pipeline ◄─┐              ├─ commitment detection (bidirectional)
     ├─ build context block│              ├─ relationship detection
     ├─ inject proactive ◄─┘              ├─ sentiment → trust adjustment
     │  commitment reminders              └─ interaction classification
     │                                          │
     ├─ [SOCIAL CONTEXT] injected ──────────────┴─ interaction event logged
     │
     └─ Agent generates response
```

---

## Tools (4 explicit tools)

The plugin registers 4 tools the agent can call explicitly:

### `social_remember`
Store a socially-tagged memory, optionally linked to a named person.
```json
{
  "content": "string (required) — memory content",
  "person_name": "string (optional) — who this is about",
  "category": "string (default: 'social')"
}
```

### `social_query`
Query trust scores, pending commitments, or person profiles.
```json
{
  "person_name": "string (required)",
  "query_type": "enum: 'trust' | 'commitments' | 'profile'"
}
```

### `social_commit`
Explicitly record a promise (more reliable than auto-detection).
```json
{
  "description": "string (required) — what you're promising",
  "promisee_name": "string (default: 'user')",
  "due_date": "string (optional) — ISO 8601, e.g. '2026-05-15'"
}
```

### `social_fulfill`
Mark a commitment as fulfilled. Increases the fulfiller's trust.
```json
{
  "commitment_id": "string (required)",
  "fulfiller_name": "string (default: 'assistant')"
}
```

---

## Hooks (6 hooks registered)

| Hook | Trigger | What It Does |
|------|---------|-------------|
| `on_session_start` | Session begins | Creates session event, stores session ID |
| `pre_llm_call` | Before LLM generation | Detects persons, recalls memories, runs ToM pipeline, injects social context + commitment reminders |
| `post_llm_call` | After LLM responds | Extracts entities, records commitments/relationships/trust, classifies interaction |
| `on_session_end` | Session ends | Runs consolidation worker, logs session end |
| `pre_tool_call` | Before any tool call | Captures tool name and args for person detection |
| `post_tool_call` | After any tool call | Scans all tool output for person mentions, links to Mazemaker memories |

---

## Features

### Auto-Person Discovery
Any name mentioned in conversation automatically creates a person record. No manual registration needed.

### Entity Kind Detection
Automatically classifies entities as:
- **human** — default
- **agent** — AI assistants, bots (Claude, GPT, Hermes, etc.)
- **user** — the operator

### Sentiment-Aware Trust Scoring
Trust scores adjust based on interaction sentiment:
- Positive words ("thanks", "great", "perfect") → trust increases
- Negative words ("wrong", "broken", "terrible") → trust decreases (weighted 1.5×)
- Trust changes are small increments (±0.05 max per interaction)
- **Trust decay:** inactive human persons slowly lose trust (0.01/week after 7 days inactive)
- **Agents never decay** — their reliability doesn't fade with disuse

### Bidirectional Commitment Detection
Detects commitments from **both** user and assistant:
- Assistant → User: "I'll fix that bug"
- User → Assistant: "I will review the PR tomorrow"
- Third-party: "Alice promised Bob she'd send files"

### Relationship Detection
Automatically detects relationship statements:
- "Alice is my wife" → spouse relationship
- "Bob manages Charlie" → manager_of
- "Diana and Eve are colleagues" → colleague (bidirectional)
- Support for family, professional, personal, and adversarial relationships
- Detects relationship endings: breaks up, fired, divorced, no longer

### Proactive Commitment Reminders
Pending and broken commitments are injected into every LLM call with status icons:
- 🟡 pending
- 🔴 broken

### NLP + Regex Dual Pipeline
- **Primary path:** LLM-powered social signal extraction via `social_nlp.py`
- **Fallback:** Regex-based detection for all commitment, relationship, and sentiment patterns
- Ensures social awareness works even without LLM calls for extraction

---

## Installation

### Quick Install (one-liner)
```bash
curl -fsSL https://raw.githubusercontent.com/markogrcic/social-tracking-plugin/main/install.sh | bash
```

### Manual Install

1. **Clone the repository:**
```bash
git clone https://github.com/markogrcic/social-tracking-plugin.git ~/.hermes/plugins/social_tracking
```

2. **Install dependencies:**
```bash
pip install pydantic aiosqlite
```

3. **Ensure the `hermes_plugins` import path exists** (required for Hermes to find the plugin):
```bash
ln -sf ~/.hermes/plugins ~/.hermes/hermes_plugins
```

4. **Verify the plugin can be imported:**
```bash
python3 -c "import sys; sys.path.insert(0, '$HOME/.hermes'); import hermes_plugins.social_tracking; print('OK')"
```

5. **Restart Hermes Agent:**
```bash
# WSL2: user-level systemd is broken, use direct run
hermes gateway run
# Or in tmux: tmux new -s hermes 'hermes gateway run'
```

---

## Configuration

Add to your `config.yaml`:

```yaml
plugins:
  social_tracking:
    db_path: "~/.hermes/social_tracking.db"
    advanced_enabled: false
    entity_backend: "regex"      # or "spacy" for spaCy-based NER
    tom_pipeline_enabled: false
    consolidation_enabled: false
    consolidation_interval_s: 300
    trust_increment: 0.10
    trust_decrement: 0.20
    top_k_recall: 6
    tom_model: ""                # model name for ToM pipeline (empty = use default)
    domain_norms: []             # custom domain norms for the ToM pipeline
```

### Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `db_path` | string | `~/.hermes/social_tracking.db` | SQLite database path |
| `entity_backend` | string | `"regex"` | Entity extraction backend (`regex` or `spacy`) |
| `spacy_model` | string | (auto) | spaCy model name (only if entity_backend=spacy) |
| `tom_model` | string | (default) | Model for Theory-of-Mind pipeline |
| `top_k_recall` | int | 6 | Number of social memories to recall per LLM call |
| `consolidation_interval_s` | int | 300 | Background consolidation worker interval |
| `trust_increment` | float | 0.10 | Trust delta for positive interactions |
| `trust_decrement` | float | 0.20 | Trust delta for negative interactions |
| `trust_clamp_min` | float | 0.0 | Minimum trust score |
| `trust_clamp_max` | float | 1.0 | Maximum trust score |

---

## Database Schema

The plugin maintains a SQLite database with these tables:

| Table | Purpose | Key Columns |
|-------|---------|-------------|
| `persons` | People in your social graph | person_id, name, kind (human/agent/user), roles, trust_score, last_active |
| `events` | Social interactions | event_id, timestamp, kind (meeting/chat/etc.), context_notes |
| `commitments` | Promises and expectations | commitment_id, description, status (pending/fulfilled/broken), timestamp_promised, due_date |
| `meta` | Plugin configuration | key (e.g., "primary_user"), value |

### Foreign Key Relationships
- `person_events` — many-to-many between persons and events
- `commitment_parties` — maps commitments to persons with roles (`maker`, `target`)

---

## Usage Examples

### Explicit tool calls (agent-driven)

```
# Record a memory about someone
social_remember(content="Alice prefers concise communication", person_name="Alice")

# Check trust level
social_query(person_name="Alice", query_type="trust")

# Record a promise
social_commit(description="Review Alice's PR by Friday", due_date="2026-05-20")

# Fulfill a promise
social_fulfill(commitment_id="abc123")

# Get full profile
social_query(person_name="Alice", query_type="profile")
```

### Passive behavior (automatic)

When the plugin is active, the agent automatically:
- Creates person records for anyone mentioned by name
- Detects relationships from conversation context
- Tracks commitments made by anyone
- Adjusts trust based on sentiment
- Injects social context into every response
- Reminds the agent about outstanding commitments

No manual tool calls required.

---

## Files

```
social_tracking/
├── __init__.py          # Plugin entrypoint: register() — tools, hooks, components
├── plugin.yaml          # Plugin manifest (name, version, tools, hooks)
├── config.py            # SocialTrackingConfig — Pydantic config model
├── db.py                # SocialDB — SQLite database layer
├── memory_client.py     # MemoryClient — Mazemaker integration
├── entity.py            # extract_persons() — name extraction from text
├── trust.py             # TrustManager — trust score management
├── commitment.py        # CommitmentTracker — commitment lifecycle
├── tom_pipeline.py      # ToMPipeline — Theory-of-Mind reasoning
├── social_nlp.py        # LLM-powered social signal extraction
├── advanced/            # Optional advanced components (v1 legacy)
│   ├── entity_extractor.py
│   ├── trust_manager.py
│   ├── commitment_tracker.py
│   ├── consolidation.py
│   └── tompipeline.py
├── core/                # Shared core modules (v1 legacy)
│   ├── db.py
│   ├── hooks.py
│   └── tools.py
└── README.md            # This file
```

---

## Known Limitations

1. **Hook reliability:** The `post_tool_call` hook for Mazemaker tools may not fire reliably in all Hermes runtime versions. Verify before relying on hook side-effects.

2. **spaCy dependency:** The `spacy` entity backend requires `python -m spacy download en_core_web_sm`. The default `regex` backend works without additional dependencies.

3. **WSL2 systemd:** On WSL2, user-level systemd is broken. Use `hermes gateway run` directly (or in tmux) instead of `hermes gateway start`.

4. **Database concurrency:** SQLite handles concurrent reads well, but heavy concurrent writes during peak LLM call periods may cause brief locking. The plugin uses connection reuse to minimize this.

---

## Changelog

### v0.3.0 (2026-05-13)
- LLM-powered social NLP extraction with regex fallback for commitments, relationships, and sentiment
- Relationship detection: family, professional, personal, adversarial
- Relationship change detection: breakups, firings, divorces
- Entity kind auto-detection: human, agent, user
- Bidirectional commitment detection (user ↔ assistant ↔ third parties)
- Proactive commitment reminders in context injection
- Trust decay for inactive human persons (agents exempt)
- 6 hooks registered (on_session_start/end, pre/post_llm_call, pre/post_tool_call)
- All tools registered with proper JSON Schema

### v0.2.0
- Auto-person discovery from any named entity
- Sentiment-aware trust scoring
- Background consolidation worker
- Theory-of-Mind pipeline integration

### v0.1.0
- Basic SQLite social graph
- Manual tool calls for person/interaction/commitment management
- Pre/post_llm_call hooks for context injection

---

## License

MIT

## Author

Marko Grcic
