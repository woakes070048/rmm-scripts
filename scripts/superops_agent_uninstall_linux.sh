#!/bin/bash
#
# ██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
# ██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
# ██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
# ██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
# ███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
# ╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
# ================================================================================
#  SCRIPT   : SuperOps Agent Uninstall (Linux)                             v1.1.0
#  AUTHOR   : Limehawk.io
#  DATE     : December 2025
#  USAGE    : sudo ./superops_agent_uninstall_linux.sh
# ================================================================================
#  FILE     : superops_agent_uninstall_linux.sh
#  DESCRIPTION : Uninstalls SuperOps RMM agent from Linux using vendor script
# --------------------------------------------------------------------------------
#  README
# --------------------------------------------------------------------------------
#  PURPOSE
#  Uninstalls the SuperOps RMM agent from Linux systems by executing the
#  agent's built-in uninstall script. This provides a clean removal of the
#  agent and all associated components.
#
#  DATA SOURCES & PRIORITY
#  1) SuperOps agent uninstall script (provided by agent installation)
#  2) Hardcoded installation path
#
#  REQUIRED INPUTS
#  - UninstallScriptPath : "/opt/superopsrmm/uninstall.sh"
#    (Path to the SuperOps-provided uninstall script)
#
#  SETTINGS
#  - Uses the official SuperOps uninstall script
#  - Ensures script is executable before running
#  - Validates script existence before execution
#  - No additional cleanup needed (handled by uninstall script)
#
#  BEHAVIOR
#  - Validates that the uninstall script exists at expected path
#  - Sets executable permissions on the uninstall script
#  - Executes the SuperOps-provided uninstall script
#  - Reports progress and status to stdout
#  - Exits with code 0 on success, 1 on failure
#  - All-or-nothing: any failure stops the script immediately
#
#  PREREQUISITES
#  - Bash shell
#  - Linux operating system
#  - Root/sudo privileges (for uninstallation)
#  - SuperOps RMM agent must be installed
#  - Uninstall script must exist at /opt/superopsrmm/uninstall.sh
#
#  SECURITY NOTES
#  - No secrets or credentials used
#  - Executes only the official SuperOps uninstall script
#  - Requires root privileges to execute
#  - Does not store or transmit any data
#
#  ENDPOINTS
#  - N/A (local uninstallation only)
#
#  EXIT CODES
#  - 0 success
#  - 1 failure
#
#  EXAMPLE RUN (Style A)
#  [ INPUT VALIDATION ]
#  --------------------------------------------------------------
#  Uninstall Script: /opt/superopsrmm/uninstall.sh
#
#  [ OPERATION ]
#  --------------------------------------------------------------
#  Checking for uninstall script...
#  Uninstall script found
#  Setting executable permissions...
#  Executing uninstall script...
#  Removing SuperOps RMM Agent...
#  Stopping services...
#  Removing files...
#  Uninstallation complete
#
#  [ RESULT ]
#  --------------------------------------------------------------
#  Status: Success
#
#  [ FINAL STATUS ]
#  --------------------------------------------------------------
#  SuperOps agent uninstalled successfully
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
# Note: Adjust this path if your SuperOps installation uses a different directory
UNINSTALL_SCRIPT_PATH="/opt/superopsrmm/uninstall.sh"

# ==== VALIDATION ====
if [ -z "$UNINSTALL_SCRIPT_PATH" ]; then
    ERROR_OCCURRED=1
    ERROR_TEXT="UNINSTALL_SCRIPT_PATH is required but not set."
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
    echo "Script cannot proceed. Invalid configuration."
    echo ""
    echo "[ SCRIPT COMPLETED ]"
    echo "--------------------------------------------------------------"
    exit 1
fi

# ==== RUNTIME OUTPUT (Style A) ====
echo ""
echo "[ INPUT VALIDATION ]"
echo "--------------------------------------------------------------"
echo "Uninstall Script: $UNINSTALL_SCRIPT_PATH"

echo ""
echo "[ OPERATION ]"
echo "--------------------------------------------------------------"

# Check if uninstall script exists
echo "Checking for uninstall script..."
if [ ! -f "$UNINSTALL_SCRIPT_PATH" ]; then
    ERROR_OCCURRED=1
    ERROR_TEXT="Uninstall script not found at: $UNINSTALL_SCRIPT_PATH
This could mean:
  - SuperOps agent is not installed
  - Agent was installed to a different location
  - Uninstall script was removed or corrupted

Common installation paths:
  - /opt/superopsrmm/uninstall.sh
  - /opt/SuperOpsRMM/uninstall.sh
  - /usr/local/superops/uninstall.sh"
else
    echo "Uninstall script found"

    # Make script executable
    echo "Setting executable permissions..."
    if ! chmod +x "$UNINSTALL_SCRIPT_PATH"; then
        ERROR_OCCURRED=1
        ERROR_TEXT="Failed to set executable permissions on uninstall script.
You may need to run this script with sudo."
    fi
fi

# Execute uninstall if no errors
if [ "$ERROR_OCCURRED" -eq 0 ]; then
    echo "Executing uninstall script..."

    # Run the uninstall script
    if ! "$UNINSTALL_SCRIPT_PATH"; then
        ERROR_OCCURRED=1
        ERROR_TEXT="Uninstall script execution failed.
Check the output above for specific error messages from the uninstaller."
    else
        echo "Uninstall script completed successfully"
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
    echo "SuperOps agent uninstallation failed. See error details above."
else
    echo "SuperOps agent uninstalled successfully"
fi

echo ""
echo "[ SCRIPT COMPLETED ]"
echo "--------------------------------------------------------------"

if [ "$ERROR_OCCURRED" -eq 1 ]; then
    exit 1
else
    exit 0
fi
