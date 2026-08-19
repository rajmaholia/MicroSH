dependency_version_satisfies() {
  local version="$1"
  local specification="$2"

  [[ "$specification" == "*" ]] && return 0

  case "$specification" in
  '>='*)
    dpkg --compare-versions \
      "$version" ge "${specification#>=}"
    ;;

  '<='*)
    dpkg --compare-versions \
      "$version" le "${specification#<=}"
    ;;

  '>'*)
    dpkg --compare-versions \
      "$version" gt "${specification#>}"
    ;;

  '<'*)
    dpkg --compare-versions \
      "$version" lt "${specification#<}"
    ;;

  *)
    dpkg --compare-versions \
      "$version" eq "$specification"
    ;;
  esac
}

resolve_dependencies() {
  local package_root="$1"
  local manifest="$package_root/microsh.json"

  local dependency
  local specification
  local status
  local version

  local unresolved=false

  # ----------------------------------------------------------
  # Manifest
  # ----------------------------------------------------------

  if [[ ! -f "$manifest" ]]; then
    warning "package does not contain microsh.json"
    return 1
  fi

  # ----------------------------------------------------------
  # Validate dependencies
  # ----------------------------------------------------------

  if ! jq -e '
        type == "object"
        and (.dependencies // {} | type == "object")
    ' "$manifest" >/dev/null 2>&1; then

    warning "invalid microsh.json: 'dependencies' must be an object"
    return 1
  fi

  # ----------------------------------------------------------
  # Check each dependency
  # ----------------------------------------------------------
  info "Checking dependencies ..."
  while IFS=$'\t' read -r dependency specification; do

    [[ -n "$dependency" ]] || continue

    # Get package status and installed version.
    if ! IFS=$'\t' read -r status version < <(
      dpkg-query \
        -W \
        -f='${Status}\t${Version}\n' \
        "$dependency" 2>/dev/null
    ); then
      warning "'$dependency' is not installed" "✘"
      unresolved=true
      continue
    fi

    # Package may exist in dpkg's database without actually
    # being installed (e.g. config-files state).
    if [[ "$status" != "install ok installed" ]]; then
      warning "'$dependency' is not installed" "✘"
      unresolved=true
      continue
    fi

    # Check version.
    if ! dependency_version_satisfies \
      "$version" \
      "$specification"; then

      warning \
        "'$dependency' '$version' ('$specification')" "✘"

      unresolved=true
      continue
    fi

    info \
      "'$dependency' $version ('$specification')" "✔"

  done < <(
    jq -r '
            (.dependencies // {})
            | to_entries[]
            | [.key, .value]
            | @tsv
        ' "$manifest"
  )

  if [[ "$unresolved" == true ]]; then
    return 1
  fi

  return 0
}
