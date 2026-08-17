# ------------------------------------------------------------
# Global variables
# ------------------------------------------------------------
# Version
VERSION="1.0.0"

# Microsh Catalog
MICROSH_CATALOG_USER="rajmaholia"
MICROSH_CATALOG_REPO="MicroSH-Catalog"
MICROSH_CATALOG_BRANCH="main"
MICROSH_CATALOG_URL="https://raw.githubusercontent.com/${MICROSH_CATALOG_USER}/${MICROSH_CATALOG_REPO}/${MICROSH_CATALOG_BRANCH}/catalog.json"

# Standard Paths
XDG_BIN_HOME="${XDG_BIN_HOME:-$HOME/.local/bin}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# MicroSH Paths
MICROSH_DATA_DIR="$XDG_DATA_HOME/microsh"
MICROSH_CACHE_DIR="$XDG_CACHE_HOME/microsh"

# Installed application packages
MICROSH_APPS_DIR="${XDG_DATA_HOME:-$HOME}/microsh-apps"

# MicroSH catalog
MICROSH_CATALOG="$MICROSH_CACHE_DIR/catalog.json"

# Installed package registry
MICROSH_INSTALLED="$MICROSH_DATA_DIR/installed"
MICROSH_METADATA_DIR="$MICROSH_DATA_DIR/metadata"
INSTALLED="$MICROSH_DATA_DIR/installed"

mkdir -p "$MICROSH_CACHE_DIR"
mkdir -p "$MICROSH_DATA_DIR"
mkdir -p "$MICROSH_APPS_DIR"
mkdir -p $MICROSH_METADATA_DIR
