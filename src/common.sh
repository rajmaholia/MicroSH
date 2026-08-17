error_print() {
  printf '\033[31m%s\033[0m\n' "$*" >&2
}

error() {
  echo "MicroSH: error: $*" >&2
  exit 1
}

info() {
  echo "MicroSH: $*"
}

warning() {
  printf '\033[31m%s\033[0m\n' "$*"
}

require_command() {
  command -v "$1" >/dev/null 2>&1 ||
    error "required command '$1' is not installed"
}

check_dependencies() {
  require_command curl
  require_command jq
  require_command tar
}

download() {
  curl -fL --retry 3 --retry-delay 1 "$1"
}

verify_checksum() {
  local archive="$1"
  local expected="$2"

  [[ -z "$expected" ]] && return 0

  require_command sha256sum

  local actual

  actual="$(sha256sum "$archive" | awk '{print $1}')"

  if [[ "$actual" != "$expected" ]]; then
    error "SHA256 checksum verification failed"
  fi

  info "Checksum verified."
}

extract_archive() {
  local archive="$1"
  local destination="$2"

  case "$archive" in

  *.tar.gz | *.tgz)
    tar -xzf "$archive" -C "$destination"
    ;;

  *.tar.bz2 | *.tbz2)
    tar -xjf "$archive" -C "$destination"
    ;;

  *.tar.xz | *.txz)
    tar -xJf "$archive" -C "$destination"
    ;;

  *.tar)
    tar -xf "$archive" -C "$destination"
    ;;

  *.zip)
    require_command unzip
    unzip -q "$archive" -d "$destination"
    ;;

  *)
    error "unsupported package archive format: $archive"
    ;;

  esac
}
