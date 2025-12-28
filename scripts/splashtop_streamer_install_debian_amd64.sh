#!/bin/bash
#
# ██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
# ██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
# ██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
# ██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
# ███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
# ╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
# ================================================================================
#  SCRIPT   : Splashtop Streamer Install (Debian AMD64)                    v1.1.0
#  AUTHOR   : Limehawk.io
#  DATE     : December 2025
#  USAGE    : sudo ./splashtop_streamer_install_debian_amd64.sh
# ================================================================================
#  FILE     : splashtop_streamer_install_debian_amd64.sh
#  DESCRIPTION : Installs Splashtop Streamer on Debian/Ubuntu AMD64 systems
# --------------------------------------------------------------------------------
#  README
# --------------------------------------------------------------------------------
#  PURPOSE
#
#    Downloads and installs the Splashtop Streamer agent on Debian/Ubuntu
#    systems running AMD64 architecture.
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
#      - Architecture: AMD64
#      - Install directory: /opt/splashtop
#
#  BEHAVIOR
#
#    The script performs the following actions in order:
#    1. Updates package lists
#    2. Downloads Splashtop Streamer package
#    3. Extracts to installation directory
#    4. Installs deb package with dependency resolution
#    5. Cleans up downloaded files
#
#  PREREQUISITES
#
#    - Debian/Ubuntu Linux (AMD64)
#    - Root/sudo privileges
#    - Internet connectivity
#    - wget and tar packages
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
#    [ SPLASHTOP STREAMER INSTALL - Debian AMD64 ]
#    --------------------------------------------------------------
#    [1/5] Updating package list...
#    [2/5] Downloading Splashtop Streamer...
#    [3/5] Extracting package to /opt/splashtop...
#    [4/5] Installing Splashtop Streamer...
#    [5/5] Cleaning up...
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
URL="https://download.splashtop.com/linux/STB_CSRS_Ubuntu_v3.7.2.0_amd64.tar.gz"
TAR_FILE="splashtop_ubuntu_amd64.tar.gz"
INSTALL_DIR="/opt/splashtop"
DEB_PACKAGE="Splashtop_Streamer_Ubuntu_amd64.deb"
# ============================================================================

# ============================================================================
# MAIN EXECUTION
# ============================================================================

echo ""
echo "[ SPLASHTOP STREAMER INSTALL - Debian AMD64 ]"
echo "--------------------------------------------------------------"

# Update package list
echo "[1/5] Updating package list..."
sudo apt update

# Download package
echo "[2/5] Downloading Splashtop Streamer..."
wget -O "$TAR_FILE" "$URL" || {
    echo ""
    echo "[ ERROR OCCURRED ]"
    echo "--------------------------------------------------------------"
    echo "Failed to download package"
    echo ""
    exit 1
}

# Create install directory and extract
echo "[3/5] Extracting package to $INSTALL_DIR..."
sudo mkdir -p "$INSTALL_DIR"
sudo tar -xzf "$TAR_FILE" -C "$INSTALL_DIR"

# Install deb package
echo "[4/5] Installing Splashtop Streamer..."
cd "$INSTALL_DIR"
sudo dpkg -i "$DEB_PACKAGE" || sudo apt install -f -y

# Cleanup
echo "[5/5] Cleaning up..."
rm -f "$TAR_FILE"

echo ""
echo "[ FINAL STATUS ]"
echo "--------------------------------------------------------------"
echo "Splashtop Streamer installed successfully"

echo ""
echo "[ SCRIPT COMPLETE ]"
echo "--------------------------------------------------------------"
exit 0
