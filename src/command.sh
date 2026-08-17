# Command resovers
cmd_list() {

  ensure_catalog

  echo
  echo "MicroSH Apps"
  echo "------------"

  jq -r '
    .apps
    | to_entries[]
    | "  \(.key)  \(.value.latest)"
  ' "$MICROSH_CATALOG"

  echo
}

cmd_update() {

  download_catalog

  echo
  echo "Available applications:"
  jq -r '
    .apps
    | to_entries[]
    | "  \(.key)  \(.value.latest)"
  ' "$MICROSH_CATALOG"

  echo
}

cmd_install() {

  local specification="$1"

  local app
  local version
  local latest
  local url
  local checksum

  local temporary_dir
  local archive
  local package_root
  local app_dir
  local installer_json

  # ----------------------------------------------------------
  # Parse:
  #
  #   Qnote
  #   Qnote@1.5.0
  # ----------------------------------------------------------

  if [[ "$specification" == *@* ]]; then
    app="${specification%@*}"
    version="${specification##*@}"

    [[ -n "$app" ]] ||
      error "invalid application name"

    [[ -n "$version" ]] ||
      error "invalid version"

  else
    app="$specification"
    version=""
  fi

  ensure_catalog

  if ! app_exists "$app"; then
    error "application '$app' is not in the microsh catalog"
  fi

  # ----------------------------------------------------------
  # Select version
  # ----------------------------------------------------------

  if [[ -z "$version" ]]; then
    version="$(latest_version "$app")"

    [[ -n "$version" ]] ||
      error "no latest version is defined for '$app'"
  else
    if ! version_exists "$app" "$version"; then
      error "version '$version' of '$app' is not available"
    fi
  fi

  url="$(package_url "$app" "$version")"

  [[ -n "$url" ]] ||
    error "no package URL is defined for '$app' version '$version'"

  checksum="$(package_sha256 "$app" "$version")"

  # ----------------------------------------------------------
  # Already installed?
  #
  # install Qnote
  # install Qnote@1.5.0
  #
  # Both replace the existing installation.
  # ----------------------------------------------------------

  if is_installed "$app"; then
    local current_version

    current_version="$(installed_version "$app")"

    if [[ "$current_version" == "$version" ]]; then
      info "'$app' $version is already installed"
      exit 0
    fi

    info "'$app' $current_version is installed."
    info "Replacing it with '$app' $version..."

    uninstall_app "$app" "$MICROSH_METADATA_DIR"
  fi

  # ----------------------------------------------------------
  # Download
  # ----------------------------------------------------------

  temporary_dir="$(mktemp -d)"

  archive="$temporary_dir/$(basename "${url%%\?*}")"

  # Download the app package
  info "Downloading '$app' $version $url"
  if ! download "$url" >"$archive"; then
    rm -rf "$temporary_dir"
    error "could not download '$app' $version"
  fi

  # Verify checksum
  verify_checksum "$archive" "$checksum"

  # extract
  info "Extracting '$app' $version..."
  mkdir -p "$temporary_dir/extracted"
  extract_archive \
    "$archive" \
    "$temporary_dir/extracted"

  # find package root
  package_root="$(
    find_package_root "$temporary_dir/extracted"
  )" || {
    rm -rf "$temporary_dir"
    error "'$app' package does not contain microsh.json"
  }

  #dependency resolve
  if ! resolve_dependencies "$package_root"; then
    rm -rf "$temporary_dir"
    error "dependency requirements are not satisfied"
  fi

  # write app to disk
  if ! install_app "$app" "$version" "$package_root" "$MICROSH_APPS_DIR" "$XDG_BIN_HOME"; then
    rm -rf "$temporary_dir"
    exit 1
  fi

  # check the bin dir is in path
  check_bin_path

  info "'$app' $version installed."

  rm -rf -- "$temporary_dir"
}

cmd_uninstall() {

  local app="$1"

  ensure_catalog

  if ! is_installed "$app"; then
    info "'$app' is not installed"
    exit 0
  fi

  uninstall_app "$app" "$MICROSH_METADATA_DIR"

  info "'$app' uninstalled."
}

cmd_help() {
  show_help
}
