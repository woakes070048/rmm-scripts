#!/bin/bash
#
# ██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
# ██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
# ██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
# ██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
# ███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
# ╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
# ================================================================================
#  SCRIPT   : Synology Active Backup Agent Install (Linux)                 v1.1.1
#  AUTHOR   : Limehawk.io
#  DATE     : January 2026
#  USAGE    : sudo ./synology_backup_agent_install_linux.sh
# ================================================================================
#  FILE     : synology_backup_agent_install_linux.sh
#  DESCRIPTION : Installs Synology Active Backup for Business Agent on Linux
# --------------------------------------------------------------------------------
#  README
# --------------------------------------------------------------------------------
#  PURPOSE
#
#    Installs the Synology Active Backup for Business Agent on Linux systems.
#    Includes prerequisite checks for architecture, kernel headers, and tools.
#
#  DATA SOURCES & PRIORITY
#
#    - Synology CDN: Downloads agent from global.download.synology.com
#
#  REQUIRED INPUTS
#
#    No hardcoded inputs required.
#
#  SETTINGS
#
#    Default configuration:
#      - Agent version: 2.7.1-3235
#      - Architecture: x86_64 only
#      - Package format: deb (Debian/Ubuntu)
#
#  BEHAVIOR
#
#    The script performs the following actions in order:
#    1. Verifies root privileges
#    2. Checks system architecture (x86_64 required)
#    3. Verifies kernel headers are installed
#    4. Checks required tools (make, dkms, gcc, unzip)
#    5. Downloads agent package from Synology
#    6. Extracts and runs installer
#    7. Cleans up temporary files
#
#  PREREQUISITES
#
#    - Debian 10/11/12 or Ubuntu 16.04-24.04 (x86_64 only)
#    - Root/sudo privileges
#    - linux-headers for current kernel
#    - make 4.1+, dkms 2.2.0.3+, gcc 4.8.2+
#    - unzip, curl or wget
#
#  SECURITY NOTES
#
#    - Downloads from official Synology servers
#    - No secrets exposed in output
#    - Installer runs with elevated privileges
#
#  ENDPOINTS
#
#    - global.download.synology.com (agent download)
#
#  EXIT CODES
#
#    0 = Success
#    1 = Failure (prerequisites not met or installation failed)
#
#  EXAMPLE RUN
#
#    [INFO] SYNOLOGY ACTIVE BACKUP AGENT INSTALL
#    ==============================================================
#
#    [INFO] SYSTEM CHECKS
#    ==============================================================
#    Architecture : x86_64
#    Kernel : 5.15.0-91-generic
#    Headers : Found
#    Tools : make, dkms, gcc, unzip - OK
#
#    [RUN] DOWNLOADING
#    ==============================================================
#    Downloading Synology Active Backup Agent...
#    Download completed
#
#    [RUN] EXTRACTING
#    ==============================================================
#    Extracting installer...
#    Extraction completed
#
#    [RUN] INSTALLING
#    ==============================================================
#    Running installer...
#
#    [OK] FINAL STATUS
#    ==============================================================
#    Result : SUCCESS
#    Synology Active Backup Agent installed successfully
#
#    [OK] SCRIPT COMPLETE
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
echo "[INFO] SYNOLOGY ACTIVE BACKUP AGENT INSTALL"
echo "=============================================================="

# Ensure script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo ""
    echo "[ERROR] ERROR OCCURRED"
    echo "=============================================================="
    echo "This script must be run as root."
    echo ""
    exit 1
fi

# ============================================================================
# SYSTEM REQUIREMENT CHECKS
# ============================================================================
echo ""
echo "[INFO] SYSTEM CHECKS"
echo "=============================================================="

# Check architecture
ARCH=$(uname -m)
echo "Architecture : $ARCH"
if [ "$ARCH" != "x86_64" ]; then
    echo ""
    echo "[ERROR] ERROR OCCURRED"
    echo "=============================================================="
    echo "Unsupported architecture. Only x86_64 is supported."
    echo ""
    exit 1
fi

# Check Linux headers
KERNEL_HEADERS_DIR="/usr/src/linux-headers-$(uname -r)"
echo "Kernel : $(uname -r)"
if [ ! -d "${KERNEL_HEADERS_DIR}" ]; then
    echo ""
    echo "[ERROR] ERROR OCCURRED"
    echo "=============================================================="
    echo "Linux headers not found at ${KERNEL_HEADERS_DIR}"
    echo "Install with: apt install linux-headers-$(uname -r)"
    echo ""
    exit 1
