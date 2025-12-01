#!/bin/bash
set -euo pipefail
# ==============================================================================
# SCRIPT : DietPi Debian 12 VM Installer for Proxmox                     v1.0.0
# FILE   : dietpi_proxmox_install.sh
# ==============================================================================
# PURPOSE:
#   Downloads and runs the DietPi Debian 12 Bookworm VM installer for Proxmox.
#   This creates a lightweight Debian-based VM optimized for low resource usage.
#
# PREREQUISITES:
#   - Proxmox VE host
#   - Run from Proxmox shell (not inside a VM)
#   - Internet access
#
# SOURCE:
#   https://github.com/limehawk/proxmox-scripts
#
# EXIT CODES:
#   0 = Success
#   1 = Failure
#
# CHANGELOG:
#   2024-12-01 v1.0.0  Initial release - migrated from SuperOps
# ==============================================================================

echo ""
echo "[ DIETPI PROXMOX INSTALLER ]"
echo "--------------------------------------------------------------"
echo " Downloading and running DietPi Debian 12 Bookworm installer..."
echo ""

bash <(curl -sSfL https://raw.githubusercontent.com/limehawk/proxmox-scripts/main/scripts/dietpi-bookworm-install.sh)

exit $?
