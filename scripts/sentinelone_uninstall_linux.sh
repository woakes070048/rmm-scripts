#!/bin/bash
#
# ██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
# ██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
# ██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
# ██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
# ███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
# ╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
# ================================================================================
#  SCRIPT   : SentinelOne Agent Uninstall (Linux)                          v1.1.0
#  AUTHOR   : Limehawk.io
#  DATE     : December 2024
#  USAGE    : sudo ./sentinelone_uninstall_linux.sh
# ================================================================================
#  FILE     : sentinelone_uninstall_linux.sh
# --------------------------------------------------------------------------------
#  README
# --------------------------------------------------------------------------------
#  PURPOSE
#
#    Uninstalls the SentinelOne agent from Linux systems using the sentinelctl
#    command. Verifies the agent is installed before attempting removal.
#
#  DATA SOURCES & PRIORITY
#
#    - sentinelctl: SentinelOne command-line utility
#
#  REQUIRED INPUTS
#
#    No hardcoded inputs required.
#
#  SETTINGS
#
#    Default configuration:
#      - Uses sentinelctl uninstall command
#
#  BEHAVIOR
#
#    The script performs the following actions in order:
#    1. Verifies root privileges
#    2. Checks if sentinelctl command is available
#    3. Runs sentinelctl uninstall
#    4. Reports success or failure
#
#  PREREQUISITES
#
#    - Linux system with SentinelOne agent installed
#    - Root/sudo privileges
#    - sentinelctl must be in PATH (/usr/local/bin or /opt/sentinelone/bin)
#
#  SECURITY NOTES
#
#    - No secrets exposed in output
#    - Requires elevated privileges for uninstall
#    - Agent may have tamper protection enabled
#
#  ENDPOINTS
#
#    Not applicable - local system operation only
#
#  EXIT CODES
#
#    0 = Success (agent uninstalled)
#    1 = Failure (not root, sentinelctl not found, or uninstall failed)
#
#  EXAMPLE RUN
#
#    [ SENTINELONE UNINSTALL ]
#    --------------------------------------------------------------
#    Starting SentinelOne agent uninstallation...
#
#    Permissions : root
#
#    sentinelctl found : yes
#
#    Running uninstall command...
#
#    [ FINAL STATUS ]
#    --------------------------------------------------------------
#    Result : SUCCESS
#    SentinelOne agent uninstalled successfully
#
#    [ SCRIPT COMPLETE ]
#    --------------------------------------------------------------
#
# --------------------------------------------------------------------------------
#  CHANGELOG
# --------------------------------------------------------------------------------
#  2024-12-23 v1.1.0 Updated to Limehawk Script Framework
#  2024-01-01 v1.0.0 Initial release
# ================================================================================

set -e

# ============================================================================
# MAIN EXECUTION
# ============================================================================

echo ""
echo "[ SENTINELONE UNINSTALL ]"
echo "--------------------------------------------------------------"
echo "Starting SentinelOne agent uninstallation..."
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo ""
    echo "[ ERROR OCCURRED ]"
    echo "--------------------------------------------------------------"
    echo "This script must be run as root"
    echo ""
    echo "Troubleshooting:"
    echo "- Run with: sudo $0"
    echo "- Or run from RMM with root/sudo privileges"
    echo ""
    exit 1
fi

echo "Permissions : root"
echo ""

# Check if sentinelctl exists
if ! command -v sentinelctl &> /dev/null; then
    echo ""
    echo "[ ERROR OCCURRED ]"
    echo "--------------------------------------------------------------"
    echo "sentinelctl command not found"
    echo ""
    echo "Troubleshooting:"
    echo "- SentinelOne agent may not be installed"
    echo "- sentinelctl should be in /usr/local/bin or /opt/sentinelone/bin"
    echo ""
    exit 1
fi

echo "sentinelctl found : yes"
echo ""

# Uninstall SentinelOne agent
echo "Running uninstall command..."
if sudo sentinelctl uninstall; then
    echo ""
    echo "[ FINAL STATUS ]"
    echo "--------------------------------------------------------------"
    echo "Result : SUCCESS"
    echo "SentinelOne agent uninstalled successfully"
    echo ""
    echo "[ SCRIPT COMPLETE ]"
    echo "--------------------------------------------------------------"
    exit 0
else
    echo ""
    echo "[ ERROR OCCURRED ]"
    echo "--------------------------------------------------------------"
    echo "SentinelOne uninstall failed"
    echo ""
    echo "Troubleshooting:"
    echo "- Check if agent is protected by tamper protection"
    echo "- Verify sentinelctl has proper permissions"
    echo "- Review system logs for details"
    echo ""
    exit 1
fi
