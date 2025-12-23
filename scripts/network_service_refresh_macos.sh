#!/bin/bash
#
# ============================================================================
#                    NETWORK SERVICE REFRESH SCRIPT (macOS)
# ============================================================================
#  Script Name: network_service_refresh_macos.sh
#  Description: Toggles all network services off and on to refresh connections.
#               Useful for resolving network connectivity issues without
#               requiring a full system restart. Restores original enabled/
#               disabled state after refresh.
#  Author:      Limehawk.io
#  Version:     1.0.0
#  Date:        November 2024
#  Usage:       sudo ./network_service_refresh_macos.sh
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
#  Refreshes all network services on macOS by toggling them off and on.
#  Preserves the original enabled/disabled state of each service.
#  Useful for resolving DHCP lease issues, DNS problems, or general
#  network connectivity problems.
#
#  CONFIGURATION
#  -----------------------------------------------------------------------
#  - TOGGLE_DELAY: Seconds to wait between off/on toggle (default: 2)
#
#  BEHAVIOR
#  -----------------------------------------------------------------------
#  1. Lists all network services
#  2. For each service:
#     a. Records initial enabled/disabled state
#     b. Disables the service
#     c. Waits briefly
#     d. Enables the service
#     e. Restores original state if it was disabled
#  3. Reports final status
#
#  PREREQUISITES
#  -----------------------------------------------------------------------
#  - Root/sudo access required
#  - macOS 10.14 or later
#  - networksetup command available
#
#  SECURITY NOTES
#  -----------------------------------------------------------------------
#  - No secrets exposed in output
#  - Runs with elevated privileges (sudo required)
#  - Temporarily disrupts network connectivity
#
#  EXIT CODES
#  -----------------------------------------------------------------------
#  0 - Success
#  1 - Failure
#
# ============================================================================

set -e

# ==== CONFIGURATION ====
TOGGLE_DELAY=2

# ==== HELPER FUNCTIONS ====

print_section() {
    echo ""
    echo "[ $1 ]"
    echo "--------------------------------------------------------------"
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

# ==== MAIN SCRIPT ====

print_section "INPUT VALIDATION"
print_kv "Toggle Delay" "${TOGGLE_DELAY}s"

# Check for root privileges
if [ "$(id -u)" != "0" ]; then
    echo "ERROR: This script must be run with root privileges (sudo)"
    exit 1
fi
print_kv "Running as root" "Yes"

print_section "NETWORK SERVICES"

# Get the list of network services (skip the header line)
network_services=$(networksetup -listallnetworkservices | tail -n +2)

if [ -z "$network_services" ]; then
    echo "No network services found"
    exit 1
fi

# Count services
service_count=$(echo "$network_services" | wc -l | tr -d ' ')
echo "Found $service_count network service(s)"

print_section "OPERATION"

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

print_section "RESULT"
print_kv "Status" "Success"
print_kv "Services Processed" "$processed"

print_section "FINAL STATUS"
echo "Network services have been refreshed."
echo ""
echo "Current network service status:"
networksetup -listallnetworkservices

print_section "SCRIPT COMPLETED"
exit 0
