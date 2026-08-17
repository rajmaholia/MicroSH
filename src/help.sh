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

  microsh help
      Show this help.

  microsh version
      Show MicroSH version.

Examples:

  microsh update

  microsh list

  microsh install Qnote

  microsh install Qnote@1.5.0

  microsh uninstall Qnote

EOF

}
