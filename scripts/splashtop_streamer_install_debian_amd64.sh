#!/bin/bash
#
# ██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
# ██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
# ██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
# ██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
# ███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
# ╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
# ================================================================================
#  SCRIPT   : Splashtop Streamer Install (Debian AMD64)                    v1.1.1
#  AUTHOR   : Limehawk.io
#  DATE     : January 2026
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
#    [RUN] UPDATING PACKAGES
#    ==============================================================
#    Updating package list...
#
#    [RUN] DOWNLOADING INSTALLER
#    ==============================================================
#    Downloading Splashtop Streamer...
#
#    [RUN] EXTRACTING PACKAGE
#    ==============================================================
#    Extracting package to /opt/splashtop...
#
#    [RUN] INSTALLING
#    ==============================================================
#    Installing Splashtop Streamer...
#
#    [RUN] CLEANUP
#    ==============================================================
#    Cleaning up...
#
#    [OK] SCRIPT COMPLETED
#    ==============================================================
#    Splashtop Streamer installed successfully
#
# --------------------------------------------------------------------------------
#  CHANGELOG
# --------------------------------------------------------------------------------
#  2026-01-19 v1.1.1 Updated to two-line ASCII console output style
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
echo "[RUN] UPDATING PACKAGES"
echo "=============================================================="

# Update package list
echo "Updating package list..."
sudo apt update

echo ""
echo "[RUN] DOWNLOADING INSTALLER"
echo "=============================================================="

# Download package
echo "Downloading Splashtop Streamer..."
wget -O "$TAR_FILE" "$URL" || {
    echo ""
    echo "[ERROR] ERROR OCCURRED"
    echo "=============================================================="
    echo "Failed to download package"
    echo ""
    exit 1
}

echo ""
echo "[RUN] EXTRACTING PACKAGE"
echo "=============================================================="

# Create install directory and extract
echo "Extracting package to $INSTALL_DIR..."
sudo mkdir -p "$INSTALL_DIR"
sudo tar -xzf "$TAR_FILE" -C "$INSTALL_DIR"

echo ""
echo "[RUN] INSTALLING"
echo "=============================================================="

# Install deb package
echo "Installing Splashtop Streamer..."
cd "$INSTALL_DIR"
sudo dpkg -i "$DEB_PACKAGE" || sudo apt install -f -y

echo ""
echo "[RUN] CLEANUP"
echo "=============================================================="

# Cleanup
echo "Cleaning up..."
rm -f "$TAR_FILE"

echo ""
echo "[OK] SCRIPT COMPLETED"
echo "=============================================================="
echo "Splashtop Streamer installed successfully"
exit 0
