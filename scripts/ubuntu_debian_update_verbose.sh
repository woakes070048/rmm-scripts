#!/bin/bash
#
# ============================================================================
#                        SYSTEM UPDATE AUTOMATION SCRIPT
# ============================================================================
#  Script Name: ubuntu_debian_update_verbose.sh
#  Description: Automated system update script for Ubuntu/Debian systems with
#               verbose output, color-coded status messages, and configurable
#               update options. Handles package updates, cleanup, and reboot
#               detection with clear success/failure reporting.
#  Author:      Limehawk LLC
#  Version:     1.0.0
#  Date:        November 2024
#  Usage:       sudo ./ubuntu_debian_update_verbose.sh
# ============================================================================
#
# ============================================================================
# CONFIGURATION SETTINGS - Modify these as needed
# ============================================================================
ENSURE_APT_UTILS=true                 # Ensure apt-utils is installed (recommended)
ENABLE_FULL_UPGRADE=false             # Use dist-upgrade instead of upgrade (set to false)
ENABLE_AUTOREMOVE=true                 # Remove unused packages
ENABLE_CACHE_CLEAN=true                # Clean apt cache
ENABLE_COLOR_OUTPUT=true              # Use colored output

# ============================================================================
# ENVIRONMENT SETTINGS
# ============================================================================
export DEBIAN_FRONTEND=noninteractive

# --- Define Colors ---
if [ "$ENABLE_COLOR_OUTPUT" = true ]; then
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    RED='\033[0;31m'
    NC='\033[0m'
else
    GREEN=''
    YELLOW=''
    RED=''
    NC=''
fi

# --- Helper Function ---
run_task_verbose() {
    local description="$1"
    shift
    
    echo -e "\n${YELLOW}--- Starting: $description ---${NC}"
    
    "$@"
    local status=$?
    
    if [ $status -eq 0 ]; then
        echo -e "${GREEN}+++ Success: $description +++${NC}"
    else
        echo -e "\n${RED}!!! FAILED: $description (Exit Code: $status) !!!${NC}"
        echo -e "${RED}Halting script due to error.${NC}"
        exit $status
    fi
}

# ============================================================================
# MAIN SCRIPT EXECUTION
# ============================================================================
echo -e "${GREEN}=== Starting System Update ===${NC}"

run_task_verbose "Updating package lists" apt-get update

# Ensure apt-utils is installed first (only installs if missing)
if [ "$ENSURE_APT_UTILS" = true ]; then
    if ! dpkg -l | grep -q "^ii.*apt-utils"; then
        run_task_verbose "Installing apt-utils for proper package configuration" apt-get install -y apt-utils
    else
        echo -e "${GREEN}--- apt-utils already installed ---${NC}"
    fi
fi

if [ "$ENABLE_FULL_UPGRADE" = true ]; then
    run_task_verbose "Performing full system upgrade" apt-get dist-upgrade -y --no-install-recommends
else
    run_task_verbose "Upgrading all system packages" apt-get upgrade -y --no-install-recommends
fi

if [ "$ENABLE_AUTOREMOVE" = true ]; then
    run_task_verbose "Removing unused packages" apt-get autoremove -y --purge
fi

if [ "$ENABLE_CACHE_CLEAN" = true ]; then
    run_task_verbose "Cleaning up apt cache" apt-get clean
fi

echo -e "\n${GREEN}=== All System Update Tasks Complete ===${NC}"

if [ -f /var/run/reboot-required ]; then
    echo -e "\n${YELLOW}*** System reboot required ***${NC}"
fi
