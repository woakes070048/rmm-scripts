#!/bin/bash
#
# ============================================================================
#                    WORKSTATION MANUAL-RENAME SCRIPT (macOS)
# ============================================================================
#  Script Name: rename_workstation_manual_macos.sh
#  Description: Renames a macOS device using a custom client segment with
#               standardized naming pattern: CLIENT-USER-UUID. Allows variable
#               length client segment override. Sets HostName, ComputerName,
#               and LocalHostName. Designed for RMM deployment.
#  Author:      Limehawk.io
#  Version:     1.0.0
#  Date:        November 2024
#  Usage:       sudo ./rename_workstation_manual_macos.sh
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
#  Renames a macOS device using a custom client segment override.
#
#  Naming Pattern (max 15 chars for NetBIOS compatibility):
#    CLIENT-USERUUID
#      CLIENT : Custom client segment (variable length, from $YourCustomClientHere)
#               Falls back to $YourClientNameHere if custom not set
#      USER   : Sanitized username (maximized, truncated if needed)
#      UUID   : Hardware UUID tail (at least 3 chars)
#
#  Notes:
#    - Only A-Z, 0-9, and hyphen used
#    - Name never starts or ends with '-'
#    - Always exactly 15 chars
#    - Sets HostName, ComputerName, and LocalHostName
#
#  CONFIGURATION
#  -----------------------------------------------------------------------
#  - CUSTOM_CLIENT: RMM variable $YourCustomClientHere (variable length)
#  - CLIENT_NAME: Fallback RMM variable $YourClientNameHere
#  - MAX_HOST_LEN: Maximum hostname length (default: 15)
#  - MIN_UUID_LEN: Minimum UUID suffix length (default: 3)
#
#  BEHAVIOR
#  -----------------------------------------------------------------------
#  1. Gets custom client segment from RMM variable (or falls back)
#  2. Retrieves current logged-in user
#  3. Gets hardware UUID from system
#  4. Builds hostname: CLIENT-USER-UUID (exactly 15 chars)
#  5. Sets HostName, ComputerName, and LocalHostName
#  6. Flushes DNS cache
#
#  PREREQUISITES
#  -----------------------------------------------------------------------
#  - Root/sudo access required
#  - macOS 10.14 or later
#  - RMM variable $YourCustomClientHere or $YourClientNameHere must be set
#
#  SECURITY NOTES
#  -----------------------------------------------------------------------
#  - No secrets exposed in output
#  - Runs with elevated privileges (sudo required)
#
#  EXIT CODES
#  -----------------------------------------------------------------------
#  0 - Success
#  1 - Failure (missing inputs, rename failed)
#
# ============================================================================

set -e

# ==== CONFIGURATION ====
CUSTOM_CLIENT="$YourCustomClientHere"
CLIENT_NAME="$YourClientNameHere"
MAX_HOST_LEN=15
MIN_UUID_LEN=3
MAX_USER_LEN=8

# ==== HELPER FUNCTIONS ====

# Sanitize string: uppercase, alphanumeric only
sanitize() {
    echo "$1" | tr '[:lower:]' '[:upper:]' | tr -cd '[:alnum:]'
}

# Print section header
print_section() {
    echo ""
    echo "[ $1 ]"
    echo "--------------------------------------------------------------"
}

# Print key-value
print_kv() {
    printf " %-24s : %s\n" "$1" "$2"
}

# ==== MAIN SCRIPT ====

print_section "INPUT VALIDATION"

# Determine client segment (custom override or fallback)
if [ -n "$CUSTOM_CLIENT" ]; then
    CLIENT_SEG=$(sanitize "$CUSTOM_CLIENT")
    print_kv "Custom Client" "$CUSTOM_CLIENT"
    print_kv "Client Segment (custom)" "$CLIENT_SEG"
elif [ -n "$CLIENT_NAME" ]; then
    CLIENT_SEG=$(sanitize "$CLIENT_NAME")
    print_kv "Client Name (fallback)" "$CLIENT_NAME"
    print_kv "Client Segment" "$CLIENT_SEG"
else
    echo "ERROR: CLIENT_NAME is required (set \$YourCustomClientHere or \$YourClientNameHere in RMM)"
    exit 1
fi

print_section "SYSTEM VALUES"

# Get current user (console user, not root)
CURRENT_USER=$(stat -f "%Su" /dev/console 2>/dev/null || echo "")
if [ -z "$CURRENT_USER" ] || [ "$CURRENT_USER" = "root" ]; then
    CURRENT_USER=$(who | grep console | awk '{print $1}' | head -1)
