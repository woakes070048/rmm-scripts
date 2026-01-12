#!/bin/bash
#
# ██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
# ██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
# ██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
# ██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
# ███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
# ╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
# ================================================================================
#  SCRIPT   : Huntress Agent Install (macOS)                               v2.0.0
#  AUTHOR   : Limehawk.io (based on Huntress Labs installer)
#  DATE     : January 2026
#  USAGE    : sudo ./huntress_install_macos.sh
# ================================================================================
#  FILE     : huntress_install_macos.sh
#  DESCRIPTION : Installs Huntress Agent on macOS endpoints
# --------------------------------------------------------------------------------
#  README
# --------------------------------------------------------------------------------
#  PURPOSE
#
#    Downloads and installs the Huntress Agent on macOS systems. Huntress provides
#    managed detection and response (MDR) services. This script handles the
#    download, validation, and installation of the agent with proper logging.
#
#  DATA SOURCES & PRIORITY
#
#    - Huntress API: Downloads installer script from huntress.io
#    - Local filesystem: Stores temporary installer and logs
#
#  REQUIRED INPUTS
#
#    All inputs are hardcoded in the script body:
#      - ACCOUNT_KEY: Your Huntress account secret key (32-char hex)
#      - ORG_KEY: Organization key for agent affiliation
#      - INSTALL_SYSTEM_EXTENSION: Whether to install system extension
#
#  SETTINGS
#
#    Configuration details and default values:
#      - RMM Name: Superops.ai (reported to Huntress for deployment tracking)
#      - Log file: /tmp/HuntressInstaller.log
#      - Install script: /tmp/HuntressMacInstall.sh
#      - System extension: false by default (requires MDM pre-configuration)
#
#  BEHAVIOR
#
#    The script performs the following actions in order:
#    1. Validates root privileges
#    2. Validates account key format (32-character hex)
#    3. Downloads Huntress installer from API
#    4. Validates downloaded script
#    5. Executes installer with provided keys
#    6. Reports success or failure
#
#  PREREQUISITES
#
#    - macOS operating system
#    - Root/sudo privileges
#    - Network connectivity to huntress.io
#    - Valid Huntress account key and organization key
#    - For system extension: MDM pre-configuration required
#
#  SECURITY NOTES
#
#    - Account key is masked in logs (shows first/last 4 chars only)
#    - No secrets exposed in console output
#    - Installer downloaded over HTTPS
#
#  ENDPOINTS
#
#    - https://huntress.io/script/darwin/{account_key} - Installer download
#
#  EXIT CODES
#
#    0 = Success - Huntress agent installed successfully
#    1 = Failure - validation error, download failed, or install failed
#
#  EXAMPLE RUN
#
#    [ INPUT VALIDATION ]
#    --------------------------------------------------------------
#    All required inputs are valid
#
#    [ DOWNLOADING INSTALLER ]
#    --------------------------------------------------------------
#    Downloading Huntress installer
#    Download complete
#
#    [ INSTALLING HUNTRESS AGENT ]
#    --------------------------------------------------------------
#    Running Huntress installer
#    Installation complete
#
#    [ FINAL STATUS ]
#    --------------------------------------------------------------
#    Result : SUCCESS
#
#    [ SCRIPT COMPLETE ]
#    --------------------------------------------------------------
#
#  LICENSE
#
#    Original installer script: Copyright (c) 2024 Huntress Labs, Inc.
#    BSD 3-Clause License. See https://huntress.io for details.
#
# --------------------------------------------------------------------------------
#  CHANGELOG
# --------------------------------------------------------------------------------
#  2026-01-12 v2.0.0 Converted to Limehawk Script Framework format
#  2024-01-01 v1.0.0 Original Huntress Labs installer
# ================================================================================

# ============================================================================
# HARDCODED INPUTS
# ============================================================================
ACCOUNT_KEY=""                    # Your Huntress account secret key (32-char hex)
ORG_KEY=""                        # Organization key for agent affiliation
INSTALL_SYSTEM_EXTENSION=false    # Set to true if MDM is pre-configured
RMM_NAME="Superops.ai"            # RMM name for Huntress tracking

# ============================================================================
# INTERNAL VARIABLES
# ============================================================================
LOG_FILE="/tmp/HuntressInstaller.log"
INSTALL_SCRIPT="/tmp/HuntressMacInstall.sh"
INVALID_KEY_MSG="Invalid account secret key"
KEY_PATTERN="[a-f0-9]{32}"
SCRIPT_VERSION="2.0.0"
TIMESTAMP=$(date "+%Y%m%d-%H%M%S")

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

log_message() {
    echo "$TIMESTAMP -- $*"
    echo "$TIMESTAMP -- $*" >> "$LOG_FILE"
}

mask_key() {
    local key="$1"
    echo "${key:0:4}************************${key: -4}"
}

# ============================================================================
# INPUT VALIDATION
# ============================================================================
echo ""
echo "[ INPUT VALIDATION ]"
echo "--------------------------------------------------------------"

