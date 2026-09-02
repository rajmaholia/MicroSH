#############################################################
# Installation
# ###########################################################
install_from_remote() {
  local specification="$1"
  local app
  local version
  local latest
  local url
  local checksum
  local temporary_dir
  local temp_archive

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
    local current_version="$(installed_version "$app")"

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

  temp_archive="$temporary_dir/$(basename "${url%%\?*}")"

  # Download the app package
  info "Downloading $url ..."
  if ! download "$url" >"$temp_archive"; then
    rm -rf "$temporary_dir"
    error "Download failed."
  fi

  # Verify checksum
  verify_checksum "$temp_archive" "$checksum"
  install_from_archive "$temp_archive" || {
    rm -rf -- "$temporary_dir"
    return 1
  }
  rm -rf -- "$temporary_dir"
}

install_from_archive() {
  local archive="$1"
  local temporary_dir="$(mktemp -d)"
  local archive_basename="$(basename "$archive")"
  # extract
  info "Extracting $archive_basename ..."

  extract_archive "$archive" "$temporary_dir" || {
    rm -rf -- "$temporary_dir"
    error_print "Extraction failed." && return 1
  }

  install_from_package "$temporary_dir" || {
    rm -rf -- "$temporary_dir"
    error_print "Installation failed." && return 1
  }
  rm -rf -- "$temporary_dir"
}

install_from_package() {
  local package="$1"
  local package_root package_payload manifest
  local id name version

  # find package root
  package_root="$(
    find_package_root "$package"
  )" || {
    error_print "Package does not contain microsh.json" && return 1
  }

  manifest="$package_root/microsh.json"
  if ! validate_manifest "$manifest"; then
    error_print "Invalid microsh.json." && return 1
  fi
  package_payload="$(get_package_payload "$package_root")" || {
    error_print "Package must contain exactly one payload directory" && return 1
  }

	id="$(jq -r '.id' "$manifest")"
	name="$(jq -r '.name' "$manifest")"
	version="$(jq -r '.version' "$manifest")"

  #dependency resolve
  if ! resolve_dependencies "$package_root"; then
    error_print "Dependency requirements are not satisfied" && return 1
  fi
  # installation and setup on disk
  if ! install_app "$id" "$version" "$package_root" "$package_payload" "$MICROSH_APPS_DIR" "$XDG_BIN_HOME"; then
    return 1
  fi
}

install_app() {
  local app_id="$1"
  local app_version="$2"
  local package_root="$3"
  local package_payload="$4"
  local microsh_apps_dir="$5"
  local bin_home="$6"

  local app_dir="$microsh_apps_dir/$app_id"
  local -a exec_links

  # write app
  [[ -e "$app_dir" ]] && {
    rm -rf "$app_dir"
  }

  if ! cp -a "$package_payload" "$app_dir"; then
    rm -rf "$app_dir"
    error_print "Could not write the package '$app_id' to disk." && return 1
  fi

  # Create links
  if ! create_exec_links "$package_root" "$app_id" exec_links; then
    rm -rf "$app_dir"
    error_print "Could not create executable links for '$app_id'" && return 1
  fi

  ###### Register in microsh.

  create_app_metafile "$app_id"
  add_app_metadata "$app_id" "version" "$app_version"

  # Register exectable symlinks
  for link in "${exec_links[@]}"; do
    add_app_metadata "$app_id" "link" "$link"
  done
  # Register installation dir
  add_app_metadata "$app_id" "app" "$app_dir"

  mark_installed "$app_id" "$app_version"

  info "'$app_id' $app_version installed."
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
      rm -f -- "$path"
      ;;
    app)
      rm -rf -- "$path"
      ;;
    esac
  done <"$metafile"

  rm -f -- "$metafile"

  mark_uninstalled "$app"
  hash -r
}

#################################################
# Installation Helpers
# ###############################################

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

  info "Creating exectable links..."
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

    info "$name" "*"

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

get_package_payload() {
  local root="$1"
  local dir
  local count

  count="$(find "$root" -mindepth 1 -maxdepth 1 -type d ! -name '.*' | wc -l)"
  [[ "$count" -eq 1 ]] || return 1

  dir="$(find "$root" -mindepth 1 -maxdepth 1 -type d ! -name '.*' -print -quit)"
  printf '%s\n' "$dir"
}
