#!/bin/bash
#
# ██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
# ██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
# ██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
# ██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
# ███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
# ╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
# ================================================================================
#  SCRIPT   : SuperOps Agent Install (macOS)                               v1.1.0
#  AUTHOR   : Limehawk.io
#  DATE     : December 2025
#  USAGE    : sudo ./superops_agent_install_macos.sh
# ================================================================================
#  FILE     : superops_agent_install_macos.sh
#  DESCRIPTION : Downloads and installs SuperOps RMM agent on macOS via PKG
# --------------------------------------------------------------------------------
#  README
# --------------------------------------------------------------------------------
#  PURPOSE
#  Downloads and installs the SuperOps RMM agent on macOS systems using the PKG
#  installer format. This script is designed for automated deployment in RMM
#  environments where the package download URL is provided as an environment
#  variable.
#
#  DATA SOURCES & PRIORITY
#  1) Environment variable (PKGURL - injected by RMM platform)
#  2) Error
#
#  REQUIRED INPUTS
#  - PKGURL : <provided by RMM environment>
#    (The download URL for the SuperOps agent .pkg installer. This is typically
#     injected by the RMM platform as an environment variable.)
#
#  SETTINGS
#  - Downloads to /Users/Shared directory (accessible to all users)
#  - Uses macOS installer command for PKG installation
#  - Requires sudo privileges for installation
#  - Includes -dumplog flag for detailed installation logging
#  - Cleans up by design (installer handles cleanup)
#
#  BEHAVIOR
#  - Validates that PKGURL environment variable is set
#  - Extracts filename from URL using basename
#  - Downloads the SuperOps agent PKG to /Users/Shared
#  - Installs silently using macOS installer command to root (/)
#  - Reports progress and status to stdout
#  - Exits with code 0 on success, 1 on failure
#  - All-or-nothing: any failure stops the script immediately
#
#  PREREQUISITES
#  - Bash shell
#  - macOS operating system
#  - Sudo privileges (for installation)
#  - Internet access to download agent installer
#  - curl command (standard on macOS)
#  - PKGURL environment variable must be set by RMM platform
#
#  SECURITY NOTES
#  - No secrets are hardcoded in this script
#  - Agent URL is provided by RMM environment variable
#  - Uses HTTPS for secure download (if URL is HTTPS)
#  - Requires sudo elevation for installation
#  - PKG is executed with standard macOS installer security
#
#  ENDPOINTS
#  - SuperOps agent download URL (provided via PKGURL variable)
#
#  EXIT CODES
#  - 0 success
#  - 1 failure
#
#  EXAMPLE RUN (Style A)
#  [ INPUT VALIDATION ]
#  --------------------------------------------------------------
#  Package URL: https://app.superops.com/downloads/agent.pkg
#
#  [ OPERATION ]
#  --------------------------------------------------------------
#  Downloading file from https://app.superops.com/downloads/agent.pkg...
#  File downloaded successfully.
#  Download location: /Users/Shared/agent.pkg
#  Starting the installation process...
#  installer: Package name is SuperOps RMM Agent
#  installer: Installing at base path /
#  installer: The install was successful.
#  Installation process completed successfully.
#
#  [ RESULT ]
#  --------------------------------------------------------------
#  Status: Success
#
#  [ FINAL STATUS ]
#  --------------------------------------------------------------
#  SuperOps agent installed successfully
#
#  [ SCRIPT COMPLETED ]
#  --------------------------------------------------------------
# --------------------------------------------------------------------------------
# --------------------------------------------------------------------------------
#  CHANGELOG
# --------------------------------------------------------------------------------
#  2025-12-23 v1.1.0 Updated to Limehawk Script Framework
#  2024-11-02 v1.0.0 Initial migration from SuperOps
# ================================================================================

# Exit on error
set -e

# ==== STATE ====
ERROR_OCCURRED=0
ERROR_TEXT=""

# ==== HARDCODED INPUTS (MANDATORY) ====
# PKGURL is expected to be provided by the RMM environment as an environment variable
# If testing locally, set it manually: export PKGURL="https://your-agent-url.pkg"