ERROR_OCCURRED=false
ERROR_TEXT=""

# Check root privileges
if [ "$EUID" -ne 0 ]; then
    ERROR_OCCURRED=true
    ERROR_TEXT="${ERROR_TEXT}\n- Script must be run as root (use sudo)"
fi

# Validate account key
if [[ -z "$ACCOUNT_KEY" ]]; then
    ERROR_OCCURRED=true
    ERROR_TEXT="${ERROR_TEXT}\n- ACCOUNT_KEY is required"
elif ! [[ "$ACCOUNT_KEY" =~ $KEY_PATTERN ]]; then
    ERROR_OCCURRED=true
    ERROR_TEXT="${ERROR_TEXT}\n- ACCOUNT_KEY must be a 32-character hex string"
fi

# Validate org key
if [[ -z "$ORG_KEY" ]]; then
    ERROR_OCCURRED=true
    ERROR_TEXT="${ERROR_TEXT}\n- ORG_KEY is required"
fi

if [[ "$ERROR_OCCURRED" = true ]]; then
    echo ""
    echo "[ ERROR OCCURRED ]"
    echo "--------------------------------------------------------------"
    echo -e "$ERROR_TEXT"
    echo ""
    exit 1
fi

echo "All required inputs are valid"
log_message "=========== INSTALL START AT $TIMESTAMP ==============="
log_message "=========== $RMM_NAME Deployment Script | Version: $SCRIPT_VERSION ==============="
log_message "Provided Huntress key: $(mask_key "$ACCOUNT_KEY")"
log_message "Provided Organization Key: $ORG_KEY"

# ============================================================================
# CLEANUP OLD INSTALLER
# ============================================================================
if [ -f "$INSTALL_SCRIPT" ]; then
    log_message "Removing old installer file"
    rm -f "$INSTALL_SCRIPT"
fi

# ============================================================================
# DOWNLOAD INSTALLER
# ============================================================================
echo ""
echo "[ DOWNLOADING INSTALLER ]"
echo "--------------------------------------------------------------"
echo "Downloading Huntress installer"

DOWNLOAD_URL="https://huntress.io/script/darwin/$ACCOUNT_KEY"
HTTP_CODE=$(curl -w "%{http_code}" -sL "$DOWNLOAD_URL" -o "$INSTALL_SCRIPT" 2>/dev/null)

if [ $? -ne 0 ]; then
    echo ""
    echo "[ ERROR OCCURRED ]"
    echo "--------------------------------------------------------------"
    echo "Download failed"
    echo "HTTP Code : $HTTP_CODE"
    log_message "ERROR: Download failed with HTTP code: $HTTP_CODE"
    echo ""
    exit 1
fi

# Validate downloaded script
if grep -Fq "$INVALID_KEY_MSG" "$INSTALL_SCRIPT" 2>/dev/null; then
    echo ""
    echo "[ ERROR OCCURRED ]"
    echo "--------------------------------------------------------------"
    echo "Invalid account key"
    echo "The provided ACCOUNT_KEY was rejected by Huntress"
    log_message "ERROR: ACCOUNT_KEY is invalid"
    rm -f "$INSTALL_SCRIPT"
    echo ""
    exit 1
fi

echo "Download complete"
log_message "Installer downloaded successfully"

# ============================================================================
# INSTALL HUNTRESS AGENT
# ============================================================================
echo ""
echo "[ INSTALLING HUNTRESS AGENT ]"
echo "--------------------------------------------------------------"
echo "Running Huntress installer"

INSTALL_CMD="/bin/zsh $INSTALL_SCRIPT -a $ACCOUNT_KEY -o $ORG_KEY -v"
if [ "$INSTALL_SYSTEM_EXTENSION" = true ]; then
    INSTALL_CMD="$INSTALL_CMD --install_system_extension"
    echo "System extension : enabled"
fi

log_message "=============== Begin Installer Logs ==============="
INSTALL_RESULT=$(eval "$INSTALL_CMD" 2>&1)
INSTALL_STATUS=$?

log_message "$INSTALL_RESULT"

if [ $INSTALL_STATUS -ne 0 ]; then
    echo ""
    echo "[ ERROR OCCURRED ]"
    echo "--------------------------------------------------------------"
    echo "Installation failed"
    echo "Check log file : $LOG_FILE"
    log_message "Installer Error: $INSTALL_RESULT"
    echo ""
    exit 1
fi

echo "Installation complete"
log_message "=========== INSTALL FINISHED AT $TIMESTAMP ==============="

# ============================================================================
# CLEANUP
# ============================================================================
rm -f "$INSTALL_SCRIPT"

# ============================================================================
# FINAL STATUS
# ============================================================================
echo ""
echo "[ FINAL STATUS ]"
echo "--------------------------------------------------------------"
echo "Result : SUCCESS"
echo "Log file : $LOG_FILE"

echo ""
echo "[ SCRIPT COMPLETE ]"
echo "--------------------------------------------------------------"
echo ""

exit 0
