#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$ROOT_DIR/src"
DIST_DIR="$ROOT_DIR/dist"

OUTPUT="$DIST_DIR/microsh"
OUTPUT_CHECKSUM="$DIST_DIR/microsh.sha256"
TEMP="$DIST_DIR/.microsh.tmp"

mkdir -p "$DIST_DIR"

{
  printf '%s\n' '#!/usr/bin/env bash'
  printf '%s\n' 'set -euo pipefail'
  printf '\n'

  cat \
    "$SRC_DIR/header.sh" \
    "$SRC_DIR/common.sh" \
    "$SRC_DIR/catalog.sh" \
    "$SRC_DIR/dependency.sh" \
    "$SRC_DIR/metadata.sh" \
    "$SRC_DIR/package.sh" \
    "$SRC_DIR/validate_manifest.sh" \
    "$SRC_DIR/command.sh" \
    "$SRC_DIR/help.sh" \
    "$SRC_DIR/main.sh"

  printf '\nmain "$@"\n'
} >"$TEMP"

# Check assembled source
bash -n "$TEMP"

# Minify directly into another temporary file
shfmt --minify "$TEMP" >"$TEMP.min"

# Check minified result
bash -n "$TEMP.min"

# Replace final executable
mv "$TEMP.min" "$OUTPUT"

rm -f "$TEMP"

chmod 555 "$OUTPUT"

sha256sum "$OUTPUT" >"$OUTPUT_CHECKSUM"

printf 'Built: %s\n' "$OUTPUT"
