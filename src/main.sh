# ------------------------------------------------------------
# Main
# ------------------------------------------------------------
main() {
  check_dependencies

  local command="${1:-help}"

  case "$command" in

  list)
    [[ $# -eq 1 ]] ||
      error "usage: microsh list"

    cmd_list
    ;;

  update)
    [[ $# -eq 1 ]] ||
      error "usage: microsh update"

    cmd_update
    ;;

  install)
    [[ $# -eq 2 ]] ||
      error "usage: microsh install <app>[@<version>]"

    cmd_install "$2"
    ;;

  uninstall)
    [[ $# -eq 2 ]] ||
      error "usage: microsh uninstall <app>"

    cmd_uninstall "$2"
    ;;

  help | -h | --help)
    [[ $# -eq 1 ]] ||
      error "usage: microsh help"

    cmd_help
    ;;

  version | -v | --version)
    [[ $# -eq 1 ]] ||
      error "usage: microsh version"

    echo "MicroSH $VERSION"
    ;;

  self-update)
    cmd_selfupdate "${@:2}"
    ;;

  *)
    error "unknown command '$command'. Run 'microsh help'."
    ;;

  esac
}
