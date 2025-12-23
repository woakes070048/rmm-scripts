#!/bin/bash
#
# ============================================================================
#                    SPLASHTOP SERVICE RESTART (MACOS)
# ============================================================================
#  Script Name: splashtop_service_restart_macos.sh
#  Description: Restarts the Splashtop Streamer service on macOS by unloading
#               and reloading the launch daemon.
#  Author:      Limehawk LLC
#  Version:     2.0.0
#  Date:        December 2024
#  Usage:       sudo ./splashtop_service_restart_macos.sh
# ============================================================================
#
# ============================================================================
#      ██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
#      ██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
#      ██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
#      ██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
#      ███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
#      ╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
# ============================================================================
#
#  PURPOSE
#  -----------------------------------------------------------------------
#  Restarts the Splashtop Streamer service on macOS when remote access
#  becomes unresponsive or connections fail. This is useful for resolving
#  connectivity issues without requiring a full system reboot.
#
#  CONFIGURATION
#  -----------------------------------------------------------------------
#  - PLIST_PATH: Path to the Splashtop launch daemon plist file
#
#  BEHAVIOR
#  -----------------------------------------------------------------------
#  1. Verifies the Splashtop launch daemon plist exists
#  2. Unloads the Splashtop service (stops it)
#  3. Reloads the Splashtop service (starts it)
#  4. Reports success or failure
#
#  PREREQUISITES
#  -----------------------------------------------------------------------
#  - macOS operating system
#  - Root/sudo privileges
#  - Splashtop Streamer installed
#
#  SECURITY NOTES
#  -----------------------------------------------------------------------
#  - No secrets exposed in output
#  - Requires elevated privileges to manage system services
#
#  EXIT CODES
#  -----------------------------------------------------------------------
#  0 - Success
#  1 - Failure (service not found or failed to restart)
#
#  EXAMPLE OUTPUT
#  -----------------------------------------------------------------------
#  === SPLASHTOP SERVICE RESTART ===
#  --------------------------------------------------------------
#  Plist Path: /Library/LaunchDaemons/com.splashtop.streamer-for-admin.plist
#
#  === RESTARTING SERVICE ===
#  --------------------------------------------------------------
#  Stopping Splashtop service...
#  Starting Splashtop service...
#
#  === RESULT ===
#  --------------------------------------------------------------
#  Status: SUCCESS
#  Splashtop service restarted successfully
#
#  === SCRIPT COMPLETE ===
#
#  CHANGELOG
#  -----------------------------------------------------------------------
#  2024-12-23 v2.0.0 Updated to Limehawk Script Framework
#  2024-01-01 v1.0.0 Initial release
#
# ============================================================================

# ============================================================================
# CONFIGURATION SETTINGS
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
    echo "=== ERROR OCCURRED ==="
    echo "--------------------------------------------------------------"
    echo -e "$ERROR_TEXT"
    echo ""
    exit 1
fi

# ============================================================================
# MAIN EXECUTION
# ============================================================================

echo ""
echo "=== SPLASHTOP SERVICE RESTART ==="
echo "--------------------------------------------------------------"
echo "Plist Path: $PLIST_PATH"

# Check if plist exists
if [[ ! -f "$PLIST_PATH" ]]; then
    echo ""
    echo "=== ERROR OCCURRED ==="
    echo "--------------------------------------------------------------"
    echo "Splashtop launch daemon not found"
    echo "Expected: $PLIST_PATH"
    echo "Is Splashtop Streamer installed?"
    echo ""
    exit 1
fi

echo ""
echo "=== RESTARTING SERVICE ==="
echo "--------------------------------------------------------------"

# Stop service
echo "Stopping Splashtop service..."
launchctl unload "$PLIST_PATH" 2>/dev/null || true

# Start service
echo "Starting Splashtop service..."
if ! launchctl load "$PLIST_PATH"; then
    echo ""
    echo "=== ERROR OCCURRED ==="
    echo "--------------------------------------------------------------"
    echo "Failed to start Splashtop service"
    echo "The launch daemon could not be loaded"
    echo ""
    exit 1
fi

echo ""
echo "=== RESULT ==="
echo "--------------------------------------------------------------"
echo "Status: SUCCESS"
echo "Splashtop service restarted successfully"

echo ""
echo "=== SCRIPT COMPLETE ==="
echo "--------------------------------------------------------------"
exit 0
