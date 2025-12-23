#!/bin/bash
#
# ██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
# ██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
# ██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
# ██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
# ███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
# ╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
# ================================================================================
#  SCRIPT   : Set DHCP (macOS)                                             v1.1.0
#  AUTHOR   : Limehawk.io
#  DATE     : December 2024
#  USAGE    : sudo ./network_dhcp_set_macos.sh
# ================================================================================
#  FILE     : network_dhcp_set_macos.sh
# --------------------------------------------------------------------------------
#  README
# --------------------------------------------------------------------------------
#  PURPOSE
#
#    Configures a macOS network interface to use DHCP for automatic IP
#    addressing. Toggles the network service off and on to ensure the new
#    DHCP settings take effect immediately.
#
#  DATA SOURCES & PRIORITY
#
#    - networksetup: macOS network configuration utility
#    - route: Detects primary network interface
#
#  REQUIRED INPUTS
#
#    All inputs are hardcoded in the script body:
#      - INTERFACE: Network interface to configure (leave empty for auto-detect)
#      - TOGGLE_DELAY: Seconds to wait between off/on toggle (default: 2)
#
#  SETTINGS
#
#    Default configuration:
#      - Interface: Auto-detect (falls back to en0)
#      - Toggle delay: 2 seconds
#
#  BEHAVIOR
#
#    The script performs the following actions in order:
#    1. Detects or uses specified network interface
#    2. Gets the network service name for the interface
#    3. Disables the network service
#    4. Sets DHCP on the interface
#    5. Re-enables the network service
#    6. Verifies DHCP configuration
#
#  PREREQUISITES
#
#    - Root/sudo access required
#    - macOS 10.14 or later
#    - networksetup command available
#
#  SECURITY NOTES
#
#    - No secrets exposed in output
#    - Runs with elevated privileges (sudo required)
#    - Temporarily disrupts network connectivity
#
#  ENDPOINTS
#
#    Not applicable - local system configuration only
#
#  EXIT CODES
#
#    0 = Success
#    1 = Failure (not root or interface not found)
#
#  EXAMPLE RUN
#
#    [ INPUT VALIDATION ]
#    --------------------------------------------------------------
#     Running as root          : Yes
#     Interface                : en0 (auto-detected)
#     Network Service          : Wi-Fi
#     Toggle Delay             : 2s
#
#    [ CURRENT CONFIGURATION ]
#    --------------------------------------------------------------
#     Current IP               : 192.168.1.100
#     Current Config           : DHCP Configuration
#
#    [ OPERATION ]
#    --------------------------------------------------------------
#    Disabling network service...
#    Setting DHCP on en0...
#    Enabling network service...
#
#    [ RESULT ]
#    --------------------------------------------------------------
#     Status                   : Success
#     Configuration            : DHCP Configuration
#     IP Address               : 192.168.1.101
#
#    [ SCRIPT COMPLETE ]
#    --------------------------------------------------------------
#
# --------------------------------------------------------------------------------
#  CHANGELOG
# --------------------------------------------------------------------------------
#  2024-12-23 v1.1.0 Updated to Limehawk Script Framework
#  2024-11-01 v1.0.0 Initial release
# ================================================================================

set -e

# ============================================================================
# HARDCODED INPUTS
# ============================================================================
INTERFACE=""  # Leave empty for auto-detect, or set to "en0", "en1", etc.
TOGGLE_DELAY=2
# ============================================================================

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

print_section() {
    echo ""
    echo "[ $1 ]"
    echo "--------------------------------------------------------------"
}

print_kv() {
    printf " %-24s : %s\n" "$1" "$2"
}

# Get network service name for an interface
get_service_for_interface() {
    local iface="$1"
    networksetup -listallhardwareports | awk -v iface="$iface" '
        /Hardware Port:/ { port = substr($0, index($0, ":")+2) }
        /Device:/ && $2 == iface { print port; exit }
    '
}

# Detect primary network interface
detect_primary_interface() {
    # Try to get the default route interface
    local primary
    primary=$(route -n get default 2>/dev/null | awk '/interface:/ {print $2}')

    if [ -n "$primary" ]; then
        echo "$primary"
    else
        # Fall back to en0
        echo "en0"
    fi
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

print_section "INPUT VALIDATION"

# Check for root privileges
if [ "$(id -u)" != "0" ]; then
    echo ""
    echo "[ ERROR OCCURRED ]"
    echo "--------------------------------------------------------------"
    echo "This script must be run with root privileges (sudo)"
    echo ""
    exit 1
fi
print_kv "Running as root" "Yes"

# Determine interface
if [ -z "$INTERFACE" ]; then
    INTERFACE=$(detect_primary_interface)
    print_kv "Interface" "$INTERFACE (auto-detected)"
else
    print_kv "Interface" "$INTERFACE (specified)"
fi

# Get the network service name
SERVICE_NAME=$(get_service_for_interface "$INTERFACE")
if [ -z "$SERVICE_NAME" ]; then
    echo ""
    echo "[ ERROR OCCURRED ]"
    echo "--------------------------------------------------------------"
    echo "Could not find network service for interface $INTERFACE"
    echo ""
    exit 1
fi
print_kv "Network Service" "$SERVICE_NAME"
print_kv "Toggle Delay" "${TOGGLE_DELAY}s"

print_section "CURRENT CONFIGURATION"

# Show current IP configuration
CURRENT_IP=$(ipconfig getifaddr "$INTERFACE" 2>/dev/null || echo "Not configured")
print_kv "Current IP" "$CURRENT_IP"

# Check if already DHCP
CURRENT_CONFIG=$(networksetup -getinfo "$SERVICE_NAME" 2>/dev/null | head -1 || echo "Unknown")
print_kv "Current Config" "$CURRENT_CONFIG"

print_section "OPERATION"

echo "Disabling network service..."
networksetup -setnetworkserviceenabled "$SERVICE_NAME" off
sleep $TOGGLE_DELAY

echo "Setting DHCP on $INTERFACE..."
networksetup -setdhcp "$SERVICE_NAME"
sleep 1

echo "Enabling network service..."
networksetup -setnetworkserviceenabled "$SERVICE_NAME" on
sleep $TOGGLE_DELAY

print_section "RESULT"

# Verify configuration
NEW_CONFIG=$(networksetup -getinfo "$SERVICE_NAME" 2>/dev/null | head -1 || echo "Unknown")
NEW_IP=$(ipconfig getifaddr "$INTERFACE" 2>/dev/null || echo "Acquiring...")

print_kv "Status" "Success"
print_kv "Configuration" "$NEW_CONFIG"
print_kv "IP Address" "$NEW_IP"

print_section "FINAL STATUS"
echo "DHCP has been configured on $SERVICE_NAME ($INTERFACE)."
echo "If IP shows 'Acquiring...', wait a few seconds for DHCP lease."

echo ""
echo "[ SCRIPT COMPLETE ]"
echo "--------------------------------------------------------------"
exit 0
