# Interaction with MicroSH APP installation metadata.
installed_version() {
  local app="$1"
  local version

  [[ -f "$MICROSH_INSTALLED" ]] || return 1

  version="$(
    awk -v app="$app" '$1 == app { print $2; exit }' \
      "$MICROSH_INSTALLED"
  )"

  [[ -n "$version" ]] || return 1

  printf '%s\n' "$version"
  return 0
}

is_installed() {
  local app="$1"

  installed_version "$app" >/dev/null
}

mark_installed() {
  local app="$1"
  local version="$2"

  touch "$MICROSH_INSTALLED"

  grep -v "^${app} " "$MICROSH_INSTALLED" >"$MICROSH_INSTALLED.tmp" || true

  echo "$app $version" >>"$MICROSH_INSTALLED.tmp"

  mv "$MICROSH_INSTALLED.tmp" "$MICROSH_INSTALLED"
}

mark_uninstalled() {
  local app="$1"

  [[ -f "$MICROSH_INSTALLED" ]] || return 0

  grep -v "^${app} " "$MICROSH_INSTALLED" >"$MICROSH_INSTALLED.tmp" || true

  mv "$MICROSH_INSTALLED.tmp" "$MICROSH_INSTALLED"
}

add_app_metadata() {
  local app="$1"
  local type="$2"
  local value="$3"

  local metadata

  metadata="$(get_app_metafile "$app")"

  [[ -f "$metadata" ]] || {
    error_print "metadata for '$app' does not exist"
    return 1
  }

  printf '%s=%s\n' "$type" "$value" >>"$metadata"
}

get_app_metafile() {
  local app=$1
  local full_path="$MICROSH_METADATA_DIR/$app"
  [[ -e "$full_path" ]] || touch "$full_path"
  printf "$full_path"
}

create_app_metafile() {
  local app="$1"
  local metafile="$MICROSH_METADATA_DIR/$app"
  [[ -f "$metafile" ]] && {
    rm -f -- "$metafile"
  }
  touch "$metafile"
}
