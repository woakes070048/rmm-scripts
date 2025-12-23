#!/bin/bash
#
# ============================================================================
#                       RESET NVRAM AND REBOOT SCRIPT (macOS)
# ============================================================================
#  Script Name: reset_nvram_reboot_macos.sh
#  Description: Schedules an NVRAM reset on the next reboot and immediately
#               reboots the Mac. NVRAM stores system settings like startup
#               disk selection, display resolution, speaker volume, etc.
#  Author:      Limehawk.io
#  Version:     1.0.0
#  Date:        November 2024
#  Usage:       sudo ./reset_nvram_reboot_macos.sh
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
#  Resets NVRAM (Non-Volatile Random-Access Memory) on Intel-based Macs.
#  NVRAM stores settings that macOS accesses quickly, including:
#    - Startup disk selection
#    - Display resolution
#    - Speaker volume
#    - Time zone information
#    - Recent kernel panic information
#
#  Useful for troubleshooting:
#    - Boot issues
#    - Display problems
#    - Audio issues
#    - Startup disk not found errors
#    - Time/date problems
#
#  NOTE: On Apple Silicon Macs (M1/M2/M3), NVRAM is automatically reset
#  during the update process and this manual reset may not be needed.
#
#  CONFIGURATION
#  -----------------------------------------------------------------------
#  No configuration required.
#
#  BEHAVIOR
#  -----------------------------------------------------------------------
#  1. Checks for root privileges
#  2. Detects Mac architecture (Intel vs Apple Silicon)
#  3. Sets NVRAM variable to trigger reset on next boot
#  4. Immediately reboots the system
#
#  PREREQUISITES
#  -----------------------------------------------------------------------
#  - Root/sudo access required
#  - macOS 10.14 or later
#  - Intel-based Mac (Apple Silicon uses different reset method)
#
#  SECURITY NOTES
#  -----------------------------------------------------------------------
#  - No secrets exposed in output
#  - Runs with elevated privileges (sudo required)
#  - WILL IMMEDIATELY REBOOT THE SYSTEM
#  - User data is not affected (only system settings reset)
#
#  EXIT CODES
#  -----------------------------------------------------------------------
#  0 - Success (reboot initiated)
#  1 - Failure (permission denied, unsupported architecture)
#
# ============================================================================

set -e

# ==== HELPER FUNCTIONS ====

print_section() {
    echo ""
    echo "[ $1 ]"
    echo "--------------------------------------------------------------"
}

print_kv() {
    printf " %-24s : %s\n" "$1" "$2"
}

# ==== MAIN SCRIPT ====

print_section "INPUT VALIDATION"

# Check for root privileges
if [ "$(id -u)" != "0" ]; then
    echo "ERROR: This script must be run with root privileges (sudo)"
    exit 1
fi
print_kv "Running as root" "Yes"

print_section "SYSTEM DETECTION"

# Detect architecture
ARCH=$(uname -m)
print_kv "Architecture" "$ARCH"

# Get Mac model
MAC_MODEL=$(sysctl -n hw.model 2>/dev/null || echo "Unknown")
print_kv "Mac Model" "$MAC_MODEL"

# Check for Apple Silicon
if [ "$ARCH" = "arm64" ]; then
    echo ""
    echo "WARNING: Apple Silicon Macs (M1/M2/M3) handle NVRAM differently."
    echo "         NVRAM is automatically managed and this reset may have"
    echo "         limited effect. Consider using Recovery Mode for a full"
    echo "         NVRAM reset on Apple Silicon Macs."
    echo ""
    print_kv "Proceeding" "Yes (with warning)"
fi

print_section "CURRENT NVRAM"

# Show some current NVRAM values (non-sensitive)
echo "Current NVRAM values (subset):"
nvram -p 2>/dev/null | grep -E "^(SystemAudioVolume|boot-args|csr-active-config)" | while read -r line; do
    echo "  $line"
done || echo "  (unable to read NVRAM)"

print_section "OPERATION"

echo "Setting NVRAM reset flag..."
nvram ResetNVRam=1

print_kv "NVRAM Reset Flag" "Set"
print_kv "Action" "Initiating reboot"

echo ""
echo "*** SYSTEM WILL REBOOT NOW ***"
echo ""

print_section "REBOOTING"

# Initiate reboot
reboot

# Script will not reach here
exit 0
