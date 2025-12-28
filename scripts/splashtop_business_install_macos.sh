#!/bin/bash
#
# ██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
# ██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
# ██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
# ██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
# ███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
# ╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
# ================================================================================
#  SCRIPT   : Splashtop Business Install (macOS)                           v1.1.0
#  AUTHOR   : Limehawk.io
#  DATE     : December 2025
#  USAGE    : sudo ./splashtop_business_install_macos.sh
# ================================================================================
#  FILE     : splashtop_business_install_macos.sh
#  DESCRIPTION : Downloads and installs Splashtop Business client on macOS
# --------------------------------------------------------------------------------
#  README
# --------------------------------------------------------------------------------
#  PURPOSE
#
#    Downloads and installs the Splashtop Business client application on macOS.
#    The Business client allows users to connect to remote computers with
#    Splashtop Streamer installed.
#
#  DATA SOURCES & PRIORITY
#
#    - Splashtop CDN: Downloads installer from official Splashtop servers
#
#  REQUIRED INPUTS
#
#    All inputs are hardcoded in the script body:
#      - SPLASHTOP_URL: Direct download URL for installer DMG
#
#  SETTINGS
#
#    Default configuration:
#      - Installer URL: Splashtop Business v3.7.2.0
#      - Mount directory: /Volumes/Splashtop Business
#
#  BEHAVIOR
#
#    The script performs the following actions in order:
#    1. Downloads Splashtop Business installer DMG
#    2. Mounts the DMG
#    3. Installs the package from the mounted DMG
#    4. Unmounts the DMG
#    5. Cleans up downloaded installer
#
#  PREREQUISITES
#
#    - macOS
#    - Root/sudo privileges
#    - Internet connectivity
#
#  SECURITY NOTES
#
#    - Downloads from official Splashtop servers
#    - No secrets exposed in output
#    - Installer is removed after installation
#
#  ENDPOINTS
#
#    - download.splashtop.com (installer download)
#
#  EXIT CODES
#
#    0 = Success
#    1 = Failure (download failed, mount failed, or install failed)
#
#  EXAMPLE RUN
#
#    [ SPLASHTOP BUSINESS INSTALL - macOS ]
#    --------------------------------------------------------------
#    Downloading Splashtop Business installer...
#    Download completed
#    Mounting installer DMG...
#    Installing Splashtop Business...
#    Cleaning up...
#
#    [ FINAL STATUS ]
#    --------------------------------------------------------------
#    Splashtop Business installed successfully
#
#    [ SCRIPT COMPLETE ]
#    --------------------------------------------------------------
#
# --------------------------------------------------------------------------------
#  CHANGELOG
# --------------------------------------------------------------------------------
#  2025-12-23 v1.1.0 Updated to Limehawk Script Framework
#  2024-01-01 v1.0.0 Initial release
# ================================================================================

set -e

# ============================================================================
# HARDCODED INPUTS
# ============================================================================
SPLASHTOP_URL="https://download.splashtop.com/macclient/STB/Splashtop_Business_Mac_INSTALLER_v3.7.2.0.dmg"
SPLASHTOP_INSTALLER="Splashtop_Business_Mac_INSTALLER.dmg"
MOUNT_DIR="/Volumes/Splashtop Business"
# ============================================================================

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

handle_error() {
    echo ""
    echo "[ ERROR OCCURRED ]"
    echo "--------------------------------------------------------------"
    echo "$1"
    echo ""
    exit 1
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

echo ""
echo "[ SPLASHTOP BUSINESS INSTALL - macOS ]"
echo "--------------------------------------------------------------"

# Download installer
echo "Downloading Splashtop Business installer..."
curl -L -o "$SPLASHTOP_INSTALLER" "$SPLASHTOP_URL" || handle_error "Failed to download installer"

if [ ! -f "$SPLASHTOP_INSTALLER" ]; then
    handle_error "Installer file not found after download"
fi
echo "Download completed"

# Mount DMG
echo "Mounting installer DMG..."
hdiutil attach "$SPLASHTOP_INSTALLER" -nobrowse || handle_error "Failed to mount DMG"

# Install package
PKG_PATH="$MOUNT_DIR/Splashtop Business.pkg"
if [ -e "$PKG_PATH" ]; then
    echo "Installing Splashtop Business..."
    sudo installer -pkg "$PKG_PATH" -target / || handle_error "Installation failed"
else
    hdiutil detach "$MOUNT_DIR" 2>/dev/null
    handle_error "Package not found in mounted DMG"
fi

# Cleanup
echo "Cleaning up..."
hdiutil detach "$MOUNT_DIR" || handle_error "Failed to unmount DMG"
rm -f "$SPLASHTOP_INSTALLER" || handle_error "Failed to remove installer"

echo ""
echo "[ FINAL STATUS ]"
echo "--------------------------------------------------------------"
echo "Splashtop Business installed successfully"

echo ""
echo "[ SCRIPT COMPLETE ]"
echo "--------------------------------------------------------------"
exit 0
