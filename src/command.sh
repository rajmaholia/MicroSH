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
  local target="${1:-}"

  if [[ -z "$target" ]]; then
    error "missing package"
  fi

  if [[ -d "$target" ]]; then
    install_from_package "$target"
    return $?
  fi

  if [[ -f "$target" ]]; then
    if is_archive "$target"; then
      install_from_archive "$target"
    else
      install_from_package "$target"
    fi

    return $?
  fi

  install_from_remote "$target"
  # check the bin dir is in path
  check_bin_path
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

cmd_selfupdate() {
  self_update "$@"
}