fi
USER_SEG=$(sanitize "$CURRENT_USER")
USER_SEG="${USER_SEG:0:$MAX_USER_LEN}"

print_kv "Console User" "$CURRENT_USER"
print_kv "User Segment" "$USER_SEG"

# Get hardware UUID
HARDWARE_UUID=$(ioreg -rd1 -c IOPlatformExpertDevice | awk -F'"' '/IOPlatformUUID/{print $4}')
if [ -z "$HARDWARE_UUID" ]; then
    echo "ERROR: Could not retrieve hardware UUID"
    exit 1
fi
UUID_CLEAN=$(echo "$HARDWARE_UUID" | tr -d '-' | tr '[:lower:]' '[:upper:]')

print_kv "Hardware UUID" "$HARDWARE_UUID"
print_kv "UUID (clean)" "$UUID_CLEAN"

# Get current hostname
CURRENT_HOST=$(scutil --get ComputerName 2>/dev/null || hostname -s)
print_kv "Current Hostname" "$CURRENT_HOST"

print_section "BUILD HOSTNAME"

# Trim client segment if too long (must leave room for hyphen + min uuid)
MAX_CLIENT_LEN=$((MAX_HOST_LEN - 1 - MIN_UUID_LEN))
if [ ${#CLIENT_SEG} -gt $MAX_CLIENT_LEN ]; then
    CLIENT_SEG="${CLIENT_SEG:0:$MAX_CLIENT_LEN}"
fi

PREFIX="${CLIENT_SEG}-"
PREFIX_LEN=${#PREFIX}

# Calculate remaining space
REMAINING=$((MAX_HOST_LEN - PREFIX_LEN))

# User takes what it can, UUID fills the rest (min 3)
MAX_USER_TAKE=$((REMAINING - MIN_UUID_LEN))
if [ $MAX_USER_TAKE -lt 0 ]; then
    MAX_USER_TAKE=0
fi

USER_TAKE=${#USER_SEG}
if [ $USER_TAKE -gt $MAX_USER_TAKE ]; then
    USER_TAKE=$MAX_USER_TAKE
fi

UUID_TAKE=$((MAX_HOST_LEN - PREFIX_LEN - USER_TAKE))
if [ $UUID_TAKE -lt $MIN_UUID_LEN ]; then
    UUID_TAKE=$MIN_UUID_LEN
fi

# Get UUID suffix
UUID_LEN=${#UUID_CLEAN}
UUID_START=$((UUID_LEN - UUID_TAKE))
UUID_SUFFIX="${UUID_CLEAN:$UUID_START:$UUID_TAKE}"

# Build final hostname
USER_PART="${USER_SEG:0:$USER_TAKE}"
DESIRED_NAME="${PREFIX}${USER_PART}${UUID_SUFFIX}"
DESIRED_NAME=$(echo "$DESIRED_NAME" | tr '[:lower:]' '[:upper:]')

print_kv "Prefix" "$PREFIX"
print_kv "User Part" "$USER_PART"
print_kv "UUID Suffix" "$UUID_SUFFIX"
print_kv "Desired Name" "$DESIRED_NAME"
print_kv "Name Length" "${#DESIRED_NAME}"

print_section "RENAME ACTION"

# Check if already named correctly
CURRENT_UPPER=$(echo "$CURRENT_HOST" | tr '[:lower:]' '[:upper:]')
if [ "$CURRENT_UPPER" = "$DESIRED_NAME" ]; then
    print_kv "Status" "HOSTNAME ALREADY MATCHES"
    print_kv "Action" "NO RENAME NEEDED"
else
    print_kv "Status" "RENAMING TO $DESIRED_NAME"

    # Set all hostname types
    if sudo scutil --set HostName "$DESIRED_NAME" && \
       sudo scutil --set ComputerName "$DESIRED_NAME" && \
       sudo scutil --set LocalHostName "$DESIRED_NAME"; then
        print_kv "Result" "RENAME SUCCESSFUL"
    else
        echo "ERROR: Failed to set hostname"
        exit 1
    fi

    # Flush DNS cache
    print_kv "Action" "Flushing DNS cache"
    sudo killall -HUP mDNSResponder 2>/dev/null || true
fi

print_section "FINAL STATUS"
echo " Hostname set to: $DESIRED_NAME"
echo " HostName, ComputerName, and LocalHostName updated"

print_section "SCRIPT COMPLETED"
exit 0
