#!/bin/bash
#
# ██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
# ██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
# ██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
# ██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
# ███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
# ╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
# ================================================================================
#  SCRIPT   : Network Service Refresh (macOS)                              v1.1.1
#  AUTHOR   : Limehawk.io
#  DATE     : January 2026
#  USAGE    : sudo ./network_service_refresh_macos.sh
# ================================================================================
#  FILE     : network_service_refresh_macos.sh
#  DESCRIPTION : Refreshes all macOS network services by toggling them off and on
# --------------------------------------------------------------------------------
#  README
# --------------------------------------------------------------------------------
#  PURPOSE
#
#    Refreshes all network services on macOS by toggling them off and on.
#    Preserves the original enabled/disabled state of each service.
#    Useful for resolving DHCP lease issues, DNS problems, or general
#    network connectivity problems without requiring a full system restart.
#
#  DATA SOURCES & PRIORITY
#
#    - networksetup: macOS network configuration utility
#
#  REQUIRED INPUTS
#
#    All inputs are hardcoded in the script body:
#      - TOGGLE_DELAY: Seconds to wait between off/on toggle (default: 2)
#
#  SETTINGS
#
#    Default configuration:
#      - Toggle delay: 2 seconds
#      - Preserves original enabled/disabled state of each service
#
#  BEHAVIOR
#
#    The script performs the following actions in order:
#    1. Lists all network services
#    2. For each service:
#       a. Records initial enabled/disabled state
#       b. Disables the service
#       c. Waits briefly
#       d. Enables the service
#       e. Restores original state if it was disabled
#    3. Reports final status
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
#    1 = Failure (not root or no network services found)
#
#  EXAMPLE RUN
#
#    [INFO] INPUT VALIDATION
#    ==============================================================
#     Toggle Delay             : 2s
#     Running as root          : Yes
#
#    [INFO] NETWORK SERVICES
#    ==============================================================
#    Found 3 network service(s)
#
#    [RUN] OPERATION
#    ==============================================================
#    Processing: Wi-Fi
#      Toggling 'Wi-Fi' off...
#      Toggling 'Wi-Fi' on...
#    Processing: Ethernet
#      Toggling 'Ethernet' off...
#      Toggling 'Ethernet' on...
#
#    [INFO] RESULT
#    ==============================================================
#     Status                   : Success
#     Services Processed       : 3
#
#    [OK] SCRIPT COMPLETED
#    ==============================================================
#
# --------------------------------------------------------------------------------
#  CHANGELOG
# --------------------------------------------------------------------------------
#  2026-01-19 v1.1.1 Updated to two-line ASCII console output style
#  2025-12-23 v1.1.0 Updated to Limehawk Script Framework
#  2024-11-01 v1.0.0 Initial release
# ================================================================================

set -e

# ============================================================================
# HARDCODED INPUTS
# ============================================================================
TOGGLE_DELAY=2
# ============================================================================

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

print_section() {
    local status="$1"
    local title="$2"
    echo ""
    echo "[$status] $title"
    echo "=============================================================="
}

print_kv() {
    printf " %-24s : %s\n" "$1" "$2"
}

# Toggle a network service off and on, then restore its original state
toggle_network_service() {
    local service="$1"
    local initial_state="$2"

    echo "  Toggling '$service' off..."
    networksetup -setnetworkserviceenabled "$service" off
    sleep $TOGGLE_DELAY

    echo "  Toggling '$service' on..."
    networksetup -setnetworkserviceenabled "$service" on

    # Restore the initial state if it was disabled
    if [ "$initial_state" = "Disabled" ]; then
        echo "  Restoring '$service' to Disabled state..."
        networksetup -setnetworkserviceenabled "$service" off
    fi
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

print_section "INFO" "INPUT VALIDATION"
print_kv "Toggle Delay" "${TOGGLE_DELAY}s"

# Check for root privileges
if [ "$(id -u)" != "0" ]; then
    echo ""
    echo "[ERROR] ERROR OCCURRED"
    echo "=============================================================="
    echo "This script must be run with root privileges (sudo)"
    echo ""
    exit 1
fi
print_kv "Running as root" "Yes"

print_section "INFO" "NETWORK SERVICES"

# Get the list of network services (skip the header line)
network_services=$(networksetup -listallnetworkservices | tail -n +2)

if [ -z "$network_services" ]; then
    echo ""
    echo "[ERROR] ERROR OCCURRED"
    echo "=============================================================="
    echo "No network services found"
    echo ""
    exit 1
fi

# Count services
service_count=$(echo "$network_services" | wc -l | tr -d ' ')
echo "Found $service_count network service(s)"

print_section "RUN" "OPERATION"

# Iterate over each network service
processed=0
while IFS= read -r service; do
    # Skip empty lines
    [ -z "$service" ] && continue

    echo "Processing: $service"

    # Get initial state
    initial_state=$(networksetup -getnetworkserviceenabled "$service" 2>/dev/null || echo "Unknown")

    # Toggle the service
    toggle_network_service "$service" "$initial_state"

    ((processed++))
done <<< "$network_services"

print_section "INFO" "RESULT"
print_kv "Status" "Success"
print_kv "Services Processed" "$processed"

print_section "INFO" "FINAL STATUS"
echo "Network services have been refreshed."
echo ""
echo "Current network service status:"
networksetup -listallnetworkservices

echo ""
echo "[OK] SCRIPT COMPLETED"
echo "=============================================================="
exit 0
