#!/bin/bash
#
# ██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
# ██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
# ██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
# ██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
# ███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
# ╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
# ================================================================================
#  SCRIPT   : Toggle CUPS Web Interface                                    v1.1.1
#  AUTHOR   : Limehawk.io
#  DATE     : January 2026
#  USAGE    : sudo ./cups_toggle_macos.sh
# ================================================================================
#  FILE     : cups_toggle_macos.sh
#  DESCRIPTION : Toggles CUPS web interface on/off for printer administration
# --------------------------------------------------------------------------------
#  README
# --------------------------------------------------------------------------------
#  PURPOSE
#
#    Toggles the CUPS (Common Unix Printing System) web interface on or off.
#    If currently enabled, disables it. If disabled, enables it. Useful for
#    managing printer administration access on macOS and Linux systems.
#
#  DATA SOURCES & PRIORITY
#
#    - cupsctl: Queries current CUPS configuration
#    - System CUPS service: Reads and writes web interface settings
#
#  REQUIRED INPUTS
#
#    No hardcoded inputs required - script auto-detects current state.
#
#  SETTINGS
#
#    - Web Interface URL (when enabled): http://localhost:631
#
#  BEHAVIOR
#
#    The script performs the following actions in order:
#    1. Verifies root/sudo privileges
#    2. Checks current CUPS web interface status via cupsctl
#    3. If disabled, enables the web interface
#    4. If enabled, disables the web interface
#    5. Reports the new status
#
#  PREREQUISITES
#
#    - macOS or Linux with CUPS installed
#    - cupsctl command available
#    - Root/sudo privileges
#
#  SECURITY NOTES
#
#    - No secrets exposed in output
#    - Requires elevated privileges to modify system settings
#    - Enabling web interface exposes printer admin on localhost:631
#
#  ENDPOINTS
#
#    - http://localhost:631 - CUPS web interface (when enabled)
#
#  EXIT CODES
#
#    0 = Success
#    1 = Failure (not running as root)
#
#  EXAMPLE RUN
#
#    [RUN] CUPS WEB INTERFACE TOGGLE
#    ==============================================================
#    Current Status : Disabled
#    Action         : Enabling
#    Result         : ENABLED
#
#    CUPS Web Interface URL: http://localhost:631
#
#    [OK] SCRIPT COMPLETED
#    ==============================================================
#
# --------------------------------------------------------------------------------
#  CHANGELOG
# --------------------------------------------------------------------------------
#  2026-01-19 v1.1.1 Updated to two-line ASCII console output style
#  2025-12-23 v1.1.0 Updated to Limehawk Script Framework
#  2024-01-01 v1.0.0 Initial release
# ================================================================================

set -euo pipefail

# ============================================================================
# MAIN EXECUTION
# ============================================================================

echo ""
echo "[RUN] CUPS WEB INTERFACE TOGGLE"
echo "=============================================================="

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo ""
    echo "[ERROR] ERROR OCCURRED"
    echo "=============================================================="
    echo "This script must be run as root"
    echo "Usage: sudo ./cups_toggle_macos.sh"
    echo ""
    exit 1
fi

# Check current status
web_interface_status=$(cupsctl | grep 'WebInterface=no' || true)

if [[ -n "$web_interface_status" ]]; then
    # Web interface is disabled, enable it
    echo "Current Status : Disabled"
    echo "Action         : Enabling"
    cupsctl WebInterface=yes
    echo "Result         : ENABLED"
    echo ""
    echo "CUPS Web Interface URL: http://localhost:631"
else
    # Web interface is enabled, disable it
    echo "Current Status : Enabled"
    echo "Action         : Disabling"
    cupsctl WebInterface=no
    echo "Result         : DISABLED"
fi

echo ""
echo "[OK] SCRIPT COMPLETED"
echo "=============================================================="
exit 0
