###############################
# Determine the root in downloaded archive
# #############################
find_package_root() {
  local directory="$1"

  # Normal package layout:
  #
  # package/
  # ├── install.sh
  # └── ...

  if [[ -f "$directory/microsh.json" ]]; then
    echo "$directory"
    return 0
  fi

  # Also support archives containing one top-level directory:
  #
  # package/
  #   Qnote/
  #     install.sh

  local entries=()

  while IFS= read -r -d '' entry; do
    entries+=("$entry")
  done < <(find "$directory" -mindepth 1 -maxdepth 1 -print0)

  if [[ "${#entries[@]}" -eq 1 ]] &&
    [[ -d "${entries[0]}" ]] &&
    [[ -f "${entries[0]}/microsh.json" ]]; then

    echo "${entries[0]}"
    return 0
  fi

  return 1
}

#############################################################
# Installation
# ###########################################################
install_app() {
  local app="$1"
  local app_version="$2"
  local package_root="$3" # temporary file
  local microsh_apps_dir="$4"
  local bin_home="$5"

  local app_dir="$microsh_apps_dir/$app"
  local -a exec_links

  # write app
  [[ -e "$app_dir" ]] && {
    rm -rf "$app_dir"
  }

  if ! cp -a "$package_root/$app" "$app_dir"; then
    rm -rf "$app_dir"
    error_print "could not write the package '$app' to disk."
    return 1
  fi

  # Create links
  if ! create_exec_links "$package_root" "$app" exec_links; then
    rm -rf "$app_dir"
    error_print "could not create executable links for '$app'"
    return 1
  fi

  # Register in microsh.
  create_app_metafile "$app"

  add_app_metadata "$app" "version" "$app_version"

  for link in "${exec_links[@]}"; do
    add_app_metadata "$app" "link" "$link"
  done

  add_app_metadata "$app" "app" "$app_dir"

  mark_installed "$app" "$version"
}

###################################################
# Uninstallation
# #################################################
uninstall_app() {
  local app="$1"
  local microsh_metadata_dir="$2"

  local metafile="$microsh_metadata_dir/$app"
  [[ -e $metafile && -f $metafile ]] || {
    error_print "App Installation metadata is missing."
    return 1
  }

  while IFS='=' read -r type path; do
    case "$type" in
    link)
      rm -- "$path"
      ;;
    app)
      rm -rf -- "$path"
      ;;
    esac
  done <"$metafile"

  rm -- "$metafile"

  mark_uninstalled "$app"
}

#----- ADD entry poins as symlinks
create_exec_links() {
  local package_root="$1"
  local app="$2"
  local -n exec_links_array="$3"

  local manifest="$package_root/microsh.json"
  local app_dir="$MICROSH_APPS_DIR/$app"
  local bin_dir="$XDG_BIN_HOME"

  local name
  local relative_path
  local target
  local link
  local app_exec_path

  exec_links_array=()

  mkdir -p "$bin_dir"

  while IFS=$'\t' read -r name relative_path; do

    [[ -n "$name" ]] || continue
    app_exec_path="${relative_path#*/}"
    target="$app_dir/$app_exec_path"
    link="$bin_dir/$name"

    # ------------------------------------------------------
    # Target must exist
    # ------------------------------------------------------

    if [[ ! -e "$target" && ! -L "$target" ]]; then
      warning \
        "exec target '$app_exec_path' does not exist for '$app'"

      rm -f -- "${exec_links_array[@]}"
      exec_links_array=()
      return 1
    fi

    # ------------------------------------------------------
    # Don't overwrite an existing command/link
    # ------------------------------------------------------

    if [[ -e "$link" || -L "$link" ]]; then
      rm "$link"
      #warning \
      #"cannot create '$link': already exists"

      #rm -f "${created_links[@]}"
      # exec_links_array=()
      # return 1
    fi

    # ------------------------------------------------------
    # Create symlink
    # ------------------------------------------------------

    if ! ln -s "$target" "$link"; then
      warning \
        "could not create executable link '$link'"

      rm -f -- "${exec_links_array[@]}"
      exec_links_array=()
      return 1
    fi

    exec_links_array+=("$link")

    info "Created executable link '$name'"

  done < <(
    jq -r '
            (.exec // {})
            | to_entries[]
            | [.key, .value]
            | @tsv
        ' "$manifest"
  )
  # Return created links through stdout.
  return 0
}

check_bin_path() {
  local bin_dir="$XDG_BIN_HOME"

  case ":$PATH:" in
  *":$bin_dir:"*)
    info "'$bin_dir' is in PATH."
    return 0
    ;;
  esac

  warning "'$bin_dir' is not in PATH."

  echo
  echo "Add it to PATH with:"
  echo
  echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
  echo
  echo "To make it permanent, add the same line to your shell"
  echo "startup configuration (for example ~/.bashrc)."
  echo

  return 0
}
