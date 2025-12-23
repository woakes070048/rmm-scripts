#!/bin/bash
#
# ██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
# ██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
# ██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
# ██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
# ███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
# ╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
# ================================================================================
#  SCRIPT   : Splashtop Streamer Install (Debian ARM64)                    v1.1.0
#  AUTHOR   : Limehawk.io
#  DATE     : December 2024
#  USAGE    : sudo ./splashtop_streamer_install_debian_arm64.sh
# ================================================================================
#  FILE     : splashtop_streamer_install_debian_arm64.sh
# --------------------------------------------------------------------------------
#  README
# --------------------------------------------------------------------------------
#  PURPOSE
#
#    Downloads and installs the Splashtop Streamer agent on Debian systems
#    running ARM64 architecture (e.g., Raspberry Pi, ARM servers).
#
#  DATA SOURCES & PRIORITY
#
#    - Splashtop CDN: Downloads installer from download.splashtop.com
#
#  REQUIRED INPUTS
#
#    No hardcoded inputs required.
#
#  SETTINGS
#
#    Default configuration:
#      - Streamer version: 3.7.2.0
#      - Architecture: ARM64
#      - Install directory: /opt/splashtop
#
#  BEHAVIOR
#
#    The script performs the following actions in order:
#    1. Updates package lists
#    2. Installs prerequisites (wget, tar)
#    3. Downloads Splashtop Streamer package
#    4. Extracts to installation directory
#    5. Installs deb package with dependency resolution
#    6. Enables and starts systemd service
#    7. Cleans up downloaded files
#
#  PREREQUISITES
#
#    - Debian Linux (ARM64)
#    - Root/sudo privileges
#    - Internet connectivity
#
#  SECURITY NOTES
#
#    - Downloads from official Splashtop servers
#    - No secrets exposed in output
#
#  ENDPOINTS
#
#    - download.splashtop.com (installer download)
#
#  EXIT CODES
#
#    0 = Success
#    1 = Failure
#
#  EXAMPLE RUN
#
#    [ SPLASHTOP STREAMER INSTALL - Debian ARM64 ]
#    --------------------------------------------------------------
#    [1/6] Updating APT...
#    [2/6] Installing prerequisites...
#    [3/6] Downloading Splashtop Streamer v3.7.2.0...
#    [4/6] Extracting to /opt/splashtop...
#    [5/6] Installing package and fixing dependencies...
#    [6/6] Enabling and starting service...
#
#    [ FINAL STATUS ]
#    --------------------------------------------------------------
#    Splashtop Streamer v3.7.2.0 installed and running
#
#    [ SCRIPT COMPLETE ]
#    --------------------------------------------------------------
#
# --------------------------------------------------------------------------------
#  CHANGELOG
# --------------------------------------------------------------------------------
#  2024-12-23 v1.1.0 Updated to Limehawk Script Framework
#  2024-01-01 v1.0.0 Initial release
# ================================================================================

set -e

# ============================================================================
# HARDCODED INPUTS
# ============================================================================
URL="https://download.splashtop.com/linux/STB_CSRS_Debian_v3.7.2.0_arm64.tar.gz"
TAR_FILE="splashtop_debian_arm64.tar.gz"
INSTALL_DIR="/opt/splashtop"
DEB_PACKAGE="Splashtop_Streamer_Debian_arm64.deb"
# ============================================================================

# ============================================================================
# MAIN EXECUTION
# ============================================================================

echo ""
echo "[ SPLASHTOP STREAMER INSTALL - Debian ARM64 ]"
echo "--------------------------------------------------------------"

# Update package list
echo "[1/6] Updating APT..."
sudo apt update

# Install prerequisites
echo "[2/6] Installing prerequisites..."
sudo apt install -y wget tar

# Download package
echo "[3/6] Downloading Splashtop Streamer v3.7.2.0..."
wget -O "$TAR_FILE" "$URL" || {
    echo ""
    echo "[ ERROR OCCURRED ]"
    echo "--------------------------------------------------------------"
    echo "Failed to download package"
    echo ""
    exit 1
}

# Extract package
echo "[4/6] Extracting to $INSTALL_DIR..."
sudo mkdir -p "$INSTALL_DIR"
sudo tar -xzf "$TAR_FILE" -C "$INSTALL_DIR"

# Install deb package
echo "[5/6] Installing package and fixing dependencies..."
cd "$INSTALL_DIR"
sudo dpkg -i "$DEB_PACKAGE" || sudo apt install -f -y

# Enable and start service
echo "[6/6] Enabling and starting service..."
sudo systemctl enable --now splashtop-streamer.service

# Cleanup
rm -f "$TAR_FILE"

echo ""
echo "[ FINAL STATUS ]"
echo "--------------------------------------------------------------"
echo "Splashtop Streamer v3.7.2.0 installed and running"

echo ""
echo "[ SCRIPT COMPLETE ]"
echo "--------------------------------------------------------------"
exit 0
