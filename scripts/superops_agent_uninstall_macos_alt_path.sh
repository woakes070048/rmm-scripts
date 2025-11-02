#!/bin/bash

#
# ██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
# ██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
# ██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
# ██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
# ███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
# ╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
# ================================================================================
#  SCRIPT    : superops_uninstall_macos_alt_path.sh
#  VERSION   : 1.0.0
# ================================================================================
#  README
# --------------------------------------------------------------------------------
#  PURPOSE
#    Uninstalls the SuperOps agent from macOS systems by executing the agent's
#    built-in uninstall script from an alternate path.
#
#  DATA SOURCES & PRIORITY
#    - Hardcoded path to the uninstall script.
#
#  REQUIRED INPUTS
#    - None.
#
#  SETTINGS
#    - None.
#
#  BEHAVIOR
#    - Executes the uninstall script with sudo privileges.
#
#  PREREQUISITES
#    - The uninstall script must exist at the specified path.
#    - The user running the script must have sudo privileges.
#
#  SECURITY NOTES
#    - This script runs with sudo privileges and will remove software from the system.
#
#  ENDPOINTS
#    - None.
#
#  EXIT CODES
#    - 0: Success
#    - 1: Failure
#
#  EXAMPLE OUTPUT
#    [ OPERATION ]
#    Attempting to uninstall SuperOps agent from alternate path...
#    [ FINAL STATUS ]
#    SuperOps agent uninstallation from alternate path completed.
# --------------------------------------------------------------------------------
#  CHANGELOG
# --------------------------------------------------------------------------------
#  v1.0.0 (2025-11-02) - Initial version, extracted from SuperOps.
#

set -e

echo "[ OPERATION ]"
echo "Attempting to uninstall SuperOps agent from alternate path..."
sudo bash /Library/limehawk/uninstall.sh
echo "[ FINAL STATUS ]"
echo "SuperOps agent uninstallation from alternate path completed."

exit 0