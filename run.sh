#!/usr/bin/env bash
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/src" && pwd)"

source "$SRC_DIR/header.sh"
source "$SRC_DIR/common.sh"
source "$SRC_DIR/catalog.sh"
source "$SRC_DIR/dependency.sh"
source "$SRC_DIR/metadata.sh"
source "$SRC_DIR/package.sh"
source "$SRC_DIR/command.sh"
source "$SRC_DIR/help.sh"
source "$SRC_DIR/main.sh"

main "$@"
