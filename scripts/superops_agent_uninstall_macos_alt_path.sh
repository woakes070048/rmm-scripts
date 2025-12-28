#!/bin/bash
#
# ██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
# ██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
# ██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
# ██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
# ███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
# ╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
# ================================================================================
#  SCRIPT   : SuperOps Agent Uninstall - Alt Path (macOS)                  v1.1.0
#  AUTHOR   : Limehawk.io
#  DATE     : December 2025
#  USAGE    : sudo ./superops_agent_uninstall_macos_alt_path.sh
# ================================================================================
#  FILE     : superops_agent_uninstall_macos_alt_path.sh
#  DESCRIPTION : Uninstalls SuperOps agent from alternate /Library/limehawk path
# --------------------------------------------------------------------------------
#  README
# --------------------------------------------------------------------------------
#  PURPOSE
#
#    Uninstalls the SuperOps agent from macOS systems by executing the agent's
#    built-in uninstall script from an alternate path (/Library/limehawk).
#
#  DATA SOURCES & PRIORITY
#
#    - Hardcoded path to the uninstall script
#
#  REQUIRED INPUTS
#
#    No inputs required.
#
#  SETTINGS
#
#    Default configuration:
#      - Uninstall script path: /Library/limehawk/uninstall.sh
#
#  BEHAVIOR
#
#    The script performs the following actions in order:
#    1. Executes the uninstall script with sudo privileges
#    2. Reports completion status
#
#  PREREQUISITES
#
#    - The uninstall script must exist at the specified path
#    - The user running the script must have sudo privileges
#
#  SECURITY NOTES
#
#    - This script runs with sudo privileges
#    - Will remove software from the system
#
#  ENDPOINTS
#
#    Not applicable - local system operation only
#
#  EXIT CODES
#
#    0 = Success
#    1 = Failure
#
#  EXAMPLE RUN
#
#    [ OPERATION ]
#    --------------------------------------------------------------
#    Attempting to uninstall SuperOps agent from alternate path...
#
#    [ FINAL STATUS ]
#    --------------------------------------------------------------
#    SuperOps agent uninstallation from alternate path completed.
#
#    [ SCRIPT COMPLETE ]
#    --------------------------------------------------------------
#
# --------------------------------------------------------------------------------
#  CHANGELOG
# --------------------------------------------------------------------------------
#  2025-12-23 v1.1.0 Updated to Limehawk Script Framework
#  2024-11-02 v1.0.0 Initial version, extracted from SuperOps
# ================================================================================

set -e

# ============================================================================
# MAIN EXECUTION
# ============================================================================

echo ""
echo "[ OPERATION ]"
echo "--------------------------------------------------------------"
echo "Attempting to uninstall SuperOps agent from alternate path..."

sudo bash /Library/limehawk/uninstall.sh

echo ""
echo "[ FINAL STATUS ]"
echo "--------------------------------------------------------------"
echo "SuperOps agent uninstallation from alternate path completed."

echo ""
echo "[ SCRIPT COMPLETE ]"
echo "--------------------------------------------------------------"

exit 0
