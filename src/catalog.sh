download_catalog() {
  local temporary

  temporary="$(mktemp)"

  info "Updating MicroSH Catalog..."

  if ! download "$MICROSH_CATALOG_URL" >"$temporary"; then
    rm -f "$temporary"
    error "could not download MicroSH catalog"
  fi

  if ! jq -e '
        type == "object"
        and (.["catalog-version"] | type == "number")
        and (.apps | type == "object")
      ' "$temporary" >/dev/null 2>&1; then

    rm -f "$temporary"
    error "downloaded catalog has an invalid format"
  fi

  mv "$temporary" "$MICROSH_CATALOG"

  info "Catalog updated."
}

catalog_exists() {
  [[ -f "$MICROSH_CATALOG" ]]
}

ensure_catalog() {
  if ! catalog_exists; then
    download_catalog
  fi
}

app_exists() {
  local app="$1"

  jq -e \
    --arg app "$app" \
    '.apps | has($app)' \
    "$MICROSH_CATALOG" >/dev/null
}

latest_version() {
  local app="$1"

  jq -r \
    --arg app "$app" \
    '.apps[$app].latest' \
    "$MICROSH_CATALOG"
}

version_exists() {
  local app="$1"
  local version="$2"

  jq -e \
    --arg app "$app" \
    --arg version "$version" \
    '.apps[$app].versions | has($version)' \
    "$MICROSH_CATALOG" >/dev/null
}

package_url() {
  local app="$1"
  local version="$2"

  jq -r \
    --arg app "$app" \
    --arg version "$version" \
    '.apps[$app].versions[$version].url' \
    "$MICROSH_CATALOG"
}

package_sha256() {
  local app="$1"
  local version="$2"

  jq -r \
    --arg app "$app" \
    --arg version "$version" \
    '.apps[$app].versions[$version].sha256 // empty' \
    "$MICROSH_CATALOG"
}
