# Hermes Social Tracking Plugin Makefile

PYTHON ?= python3
VENV ?= venv
PIP := $(VENV)/bin/pip
PYTHON_BIN := $(VENV)/bin/python

.PHONY: all install test lint format docs clean

all: install test

install:
	@echo "Creating virtual environment..."
	@python -m venv $(VENV)
	@echo "Installing package in development mode..."
	@$(PIP) install -e .
	@echo "Installing development dependencies..."
	@$(PIP) install black isort flake8 mypy pytest pytest-cov

test:
	@echo "Running tests..."
	@$(PYTHON_BIN) -m pytest tests/ -v --cov=social_tracking

lint:
	@echo "Checking code style with flake8..."
	@$(PYTHON_BIN) -m flake8 social_tracking/ tests/ --count --select=E9,F63,F7,F82 --show-source --statistics
	@$(PYTHON_BIN) -m flake8 social_tracking/ tests/ --count --exit-zero --max-complexity=10 --max-line-length=127 --statistics
	
	@echo "Checking imports with isort..."
	@$(PYTHON_BIN) -m isort --check-only social_tracking/ tests/

format:
	@echo "Formatting code with black..."
	@$(PYTHON_BIN) -m black social_tracking/ tests/

mypy:
	@echo "Type checking with mypy..."
	@$(PYTHON_BIN) -m mypy social_tracking/ --ignore-missing-imports

docs:
	@echo "Generating documentation..."
	@sphinx-build -b html docs/ docs/_build/html

clean:
	@echo "Cleaning up..."
	@rm -rf $(VENV)
	@rm -rf docs/_build
	@rm -rf dist/
	@rm -rf build/
	@rm -rf *.egg-info

help:
	@echo "Available targets:"
	@echo "  all       - Run install and test"
	@echo "  install   - Create venv and install package"
	@echo "  test      - Run pytest tests"
	@echo "  lint      - Check code style with flake8 and isort"
	@echo "  format    - Format code with black"
	@echo "  mypy      - Type check with mypy"
	@echo "  docs      - Generate documentation"
	@echo "  clean     - Clean up build artifacts"
	@echo "  help      - Show this help message"