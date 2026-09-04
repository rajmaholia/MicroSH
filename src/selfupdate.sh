self_update() {
  local option="${1:-latest}" release microsh_binary microsh_checksum tmp target_binary
  local latest_tag_name latest_version specified_version release_json

  case "$option" in
  -v | --version)
    [[ $# -ne 2 ]] && error "Please specify a version x.x.x"
    specified_version="$2"
    install "$specified_version"
    ;;

  -l | --list)
    echo "All available versions: "
    get_all_versions || error "Unable to get available versions info."
    ;;

  -c | --check)
    echo "Checking for updates..."
    latest_version="$(get_latest_version)" || error "Unable to get the latest version info."

    if [[ "$latest_version" == "$VERSION" ]]; then
      echo "Already Up to date: MicroSH v$VERSION"
    elif version_gt "$VERSION" "$latest_version"; then
      printf 'Local MicroSH v%s is newer than remote v%s\n' "$VERSION" "$latest_version"
    else
      echo "Update available: MicroSH v$latest_version"
    fi
    ;;

  latest)
    info "Checking for updates..."
    latest_version="$(get_latest_version)" || error "Unable to get the latest version info."
    [[ "$latest_version" == "$VERSION" ]] && {
      info "Already up to date." && exit 0
    }
    install "$latest_version"
    ;;

  *)
    echo "Invalid self-update option: $option"
    ;;
  esac
}

install() {
  specified_version="$1"
  version_exists_verbose "$specified_version" || exit 1

  info "Getting version info for 'MicroSH $specified_version' ..."
  release_json="$(curl -fsSL \
    "$MICROSH_RELEASE_API/tags/v$specified_version" 2>/dev/null)" || error "Unable to get version info. Check your connection."

  microsh_binary="$(
    jq -r '.assets[] | select(.name == "microsh") | .browser_download_url' \
      <<<"$release_json"
  )"
  #microsh_checksum="$(
  #  jq -r '.assets[] | select(.name == "microsh.sha256") | .browser_download_url' \
  #    <<<"$release_json"
  #)"

  target_binary="$(readlink -f -- "${BASH_SOURCE[0]}")" || return 1
  tmp="$(mktemp)" || return 1
  echo "Downloading Microsh $specified_version ..."
  curl -fsSL "$microsh_binary" -o "$tmp" 2>/dev/null
  #curl -fsSL "$microsh_checksum" | sed "s|microsh|$tmp|" | sha256sum -c - >/dev/null
  printf "Installing MicroSH $specified_version ..."
  chmod --reference="$target_binary" "$tmp" &&
    mv -f "$tmp" "$target_binary"
  local rc=$?
  if ((rc == 0)); then
    printf "DONE\n"
  else
    rm -f "$tmp"
    error "Failed"
  fi
}

get_latest_version() {
  local curl_result latest_tag_name latest version
  curl_result="$(curl -fsSL "$MICROSH_RELEASE_API/latest" 2>/dev/null)" || return 1
  latest_tag_name="$(printf "%s\n" "$curl_result" | jq -r '.tag_name')"
  latest_version="${latest_tag_name#v}" || return 1
  printf "%s" "$latest_version"
}

get_all_versions() {
  local curl_result
  curl_result="$(curl -fsSL "$MICROSH_RELEASE_API?per_page=100" 2>/dev/null)" || {
    return 1
  }
  printf "%s\n" "$curl_result" | jq -r '[.[].tag_name | ltrimstr("v")] | join(", ")' 2>/dev/null || return 1
}

version_exists() {
  local versions
  versions="$(get_all_versions)" || return 1
  local version="$1"
  [[ ", $versions," == *", $version,"* ]]
}

version_exists_verbose() {
  local versions
  versions="$(get_all_versions)" || {
    error_print "Unable to fetch available versions info for MicroSH."
    return 1
  }

  local version="$1"
  [[ ", $versions," == *", $version,"* ]] || {
    error_print "Specified version '$version' doesn't exist."
    printf "Available versions : %s\n" "$versions"
    return 1
  }
}

version_gt() { [[ "$1" != "$2" && "$(printf '%s\n' "$1" "$2" | sort -V | tail -n1)" == "$1" ]]; }
