#!/bin/bash
#
# ██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
# ██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
# ██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
# ██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
# ███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
# ╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
# ================================================================================
#  SCRIPT   : SuperOps Agent Reinstall (macOS)                             v1.1.0
#  AUTHOR   : Limehawk.io
#  DATE     : December 2025
#  USAGE    : sudo ./superops_agent_reinstall_macos.sh
# ================================================================================
#  FILE     : superops_agent_reinstall_macos.sh
#  DESCRIPTION : Uninstalls and reinstalls SuperOps RMM agent on macOS
# --------------------------------------------------------------------------------
#  README
# --------------------------------------------------------------------------------
#  PURPOSE
#  Performs a complete reinstallation of the SuperOps RMM agent on macOS by
#  uninstalling the current agent and installing a new version from a provided
#  URL. This is useful for agent upgrades or fixing corrupted installations.
#
#  DATA SOURCES & PRIORITY
#  1) Environment variable (PKGURL - injected by RMM platform)
#  2) SuperOps agent uninstall script (from current installation)
#
#  REQUIRED INPUTS
#  - PKGURL : <provided by RMM environment>
#    (The download URL for the new SuperOps agent .pkg installer)
#  - UninstallScriptPath : "/Library/superops/uninstall.sh"
#    (Path to current agent's uninstall script)
#
#  SETTINGS
#  - Uses background process to handle reinstall after uninstall
#  - Waits for complete uninstallation before installing new version
#  - Downloads new agent to /tmp directory
#  - Monitors agent processes to ensure clean uninstall
#  - 5-second polling interval for uninstall completion
#
#  BEHAVIOR
#  - Validates PKGURL environment variable is set
#  - Validates current agent uninstall script exists
#  - Starts background reinstall process
#  - Background process waits for uninstall to complete
#  - Executes current agent's uninstall script
#  - Background process downloads and installs new agent
#  - Reports progress and status to stdout
#  - Exits with code 0 on success, 1 on failure
#
#  PREREQUISITES
#  - Bash shell
#  - macOS operating system
#  - Sudo privileges (for installation)
#  - Internet access to download new agent
#  - curl command (standard on macOS)
#  - SuperOps RMM agent currently installed
#  - PKGURL environment variable set by RMM platform
#
#  SECURITY NOTES
#  - No secrets hardcoded
#  - New agent URL from environment variable
#  - Uses official SuperOps uninstall script
#  - Requires sudo elevation for installation
#  - Standard macOS installer security
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
#  Uninstall Script: /Library/superops/uninstall.sh
#
#  [ OPERATION ]
#  --------------------------------------------------------------
#  Starting background reinstall process...
#  Background process will wait for uninstall completion
#  Uninstalling current SuperOps agent...
#  Executing uninstall script...
#  Uninstallation completed successfully.
#  [Background] Uninstall detected, waiting for cleanup...
#  [Background] Downloading new agent from URL...
#  [Background] File downloaded successfully.
#  [Background] Starting installation...
#  [Background] Installation completed successfully.
#
#  [ RESULT ]
#  --------------------------------------------------------------
#  Status: Success
#
#  [ FINAL STATUS ]
#  --------------------------------------------------------------
#  SuperOps agent reinstalled successfully
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

# Exit on error (but allow background process to continue)
set -e

# ==== STATE ====
ERROR_OCCURRED=0
ERROR_TEXT=""

# ==== HARDCODED INPUTS (MANDATORY) ====
# PKGURL is expected to be provided by the RMM environment as an environment variable
# If testing locally, set it manually: export PKGURL="https://your-agent-url.pkg"
UNINSTALL_SCRIPT_PATH="/Library/superops/uninstall.sh"
AGENT_DIRECTORY="/Library/superops"
DOWNLOAD_DIRECTORY="/tmp"

# ==== VALIDATION ====
if [ -z "$PKGURL" ]; then
    ERROR_OCCURRED=1
    ERROR_TEXT="PKGURL environment variable is required but not set.
This variable should be injected by the RMM platform.
For manual testing, set it with: export PKGURL='https://your-url.pkg'"
fi

