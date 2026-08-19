error() {
  local prefix="${2:-}"
  if [[ -n "$prefix" ]]; then
    error_print "$1" "$prefix"
  else
    error_print "$1"
  fi
  exit 1
}

info() {
  local message="$1"
  local prefix="${2:-}"

  if [[ -n "$prefix" ]]; then
    printf '[%s] %s\n' "$prefix" "$message"
  else
    printf '%s\n' "$message"
  fi
}

warning() {
  local message="$1"
  local prefix="${2:-}"

  if [[ -n "$prefix" ]]; then
    printf '\e[33m[%s] %s\e[0m \n' "$prefix" "$message"
  else
    printf '\e[33m%s\e[0m\n' "$message"
  fi
}

error_print() {
  local message="$1"
  local prefix="${2:-}"

  if [[ -n "$prefix" ]]; then
    printf '\e[31m[%s] %s\e[0m\n' "$prefix" "$message" || return 0
  else
    printf '\e[31m%s\e[0m\n' "$message" || return 0
  fi
  return 0
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

is_archive() {
  [[ "$1" =~ \.(tar\.gz|tgz|tar\.bz2|tbz2|tar\.xz|txz|tar|zip)$ ]]
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
