#!/bin/bash
#
# ██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
# ██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
# ██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
# ██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
# ███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
# ╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
# ================================================================================
#  SCRIPT   : Splashtop Streamer Install (macOS)                           v1.1.0
#  AUTHOR   : Limehawk.io
#  DATE     : December 2025
#  USAGE    : sudo ./splashtop_streamer_install_macos.sh
# ================================================================================
#  FILE     : splashtop_streamer_install_macos.sh
#  DESCRIPTION : Downloads and installs Splashtop Streamer agent on macOS
# --------------------------------------------------------------------------------
#  README
# --------------------------------------------------------------------------------
#  PURPOSE
#
#    Downloads and installs the Splashtop Streamer agent on macOS for remote
#    access capabilities. The Streamer runs on computers to allow remote
#    connections from Splashtop Business clients.
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
#      - Installer URL: Splashtop Streamer v3.7.0.0
#      - Temp file: /tmp/splashtop_streamer.dmg
#
#  BEHAVIOR
#
#    The script performs the following actions in order:
#    1. Downloads Splashtop Streamer installer DMG
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
#    [ SPLASHTOP STREAMER INSTALL - macOS ]
#    --------------------------------------------------------------
#    Downloading Splashtop Streamer...
#    Mounting installer...
#    Installing Splashtop Streamer...
#    Cleaning up...
#
#    [ FINAL STATUS ]
#    --------------------------------------------------------------
#    Splashtop Streamer installed successfully
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
SPLASHTOP_URL="https://download.splashtop.com/csrs/Splashtop_Streamer_Mac_DEPLOY_INSTALLER_v3.7.0.0.dmg"
TEMP_DMG="/tmp/splashtop_streamer.dmg"
MOUNT_DIR="/Volumes/SplashtopStreamer"
# ============================================================================

# ============================================================================
# MAIN EXECUTION
# ============================================================================

echo ""
echo "[ SPLASHTOP STREAMER INSTALL - macOS ]"
echo "--------------------------------------------------------------"

# Download installer
echo "Downloading Splashtop Streamer..."
curl -L -o "$TEMP_DMG" "$SPLASHTOP_URL" || {
    echo ""
    echo "[ ERROR OCCURRED ]"
    echo "--------------------------------------------------------------"
    echo "Failed to download installer"
    echo ""
    exit 1
}

# Mount DMG
echo "Mounting installer..."
hdiutil attach "$TEMP_DMG" -nobrowse -quiet || {
    echo ""
    echo "[ ERROR OCCURRED ]"
    echo "--------------------------------------------------------------"
    echo "Failed to mount DMG"
    echo ""
    exit 1
}

# Install package
echo "Installing Splashtop Streamer..."
sudo installer -pkg "$MOUNT_DIR/.Splashtop Streamer.pkg" -target / || {
    hdiutil detach "$MOUNT_DIR" -quiet 2>/dev/null
    echo ""
    echo "[ ERROR OCCURRED ]"
    echo "--------------------------------------------------------------"
    echo "Installation failed"
    echo ""
    exit 1
}

# Cleanup
echo "Cleaning up..."
hdiutil detach "$MOUNT_DIR" -quiet
rm -f "$TEMP_DMG"

echo ""
echo "[ FINAL STATUS ]"
echo "--------------------------------------------------------------"
echo "Splashtop Streamer installed successfully"

echo ""
echo "[ SCRIPT COMPLETE ]"
echo "--------------------------------------------------------------"
exit 0