# ==== VALIDATION ====
if [ -z "$PKGURL" ]; then
    ERROR_OCCURRED=1
    ERROR_TEXT="PKGURL environment variable is required but not set.
This variable should be injected by the RMM platform.
For manual testing, set it with: export PKGURL='https://your-url.pkg'"
fi

if [ "$ERROR_OCCURRED" -eq 1 ]; then
    echo ""
    echo "[ ERROR OCCURRED ]"
    echo "--------------------------------------------------------------"
    echo "$ERROR_TEXT"
    echo ""
    echo "[ RESULT ]"
    echo "--------------------------------------------------------------"
    echo "Status: Failure"
    echo ""
    echo "[ FINAL STATUS ]"
    echo "--------------------------------------------------------------"
    echo "Script cannot proceed. PKGURL environment variable is missing."
    echo ""
    echo "[ SCRIPT COMPLETED ]"
    echo "--------------------------------------------------------------"
    exit 1
fi

# ==== RUNTIME OUTPUT (Style A) ====
echo ""
echo "[ INPUT VALIDATION ]"
echo "--------------------------------------------------------------"
echo "Package URL: $PKGURL"

# Extract filename from URL
BASE_NAME="$(basename "$PKGURL")"
DOWNLOAD_FILE="/Users/Shared/$BASE_NAME"

echo "Target file: $DOWNLOAD_FILE"

echo ""
echo "[ OPERATION ]"
echo "--------------------------------------------------------------"

# Download the file and handle any errors
echo "Downloading file from $PKGURL..."
if ! curl --url "$PKGURL" --output "$DOWNLOAD_FILE"; then
    ERROR_OCCURRED=1
    ERROR_TEXT="Failed to download file from $PKGURL"
else
    echo "File downloaded successfully."

    # Check file size
    if [ -f "$DOWNLOAD_FILE" ]; then
        FILE_SIZE=$(stat -f%z "$DOWNLOAD_FILE" 2>/dev/null || stat -c%s "$DOWNLOAD_FILE" 2>/dev/null || echo "0")
        FILE_SIZE_MB=$((FILE_SIZE / 1024 / 1024))
        echo "Download location: $DOWNLOAD_FILE"
        echo "File size: ${FILE_SIZE_MB} MB"
    else
        ERROR_OCCURRED=1
        ERROR_TEXT="Downloaded file not found after download operation"
    fi
fi

# Install the package if download succeeded
if [ "$ERROR_OCCURRED" -eq 0 ]; then
    echo "Starting the installation process..."

    # Change to download directory
    cd /Users/Shared || {
        ERROR_OCCURRED=1
        ERROR_TEXT="Failed to change to /Users/Shared directory"
    }

    if [ "$ERROR_OCCURRED" -eq 0 ]; then
        # Install the package
        if ! sudo -S installer -dumplog -pkg "$BASE_NAME" -target /; then
            ERROR_OCCURRED=1
            ERROR_TEXT="Failed to execute installer command"
        else
            echo "Installation process completed successfully."
        fi
    fi
fi

# ==== OUTPUT RESULTS ====
if [ "$ERROR_OCCURRED" -eq 1 ]; then
    echo ""
    echo "[ ERROR OCCURRED ]"
    echo "--------------------------------------------------------------"
    echo "$ERROR_TEXT"
fi

echo ""
echo "[ RESULT ]"
echo "--------------------------------------------------------------"
if [ "$ERROR_OCCURRED" -eq 1 ]; then
    echo "Status: Failure"
else
    echo "Status: Success"
fi

echo ""
echo "[ FINAL STATUS ]"
echo "--------------------------------------------------------------"
if [ "$ERROR_OCCURRED" -eq 1 ]; then
    echo "SuperOps agent installation failed. See error details above."
else
    echo "SuperOps agent installed successfully"
fi

echo ""
echo "[ SCRIPT COMPLETED ]"
echo "--------------------------------------------------------------"

if [ "$ERROR_OCCURRED" -eq 1 ]; then
    exit 1
else
    exit 0
fi
