#!/bin/bash
#
# ================================================================================
#  SCRIPT   : Splashtop Service Restart (macOS)                           v2.1.0
# ================================================================================
#  FILE     : splashtop_service_restart_macos.sh
# --------------------------------------------------------------------------------
#  README
# --------------------------------------------------------------------------------
#  PURPOSE
#
#    Restarts the Splashtop Streamer service on macOS when remote access
#    becomes unresponsive or connections fail. This is useful for resolving
#    connectivity issues without requiring a full system reboot.
#
#  DATA SOURCES & PRIORITY
#
#    - Local filesystem: Checks for Splashtop launch daemon plist
#    - launchctl: Used to manage the service lifecycle
#
#  REQUIRED INPUTS
#
#    All inputs are hardcoded in the script body:
#      - PLIST_PATH: Path to the Splashtop launch daemon plist file
#
#  SETTINGS
#
#    Service Management:
#      - Plist Path: /Library/LaunchDaemons/com.splashtop.streamer-for-admin.plist
#      - Unload timeout: Immediate (no wait)
#      - Load: Synchronous with error checking
#
#  BEHAVIOR
#
#    The script performs the following actions in order:
#    1. Validates that the plist path is configured
#    2. Verifies the Splashtop launch daemon plist exists
#    3. Unloads the Splashtop service (stops it)
#    4. Reloads the Splashtop service (starts it)
#    5. Reports success or failure
#
#  PREREQUISITES
#
#    - macOS operating system
#    - Root/sudo privileges
#    - Splashtop Streamer installed
#
#  SECURITY NOTES
#
#    - No secrets exposed in output
#    - Requires elevated privileges to manage system services
#    - All operations are local to the machine
#
#  ENDPOINTS
#
#    Not applicable - this script does not connect to any network endpoints
#
#  EXIT CODES
#
#    0 = Success - Splashtop service restarted successfully
#    1 = Failure - service not found or failed to restart
#
#  EXAMPLE RUN
#
#    [ INPUT VALIDATION ]
#    --------------------------------------------------------------
#    All required inputs are valid
#
#    [ SPLASHTOP SERVICE RESTART ]
#    --------------------------------------------------------------
#    Plist Path : /Library/LaunchDaemons/com.splashtop.streamer-for-admin.plist
#
#    [ RESTARTING SERVICE ]
#    --------------------------------------------------------------
#    Stopping Splashtop service...
#    Starting Splashtop service...
#
#    [ FINAL STATUS ]
#    --------------------------------------------------------------
#    Result : SUCCESS
#    Splashtop service restarted successfully
#
#    [ SCRIPT COMPLETE ]
#    --------------------------------------------------------------
#
# --------------------------------------------------------------------------------
#  CHANGELOG
# --------------------------------------------------------------------------------
#  2024-12-23 v2.1.0 Updated to match PowerShell README structure
#  2024-12-23 v2.0.0 Updated to Limehawk Script Framework
#  2024-01-01 v1.0.0 Initial release
# ================================================================================
#
# ================================================================================
#      ██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
#      ██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
#      ██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
#      ██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
#      ███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
#      ╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
# ================================================================================

# ============================================================================
# HARDCODED INPUTS
# ============================================================================
PLIST_PATH="/Library/LaunchDaemons/com.splashtop.streamer-for-admin.plist"
# ============================================================================

# ============================================================================
# INPUT VALIDATION
# ============================================================================
ERROR_OCCURRED=false
ERROR_TEXT=""

if [[ -z "$PLIST_PATH" ]]; then
    ERROR_OCCURRED=true
    ERROR_TEXT="${ERROR_TEXT}\n- Plist path is required"
fi

if [[ "$ERROR_OCCURRED" = true ]]; then
    echo ""
    echo "[ ERROR OCCURRED ]"
    echo "--------------------------------------------------------------"
    echo -e "$ERROR_TEXT"
    echo ""
    exit 1
fi

echo ""
echo "[ INPUT VALIDATION ]"
echo "--------------------------------------------------------------"
echo "All required inputs are valid"

# ============================================================================
# MAIN EXECUTION
# ============================================================================

echo ""
echo "[ SPLASHTOP SERVICE RESTART ]"
echo "--------------------------------------------------------------"
echo "Plist Path : $PLIST_PATH"

# Check if plist exists
if [[ ! -f "$PLIST_PATH" ]]; then
    echo ""
    echo "[ ERROR OCCURRED ]"
    echo "--------------------------------------------------------------"
    echo "Splashtop launch daemon not found"
    echo "Expected : $PLIST_PATH"
    echo "Is Splashtop Streamer installed?"
    echo ""
    exit 1
fi

echo ""
echo "[ RESTARTING SERVICE ]"
echo "--------------------------------------------------------------"

# Stop service
echo "Stopping Splashtop service..."
launchctl unload "$PLIST_PATH" 2>/dev/null || true

# Start service
echo "Starting Splashtop service..."
if ! launchctl load "$PLIST_PATH"; then
    echo ""
    echo "[ ERROR OCCURRED ]"
    echo "--------------------------------------------------------------"
    echo "Failed to start Splashtop service"
    echo "The launch daemon could not be loaded"
    echo ""
    exit 1
fi

echo ""
echo "[ FINAL STATUS ]"
echo "--------------------------------------------------------------"
echo "Result : SUCCESS"
echo "Splashtop service restarted successfully"

echo ""
echo "[ SCRIPT COMPLETE ]"
echo "--------------------------------------------------------------"
exit 0
