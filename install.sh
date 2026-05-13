#!/usr/bin/env bash
# Social Tracking Plugin — Install Script for Hermes Agent
# Usage: curl -fsSL https://raw.githubusercontent.com/markogrcic/social-tracking-plugin/main/install.sh | bash
#    OR: chmod +x install.sh && ./install.sh

set -euo pipefail

HERMES_DIR="${HOME}/.hermes"
PLUGIN_DIR="${HERMES_DIR}/plugins/social_tracking"
DB_PATH="${HERMES_DIR}/social_tracking.db"
PLUGIN_YAML="${PLUGIN_DIR}/plugin.yaml"
REPO_URL="https://github.com/markogrcic/social-tracking-plugin.git"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

header() { echo -e "\n${GREEN}=== $1 ===${NC}\n"; }
warn()   { echo -e "${YELLOW}⚠  $1${NC}"; }
ok()     { echo -e "${GREEN}✓  $1${NC}"; }
fail()   { echo -e "${RED}✗  $1${NC}" >&2; exit 1; }

header "Social Tracking Plugin Installer"

# --- 1. Check prerequisites ---
header "Checking prerequisites"

if ! command -v python3 &>/dev/null; then
    fail "python3 not found — install Python 3.10+ first"
fi

if ! command -v git &>/dev/null; then
    fail "git not found — install Git first"
fi

echo "Python: $(python3 --version 2>&1)"
echo "Git:    $(git --version 2>&1)"

# --- 2. Check Hermes directory ---
header "Checking Hermes setup"

if [ ! -d "$HERMES_DIR" ]; then
    fail "Hermes directory not found at $HERMES_DIR — install Hermes Agent first"
fi
ok "Hermes directory found: $HERMES_DIR"

# Create plugins directory if missing
mkdir -p "$HERMES_DIR/plugins"

# --- 3. Install or update plugin ---
header "Installing plugin"

if [ -d "$PLUGIN_DIR/.git" ]; then
    echo "Plugin directory exists with git — updating..."
    cd "$PLUGIN_DIR" || fail "Could not cd to $PLUGIN_DIR"
    git pull origin main 2>/dev/null || {
        warn "Git pull failed — removing and re-cloning"
        cd .. && rm -rf social_tracking && git clone "$REPO_URL" social_tracking
    }
elif [ -d "$PLUGIN_DIR" ]; then
    echo "Plugin directory exists without git — installing fresh version..."
    rm -rf "$PLUGIN_DIR"
    git clone "$REPO_URL" "$PLUGIN_DIR"
else
    echo "Cloning repository..."
    git clone "$REPO_URL" "$PLUGIN_DIR"
fi

ok "Plugin files installed to $PLUGIN_DIR"

# --- 4. Verify plugin structure ---
header "Verifying installation"

if [ ! -f "$PLUGIN_YAML" ]; then
    fail "plugin.yaml not found — installation failed"
fi

if [ ! -f "${PLUGIN_DIR}/__init__.py" ]; then
    fail "__init__.py not found — installation failed"
fi

VERSION=$(grep '^version:' "$PLUGIN_YAML" | head -1 | awk '{print $2}')
ok "Plugin version: $VERSION"

# --- 5. Create hermes_plugins symlink ---
header "Setting up import path"

# Hermes imports plugins as hermes_plugins.<name>, so we need a symlink
HERMES_PLUGINS_LINK="${HERMES_DIR}/hermes_plugins"

if [ -L "$HERMES_PLUGINS_LINK" ]; then
    ok "hermes_plugins symlink exists"
elif [ -e "$HERMES_PLUGINS_LINK" ]; then
    warn "$HERMES_PLUGINS_LINK exists as regular file — not a symlink"
else
    ln -sf "${HERMES_DIR}/plugins" "$HERMES_PLUGINS_LINK"
    ok "Created symlink: hermes_plugins → plugins"
fi

# Verify import
if python3 -c "import sys; sys.path.insert(0, '${HERMES_DIR}'); import hermes_plugins.social_tracking" 2>/dev/null; then
    ok "Plugin imports successfully"
else
    warn "Plugin import check failed — this may be normal if dependencies aren't installed yet"
fi

# --- 6. Install dependencies ---
header "Installing Python dependencies"

# Check if pydantic and aiosqlite are already installed
DEPS_NEEDED=""
python3 -c "import pydantic" 2>/dev/null || DEPS_NEEDED="$DEPS_NEEDED pydantic"
python3 -c "import aiosqlite" 2>/dev/null || DEPS_NEEDED="$DEPS_NEEDED aiosqlite"

if [ -z "$DEPS_NEEDED" ]; then
    ok "All dependencies already installed"
else
    echo "Installing:$DEPS_NEEDED"
    pip3 install $DEPS_NEEDED --quiet --user 2>/dev/null || \
        pip3 install $DEPS_NEEDED --quiet 2>/dev/null || {
            warn "pip install failed — try: pip3 install pydantic aiosqlite"
        }
    ok "Dependencies installed$DEPS_NEEDED"
fi

# Optional: spaCy for advanced entity extraction
echo ""
echo "Optional: For spaCy-based entity extraction (more accurate):"
echo "  pip3 install spacy"
echo "  python3 -m spacy download en_core_web_sm"

# --- 7. Database ---
header "Database"

if [ -f "$DB_PATH" ]; then
    SIZE=$(du -h "$DB_PATH" 2>/dev/null | awk '{print $1}')
    echo "Existing database found: $DB_PATH ($SIZE)"
else
    echo "Database will be created automatically on first use: $DB_PATH"
fi

# --- 8. Restart instructions ---
header "Next steps"

echo -e "${GREEN}Plugin installed successfully!${NC}"
echo ""
echo "To activate the plugin, restart your Hermes gateway:"
echo ""
echo "  # Standard:"
echo "  hermes gateway restart"
echo ""
echo "  # WSL2 (user-level systemd is broken):"
echo "  pkill -f 'hermes gateway' 2>/dev/null; hermes gateway run"
echo ""
echo "  # Or in tmux:"
echo "  tmux new -s hermes 'hermes gateway run'"
echo ""
echo "After restart, verify with:"
echo "  hermes plugins list | grep social-tracking"
echo ""