if [ ! -f "$UNINSTALL_SCRIPT_PATH" ]; then
    ERROR_OCCURRED=1
    if [ -n "$ERROR_TEXT" ]; then ERROR_TEXT="$ERROR_TEXT

"; fi
    ERROR_TEXT="${ERROR_TEXT}Uninstall script not found at: $UNINSTALL_SCRIPT_PATH
This could mean:
  - SuperOps agent is not currently installed
  - Agent was installed to a different location
  - Uninstall script was removed or corrupted"
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
    echo "Script cannot proceed. See error details above."
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
echo "Uninstall Script: $UNINSTALL_SCRIPT_PATH"
echo "Agent Directory: $AGENT_DIRECTORY"

echo ""
echo "[ OPERATION ]"
echo "--------------------------------------------------------------"

# Extract filename from URL
BASE_NAME="$(basename "$PKGURL")"
DOWNLOAD_FILE="$DOWNLOAD_DIRECTORY/$BASE_NAME"

echo "Starting background reinstall process..."
echo "Background process will wait for uninstall completion"

# Start the reinstallation process in a separate background process
(
    # Function to check if agent is still installed
    is_agent_installed() {
        [ -d "$AGENT_DIRECTORY" ] || [ -f "$UNINSTALL_SCRIPT_PATH" ]
    }

    # Function to check if agent processes are running
    is_agent_running() {
        pgrep -f "superops" > /dev/null 2>&1
    }

    echo "[Background] Waiting for uninstall to start..."
    # Wait for uninstallation to start (directory/script removed)
    until ! is_agent_installed; do
        sleep 5
    done

    echo "[Background] Uninstall detected, waiting for cleanup..."
    # Wait for agent processes to stop
    until ! is_agent_running; do
        sleep 5
    done

    echo "[Background] Uninstall complete, starting download..."

    # Download the new agent
    echo "[Background] Downloading file from $PKGURL..."
    if ! curl --url "$PKGURL" --output "$DOWNLOAD_FILE"; then
        echo "[Background] ERROR: Failed to download file from $PKGURL"
        exit 1
    fi
    echo "[Background] File downloaded successfully: $DOWNLOAD_FILE"

    # Install the new agent
    echo "[Background] Starting installation process..."
    if ! sudo installer -dumplog -pkg "$DOWNLOAD_FILE" -target /; then
        echo "[Background] ERROR: Installation failed"
        exit 1
    fi

    echo "[Background] Installation process completed successfully"

    # Clean up downloaded file
    echo "[Background] Cleaning up download file..."
    rm -f "$DOWNLOAD_FILE" 2>/dev/null || true

    exit 0
) &

BACKGROUND_PID=$!
echo "Background process started (PID: $BACKGROUND_PID)"

# Now uninstall the current agent
echo "Uninstalling current SuperOps agent..."

if [ -d "$AGENT_DIRECTORY" ]; then
    echo "Changing to agent directory: $AGENT_DIRECTORY"
    cd "$AGENT_DIRECTORY" || {
        ERROR_OCCURRED=1
        ERROR_TEXT="Failed to change to agent directory"
    }
fi

if [ "$ERROR_OCCURRED" -eq 0 ]; then
    echo "Executing uninstall script..."
    if ! bash "$UNINSTALL_SCRIPT_PATH"; then
        ERROR_OCCURRED=1
        ERROR_TEXT="Uninstall script execution failed"
    else
        echo "Uninstallation completed successfully"
        echo "Background process is now installing new agent..."
        echo "Waiting for background installation to complete..."

        # Wait for background process
        if wait $BACKGROUND_PID; then
            echo "Background installation completed successfully"
        else
            ERROR_OCCURRED=1
            ERROR_TEXT="Background installation failed. Check output above for details."
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
    echo "SuperOps agent reinstallation failed. See error details above."
else
    echo "SuperOps agent reinstalled successfully"
fi

echo ""
echo "[ SCRIPT COMPLETED ]"
echo "--------------------------------------------------------------"

if [ "$ERROR_OCCURRED" -eq 1 ]; then
    exit 1
else
    exit 0
fi
