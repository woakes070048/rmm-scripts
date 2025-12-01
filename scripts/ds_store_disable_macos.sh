#!/bin/bash
set -euo pipefail
# ==============================================================================
# SCRIPT : Disable .DS_Store on Network Shares                           v1.0.0
# FILE   : ds_store_disable_macos.sh
# ==============================================================================
# PURPOSE:
#   Prevents macOS from creating .DS_Store files on network shares.
#   These files contain folder metadata and can clutter network drives.
#
# BEHAVIOR:
#   Sets DSDontWriteNetworkStores to true in com.apple.desktopservices
#
# PREREQUISITES:
#   - macOS
#   - No special privileges required
#
# NOTE:
#   Requires logout/login or reboot to take effect
#
# EXIT CODES:
#   0 = Success
#   1 = Failure
#
# CHANGELOG:
#   2024-12-01 v1.0.0  Initial release - migrated from SuperOps
# ==============================================================================

echo ""
echo "[ DISABLE .DS_STORE ON NETWORK SHARES ]"
echo "--------------------------------------------------------------"

defaults write com.apple.desktopservices DSDontWriteNetworkStores true

echo " Setting applied: DSDontWriteNetworkStores = true"
echo ""
echo " NOTE: Log out and back in (or reboot) for changes to take effect."
echo ""
echo "[ SCRIPT COMPLETED ]"
echo "--------------------------------------------------------------"

exit 0
