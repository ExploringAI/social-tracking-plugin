# Contributing to Hermes Social Tracking Plugin

Thank you for your interest in contributing! We welcome contributions from the community. This guide explains how to get started.

## Development Setup

### Prerequisites

- Python 3.10+
- pip
- git
- SQLite (usually pre-installed on most systems)

### Environment Setup

1. **Clone the repository:**

   ```bash
   git clone https://github.com/yourusername/hermes-social-tracking-plugin.git
   cd hermes-social-tracking-plugin
   ```

2. **Create and activate a virtual environment:**

   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install dependencies:**

   ```bash
   pip install -r requirements.txt
   pip install -e .  # Install plugin in development mode
   ```

4. **Install optional dependencies (for advanced features):**

   ```bash
   pip install spacy
   python -m spacy download en_core_web_sm
   ```

## Code Standards

### Style Guide

We follow standard Python conventions:

- **PEP 8** for code style
- **Black** for code formatting
- **isort** for import sorting
- **flake8** for linting
- **mypy** for type checking

### Git Workflow

1. **Create a feature branch:**

   ```bash
   git checkout -b feature/your-feature-branch
   ```

2. **Make your changes** and commit frequently with descriptive messages.

3. **Run tests** before committing:

   ```bash
   pytest tests/
   ```

4. **Push to the branch:**

   ```bash
   git push origin feature/your-feature-branch
   ```

5. **Create a Pull Request** with a clear description of the changes.

### Testing

We use pytest for testing. All tests should be placed in the `tests/` directory.

#### Running Tests

```bash
# Run all tests
pytest tests/

# Run unit tests
pytest tests/unit/

# Run integration tests
pytest tests/integration/

# Run with coverage
pytest --cov=social_tracking tests/
```

#### Writing Tests

- Test functions should start with `test_`
- Use fixtures for setup and teardown
- Test edge cases and error conditions
- Aim for high code coverage

## Documentation

All new features should include:

1. **Inline documentation** using docstrings
2. **Update README.md** with usage examples
3. **Add to API reference** if it's a new function/class
4. **Update documentation** in the `docs/` directory

## Issue Tracking

### Reporting Bugs

When reporting bugs, please include:

- Your operating system and version
- Python version
- Hermes version
- Steps to reproduce
- Expected vs actual behavior
- Any relevant logs or error messages

### Feature Requests

We welcome feature requests! Please provide:

- A clear description of the feature
- Use cases and examples
- How it fits with the plugin's goals
- Any design considerations

## Pull Request Guidelines

1. **Keep PRs small and focused** - one feature or bug fix per PR
2. **Include tests** for all new functionality
3. **Update documentation** as needed
4. **Follow code style** guidelines
5. **Squash commits** before merging (maintain clean history)

## Project Structure

```
hermes-social-tracking-plugin/
├── social_tracking/       # Main plugin package
│   ├── __init__.py       # Plugin entry point
│   ├── config.py         # Configuration classes
│   ├── db.py             # Database operations
│   ├── entity.py         # Entity extraction
│   ├── trust.py          # Trust management
│   ├── commitment.py     # Commitment tracking
│   ├── tom_pipeline.py   # Theory-of-Mind pipeline
│   ├── memory_client.py  # Mazemaker integration
│   ├── core/             # Core functionality
│   └── advanced/         # Advanced features
├── tests/                # Test suite
├── docs/                 # Documentation
├── examples/             # Example usage
├── scripts/              # Installation scripts
├── .gitignore
├── LICENSE.md
├── README.md
├── CONTRIBUTING.md
├── setup.py
└── requirements.txt
```

## Getting Help

If you need help:

1. **Check the documentation** first
2. **Search existing issues** on GitHub
3. **Ask in our Discord community**
4. **Open a new issue** if you can't find an answer

## Code of Conduct

We expect all contributors to follow our [Code of Conduct](CODE_OF_CONDUCT.md). Please be respectful, inclusive, and constructive.

## Maintainers

For maintainer inquiries, please contact the project maintainers directly.

## Thank You!

Thank you for contributing to the Hermes Social Tracking Plugin! Your work helps make AI agents more socially intelligent and capable of meaningful human interaction.