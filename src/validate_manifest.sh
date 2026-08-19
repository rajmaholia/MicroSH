validate_manifest() {
  local manifest="$1"

  # File must exist
  if [[ ! -f "$manifest" ]]; then
    error_print "microsh.json not found: $manifest" && return 1
  fi

  # Must be valid JSON
  if ! jq empty "$manifest" 2>/dev/null; then
    error_print "invalid JSON: $manifest" && return 1
  fi

  # Root must be an object
  if [[ "$(jq -r 'type' "$manifest")" != "object" ]]; then
    error_print "microsh.json root must be an object" && return 1
  fi

  # Required fields
  local id
  local name
  local version

  id="$(jq -r '.id // empty' "$manifest")"
  name="$(jq -r '.name // empty' "$manifest")"
  version="$(jq -r '.version // empty' "$manifest")"

  if [[ -z "$id" ]]; then
    error_print "microsh.json: missing 'id'" && return 1
  fi

  if [[ -z "$name" ]]; then
    error_print "microsh.json: missing 'name'" && return 1
  fi

  if [[ -z "$version" ]]; then
    error_print "microsh.json: missing 'version'" && return 1
  fi

  # Validate field types
  if [[ "$(jq -r '.id | type' "$manifest")" != "string" ]]; then
    error_print "microsh.json: 'id' must be a string" && return 1
  fi

  if [[ "$(jq -r '.name | type' "$manifest")" != "string" ]]; then
    error_print "microsh.json: 'name' must be a string" && return 1
  fi

  if [[ "$(jq -r '.version | type' "$manifest")" != "string" ]]; then
    error_print "microsh.json: 'version' must be a string" && return 1
  fi

  # ID: lowercase letters, numbers and hyphens only
  if [[ ! "$id" =~ ^[a-z0-9]+([.-][a-z0-9]+)*$ ]]; then
    error_print "microsh.json: invalid package id '$id'" && return 1
  fi

  # Optional description
  if jq -e '.description != null and (.description | type) != "string"' \
    "$manifest" >/dev/null; then
    error_print "microsh.json: 'description' must be a string" && return 1
  fi

  # Optional dependencies
  if jq -e '.dependencies != null and (.dependencies | type) != "object"' \
    "$manifest" >/dev/null; then
    error_print "microsh.json: 'dependencies' must be an object" && return 1
  fi

  # Optional exec
  if jq -e '.exec != null and (.exec | type) != "object"' \
    "$manifest" >/dev/null; then
    error_print "microsh.json: 'exec' must be an object" && return 1
  fi

  return 0
}
