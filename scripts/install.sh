#!/bin/bash
set -e  # Exit on any error

# Hermes Social Tracking Plugin Installation Script
# Version: 1.0
# Description: Automates the installation of the social-tracking plugin for Hermes

echo "================================================="
echo "Hermes Social Tracking Plugin Installation"
echo "================================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${YELLOW}Note: This script is not running as root.${NC}"
   echo "You may need to run with sudo if installing system-wide dependencies."
   echo ""
fi

# Function to check dependencies
check_dependencies() {
    echo "Checking dependencies..."
    
    # Check Python
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}Error: python3 could not be found.${NC}"
        exit 1
    fi
    
    # Check pip
    if ! command -v pip3 &> /dev/null; then
        echo -e "${RED}Error: pip3 could not be found.${NC}"
        exit 1
    fi
    
    # Check if pydantic is installed
    if ! pip3 show pydantic &> /dev/null; then
        echo -e "${YELLOW}pydantic not found. Installing...${NC}"
        pip3 install pydantic
    else
        echo "pydantic: $(pip3 show pydantic | grep Version | cut -d' ' -f2)"
    fi
    
    echo -e "${GREEN}All dependencies are satisfied!${NC}"
    echo ""
}

# Function to install optional spaCy dependencies
install_spacy() {
    if [[ "$ADVANCED_ENABLED" == "true" ]]; then
        read -p "Do you want to install spaCy for advanced entity extraction? (y/n): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Installing spaCy and English model..."
            pip3 install spacy
            python3 -m spacy download en_core_web_sm
            echo -e "${GREEN}spaCy installation complete!${NC}"
        fi
    fi
}

# Function to install the plugin
install_plugin() {
    echo "Installing social-tracking plugin..."
    
    # Create plugins directory if it doesn't exist
    mkdir -p ~/.hermes/plugins/social-tracking
    
    # Copy files to the plugins directory
    cp -r ./* ~/.hermes/plugins/social-tracking/
    
    # Make sure permissions are correct
    chmod +x ~/.hermes/plugins/social-tracking/*.py
    
    echo -e "${GREEN}Plugin installed successfully to ~/.hermes/plugins/social-tracking${NC}"
    echo ""
}

# Function to configure the plugin
configure_plugin() {
    echo "Plugin installed! Next steps:"
    echo "1. Add configuration to your Hermes config.yaml:"
    echo ""
    echo "social_tracking:"
    echo "  db_path: \"~/.hermes/data/social_tracking.db\""
    echo "  advanced_enabled: false"
    echo ""
    echo "2. Restart your Hermes agent:"
    echo "hermes restart"
    echo ""
    echo -e "${YELLOW}For advanced features (entity extraction, ToM pipeline, etc.),${NC}"
    echo -e "${YELLOW}set advanced_enabled: true and configure additional settings.${NC}"
    echo ""
}

# Main installation function
main() {
    echo "Starting installation..."
    echo ""
    
    # Parse command line arguments
    ADVANCED_ENABLED=false
    if [[ "$1" == "--advanced" ]]; then
        ADVANCED_ENABLED=true
        echo -e "${YELLOW}Advanced features will be enabled.${NC}"
    fi
    
    check_dependencies
    install_plugin
    
    if [[ "$ADVANCED_ENABLED" == "true" ]]; then
        install_spacy
    fi
    
    configure_plugin
}

# Run main function
main "$@"

echo "================================================="
echo "Installation Complete!"
echo "================================================="
echo ""
echo "Plugin: social-tracking (v0.3.0)"
echo "Location: ~/.hermes/plugins/social-tracking"
echo ""
echo "Next: Restart Hermes agent and configure as needed."
echo "================================================="