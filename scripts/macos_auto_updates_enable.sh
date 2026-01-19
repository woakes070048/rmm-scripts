#!/bin/bash
#
# ██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
# ██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
# ██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
# ██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
# ███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
# ╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
# ================================================================================
#  SCRIPT   : Enable macOS Auto-Updates                                    v1.1.1
#  AUTHOR   : Limehawk.io
#  DATE     : January 2026
#  USAGE    : sudo ./macos_auto_updates_enable.sh
# ================================================================================
#  FILE     : macos_auto_updates_enable.sh
#  DESCRIPTION : Enables all automatic update settings on macOS
# --------------------------------------------------------------------------------
#  README
# --------------------------------------------------------------------------------
#  PURPOSE
#
#    Enables all automatic update settings on macOS including automatic checking,
#    downloading, and installation of macOS updates, App Store updates, and
#    security/critical updates. Ensures systems stay patched and secure.
#
#  DATA SOURCES & PRIORITY
#
#    - macOS defaults system: Writes to SoftwareUpdate and commerce preferences
#
#  REQUIRED INPUTS
#
#    No hardcoded inputs required.
#
#  SETTINGS
#
#    The following settings are enabled:
#      - AutomaticCheckEnabled: Check for updates automatically
#      - AutomaticDownload: Download updates in background
#      - AutoUpdate: App Store auto-updates
#      - ConfigDataInstall: Config data file updates
#      - CriticalUpdateInstall: Security updates
#      - AutomaticallyInstallMacOSUpdates: macOS system updates
#
#  BEHAVIOR
#
#    The script performs the following actions in order:
#    1. Verifies root/sudo privileges
#    2. Enables automatic check for updates
#    3. Enables automatic download of updates
#    4. Enables App Store auto-updates
#    5. Enables config data file updates
#    6. Enables critical security updates
#    7. Enables automatic macOS updates
#    8. Verifies all settings were applied
#
#  PREREQUISITES
#
#    - macOS 10.14 or later
#    - Root/sudo privileges
#
#  SECURITY NOTES
#
#    - No secrets exposed in output
#    - Requires elevated privileges to modify system preferences
#    - Enables automatic security patching (recommended)
#
#  ENDPOINTS
#
#    Not applicable - local system configuration only
#
#  EXIT CODES
#
#    0 = Success
#    1 = Failure (not running as root)
#
#  EXAMPLE RUN
#
#    [RUN] ENABLING AUTO-UPDATES
#    ==============================================================
#    Enabling automatic check for updates...
#    Enabling automatic download of updates...
#    Enabling App Store auto-updates...
#    Enabling config data file updates...
#    Enabling critical security updates...
#    Enabling automatic macOS updates...
#
#    [INFO] VERIFICATION
#    ==============================================================
#    AutomaticCheckEnabled           : 1
#    AutomaticDownload               : 1
#    AutoUpdate (App Store)          : 1
#    ConfigDataInstall               : 1
#    CriticalUpdateInstall           : 1
#    AutomaticallyInstallMacOSUpdates: 1
#
#    [INFO] RESULT
#    ==============================================================
#    All auto-update settings have been enabled.
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
echo "[RUN] ENABLING AUTO-UPDATES"
echo "=============================================================="

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo ""
    echo "[ERROR] ERROR OCCURRED"
    echo "=============================================================="
    echo "This script must be run as root (use sudo)"
    echo ""
    exit 1
fi

echo "Enabling automatic check for updates..."
defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true

echo "Enabling automatic download of updates..."
defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -bool true

echo "Enabling App Store auto-updates..."
defaults write /Library/Preferences/com.apple.commerce AutoUpdate -bool true

echo "Enabling config data file updates..."
defaults write /Library/Preferences/com.apple.SoftwareUpdate ConfigDataInstall -bool true

echo "Enabling critical security updates..."
defaults write /Library/Preferences/com.apple.SoftwareUpdate CriticalUpdateInstall -bool true

echo "Enabling automatic macOS updates..."
defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates -bool true

echo ""
echo "[INFO] VERIFICATION"
echo "=============================================================="
echo "AutomaticCheckEnabled           : $(defaults read /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled 2>/dev/null || echo 'not set')"
echo "AutomaticDownload               : $(defaults read /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload 2>/dev/null || echo 'not set')"
echo "AutoUpdate (App Store)          : $(defaults read /Library/Preferences/com.apple.commerce AutoUpdate 2>/dev/null || echo 'not set')"
echo "ConfigDataInstall               : $(defaults read /Library/Preferences/com.apple.SoftwareUpdate ConfigDataInstall 2>/dev/null || echo 'not set')"
echo "CriticalUpdateInstall           : $(defaults read /Library/Preferences/com.apple.SoftwareUpdate CriticalUpdateInstall 2>/dev/null || echo 'not set')"
echo "AutomaticallyInstallMacOSUpdates: $(defaults read /Library/Preferences/com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates 2>/dev/null || echo 'not set')"

echo ""
echo "[INFO] RESULT"
echo "=============================================================="
echo "All auto-update settings have been enabled."

echo ""
echo "[OK] SCRIPT COMPLETED"
echo "=============================================================="
exit 0
