#!/bin/bash
#
# ██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
# ██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
# ██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
# ██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
# ███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
# ╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
# ================================================================================
#  SCRIPT   : DietPi Debian 12 VM Installer for Proxmox                    v1.1.0
#  AUTHOR   : Limehawk.io
#  DATE     : December 2025
#  USAGE    : ./dietpi_proxmox_install.sh
# ================================================================================
#  FILE     : dietpi_proxmox_install.sh
#  DESCRIPTION : Creates lightweight DietPi Debian 12 VM on Proxmox
# --------------------------------------------------------------------------------
#  README
# --------------------------------------------------------------------------------
#  PURPOSE
#
#    Downloads and runs the DietPi Debian 12 Bookworm VM installer for Proxmox.
#    This creates a lightweight Debian-based VM optimized for low resource usage.
#
#  DATA SOURCES & PRIORITY
#
#    - GitHub: Downloads installer from limehawk/proxmox-scripts repository
#
#  REQUIRED INPUTS
#
#    No hardcoded inputs required - installer is fetched from remote source.
#
#  SETTINGS
#
#    - Source URL: https://raw.githubusercontent.com/limehawk/proxmox-scripts/main/scripts/dietpi-bookworm-install.sh
#
#  BEHAVIOR
#
#    The script performs the following actions in order:
#    1. Downloads the DietPi installer script from GitHub
#    2. Executes the installer via bash
#    3. Returns the exit code from the installer
#
#  PREREQUISITES
#
#    - Proxmox VE host
#    - Run from Proxmox shell (not inside a VM)
#    - Internet access to GitHub
#    - curl installed
#
#  SECURITY NOTES
#
#    - No secrets exposed in output
#    - Script is fetched over HTTPS
#    - Executes remote code - review source before running
#
#  ENDPOINTS
#
#    - https://raw.githubusercontent.com/limehawk/proxmox-scripts/main/scripts/dietpi-bookworm-install.sh
#
#  EXIT CODES
#
#    0 = Success
#    1 = Failure (from remote installer)
#
#  EXAMPLE RUN
#
#    [ DIETPI PROXMOX INSTALLER ]
#    --------------------------------------------------------------
#    Downloading and running DietPi Debian 12 Bookworm installer...
#
#    (installer output follows)
#
# --------------------------------------------------------------------------------
#  CHANGELOG
# --------------------------------------------------------------------------------
#  2025-12-23 v1.1.0 Updated to Limehawk Script Framework
#  2024-12-01 v1.0.0 Initial release - migrated from SuperOps
# ================================================================================

set -euo pipefail

# ============================================================================
# MAIN EXECUTION
# ============================================================================

echo ""
echo "[ DIETPI PROXMOX INSTALLER ]"
echo "--------------------------------------------------------------"
echo "Downloading and running DietPi Debian 12 Bookworm installer..."
echo ""

bash <(curl -sSfL https://raw.githubusercontent.com/limehawk/proxmox-scripts/main/scripts/dietpi-bookworm-install.sh)

exit $?
