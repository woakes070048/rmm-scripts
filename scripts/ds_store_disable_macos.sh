#!/bin/bash
#
# ██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
# ██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
# ██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
# ██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
# ███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
# ╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
# ================================================================================
#  SCRIPT   : Disable .DS_Store on Network Shares                          v1.1.1
#  AUTHOR   : Limehawk.io
#  DATE     : January 2026
#  USAGE    : ./ds_store_disable_macos.sh
# ================================================================================
#  FILE     : ds_store_disable_macos.sh
#  DESCRIPTION : Prevents macOS from creating .DS_Store files on network shares
# --------------------------------------------------------------------------------
#  README
# --------------------------------------------------------------------------------
#  PURPOSE
#
#    Prevents macOS from creating .DS_Store files on network shares.
#    These files contain folder metadata and can clutter network drives,
#    causing issues for non-Mac users accessing shared folders.
#
#  DATA SOURCES & PRIORITY
#
#    - macOS defaults system: Writes to com.apple.desktopservices preferences
#
#  REQUIRED INPUTS
#
#    No hardcoded inputs required.
#
#  SETTINGS
#
#    - DSDontWriteNetworkStores: Set to true to disable .DS_Store on network shares
#
#  BEHAVIOR
#
#    The script performs the following actions in order:
#    1. Sets DSDontWriteNetworkStores to true via defaults command
#    2. Displays confirmation message
#    3. Notifies user that logout/reboot is required
#
#  PREREQUISITES
#
#    - macOS operating system
#    - No special privileges required (runs as current user)
#
#  SECURITY NOTES
#
#    - No secrets exposed in output
#    - Modifies user preferences only
#    - No elevated privileges required
#
#  ENDPOINTS
#
#    Not applicable - local system configuration only
#
#  EXIT CODES
#
#    0 = Success
#    1 = Failure
#
#  EXAMPLE RUN
#
#    [RUN] DISABLE .DS_STORE ON NETWORK SHARES
#    ==============================================================
#    Setting applied: DSDontWriteNetworkStores = true
#
#    NOTE: Log out and back in (or reboot) for changes to take effect.
#
#    [OK] SCRIPT COMPLETED
#    ==============================================================
#
# --------------------------------------------------------------------------------
#  CHANGELOG
# --------------------------------------------------------------------------------
#  2026-01-19 v1.1.1 Updated to two-line ASCII console output style
#  2025-12-23 v1.1.0 Updated to Limehawk Script Framework
#  2024-12-01 v1.0.0 Initial release - migrated from SuperOps
# ================================================================================

set -euo pipefail

# ============================================================================
# MAIN EXECUTION
# ============================================================================

echo ""
echo "[RUN] DISABLE .DS_STORE ON NETWORK SHARES"
echo "=============================================================="

defaults write com.apple.desktopservices DSDontWriteNetworkStores true

echo "Setting applied : DSDontWriteNetworkStores = true"
echo ""
echo "NOTE: Log out and back in (or reboot) for changes to take effect."

echo ""
echo "[OK] SCRIPT COMPLETED"
echo "=============================================================="
exit 0