fi
echo "Headers : Found"

# Check required commands
for cmd in make dkms gcc unzip; do
    if ! command -v $cmd >/dev/null 2>&1; then
        echo ""
        echo "[ERROR] ERROR OCCURRED"
        echo "=============================================================="
        echo "$cmd is not installed. Please install it."
        echo ""
        exit 1
    fi
done
echo "Tools : make, dkms, gcc, unzip - OK"

# Setup downloader
if command -v curl >/dev/null 2>&1; then
    DOWNLOADER="curl -L -o"
elif command -v wget >/dev/null 2>&1; then
    DOWNLOADER="wget -O"
else
    echo ""
    echo "[ERROR] ERROR OCCURRED"
    echo "=============================================================="
    echo "Neither curl nor wget is installed."
    echo ""
    exit 1
fi

# Version check function
check_version() {
    local prog_name=$1
    local required_version=$2
    local current_version

    current_version=$($prog_name --version 2>&1 | head -n1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?')
    if [ -z "$current_version" ]; then
        echo "[WARN] Could not determine version for $prog_name"
        return
    fi
    if dpkg --compare-versions "$current_version" "lt" "$required_version"; then
        echo ""
        echo "[ERROR] ERROR OCCURRED"
        echo "=============================================================="
        echo "$prog_name version $current_version < required $required_version"
        echo ""
        exit 1
    fi
    echo "$prog_name : $current_version (>= $required_version required) - OK"
}

check_version make 4.1
check_version dkms 2.2.0.3
check_version gcc 4.8.2

# ============================================================================
# DOWNLOAD
# ============================================================================
echo ""
echo "[RUN] DOWNLOADING"
echo "=============================================================="

FILE_URL="https://global.download.synology.com/download/Utility/ActiveBackupBusinessAgent/2.7.1-3235/Linux/x86_64/Synology%20Active%20Backup%20for%20Business%20Agent-2.7.1-3235-x64-deb.zip"
TEMP_DIR=$(mktemp -d -t synology_installer_XXXXXX)
ZIP_FILE="${TEMP_DIR}/agent.zip"

echo "Downloading Synology Active Backup Agent..."
if ! ${DOWNLOADER} "${ZIP_FILE}" "${FILE_URL}"; then
    echo ""
    echo "[ERROR] ERROR OCCURRED"
    echo "=============================================================="
    echo "Failed to download the file."
    echo ""
    exit 1
fi
echo "Download completed"

# ============================================================================
# EXTRACT
# ============================================================================
echo ""
echo "[RUN] EXTRACTING"
echo "=============================================================="

echo "Extracting installer..."
if ! unzip "${ZIP_FILE}" -d "${TEMP_DIR}"; then
    echo ""
    echo "[ERROR] ERROR OCCURRED"
    echo "=============================================================="
    echo "Failed to unzip the file."
    echo ""
    exit 1
fi
echo "Extraction completed"

# ============================================================================
# INSTALL
# ============================================================================
echo ""
echo "[RUN] INSTALLING"
echo "=============================================================="

INSTALL_RUN=$(find "${TEMP_DIR}" -type f -name "install.run" | head -n 1)
if [ -z "${INSTALL_RUN}" ]; then
    echo ""
    echo "[ERROR] ERROR OCCURRED"
    echo "=============================================================="
    echo "install.run not found in the archive."
    echo ""
    exit 1
fi

echo "Running installer..."
chmod +x "${INSTALL_RUN}"
if ! "${INSTALL_RUN}"; then
    echo ""
    echo "[ERROR] ERROR OCCURRED"
    echo "=============================================================="
    echo "Installation failed."
    echo ""
    exit 1
fi

# ============================================================================
# CLEANUP
# ============================================================================
echo ""
echo "[RUN] CLEANUP"
echo "=============================================================="

echo "Removing temporary files..."
rm -rf "${TEMP_DIR}"
echo "Cleanup completed"

# ============================================================================
# FINAL STATUS
# ============================================================================
echo ""
echo "[OK] FINAL STATUS"
echo "=============================================================="
echo "Result : SUCCESS"
echo "Synology Active Backup Agent installed successfully"
echo ""
echo "To connect to your NAS: abb-cli -c"
echo "For help: abb-cli -h"

echo ""
echo "[OK] SCRIPT COMPLETE"
echo "=============================================================="

exit 0
