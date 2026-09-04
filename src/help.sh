show_help() {
  cat <<EOF

MicroSH $VERSION

Tiny Linux application manager.

Usage:

  microsh list
      List applications and their latest versions.

  microsh update
      Update the local application catalog.

  microsh install <app>
      Install the latest version of an application.

  microsh install <app>@<version>
      Install a specific available version.

  microsh uninstall <app>
      Uninstall an application.

  microsh self-update
      Update MicroSH to the latest version.

  microsh self-update -l|--list
      List available MicroSH versions.

  microsh self-update -c|--check
      Check for a newer MicroSH version.

  microsh self-update -v|--version <version>
      Install a specific MicroSH version.

  microsh help|-h
      Show this help.

  microsh version|-v
      Show MicroSH version.

Examples:

  microsh update

  microsh list

  microsh install Qnote

  microsh install Qnote@1.5.0

  microsh uninstall Qnote

  microsh self-update

  microsh self-update --check

  microsh self-update --version 2.2.0

EOF
}
