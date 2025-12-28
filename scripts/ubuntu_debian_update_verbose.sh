#!/bin/bash
#
# ██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
# ██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
# ██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
# ██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
# ███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
# ╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
# ================================================================================
#  SCRIPT   : Ubuntu/Debian System Update (Verbose)                        v1.1.0
#  AUTHOR   : Limehawk.io
#  DATE     : December 2025
#  USAGE    : sudo ./ubuntu_debian_update_verbose.sh
# ================================================================================
#  FILE     : ubuntu_debian_update_verbose.sh
#  DESCRIPTION : Updates all packages on Ubuntu/Debian with verbose output
# --------------------------------------------------------------------------------
#  README
# --------------------------------------------------------------------------------
#  PURPOSE
#
#    Automates system package updates for Ubuntu/Debian systems with verbose
#  output and error handling. Updates package lists, upgrades installed
#  packages, removes unused dependencies, and cleans package cache.
#  Provides color-coded status messages and reboot detection.
#
#  CONFIGURATION
#  -----------------------------------------------------------------------
#  - ENSURE_APT_UTILS: Install apt-utils if missing (recommended: true)
#  - ENABLE_FULL_UPGRADE: Use dist-upgrade instead of upgrade (default: false)
#  - ENABLE_AUTOREMOVE: Remove unused packages after upgrade (default: true)
#  - ENABLE_CACHE_CLEAN: Clean apt cache to free disk space (default: true)
#  - ENABLE_COLOR_OUTPUT: Use colored terminal output (default: true)
#
#  BEHAVIOR
#  -----------------------------------------------------------------------
#  1. Updates package lists from repositories
#  2. Ensures apt-utils is installed for proper configuration
#  3. Upgrades all system packages (or performs dist-upgrade if enabled)
#  4. Removes unused packages and dependencies if enabled
#  5. Cleans apt cache if enabled
#  6. Checks if system reboot is required and notifies user
#
#  PREREQUISITES
#  -----------------------------------------------------------------------
#  - Root/sudo access required
#  - Ubuntu or Debian-based Linux distribution
#  - Network connectivity to package repositories
#  - apt package manager
#
#  SECURITY NOTES
#  -----------------------------------------------------------------------
#  - No secrets exposed in output
#  - Uses DEBIAN_FRONTEND=noninteractive to prevent interactive prompts
#  - Runs with elevated privileges (sudo required)
#
#  EXIT CODES
#  -----------------------------------------------------------------------
#  0 - Success (all updates completed)
#  Non-zero - Failure (error occurred during execution)
#
#  EXAMPLE OUTPUT
#  -----------------------------------------------------------------------
#  === Starting System Update ===
#
#  --- Starting: Updating package lists ---
#  Hit:1 http://archive.ubuntu.com/ubuntu jammy InRelease
#  +++ Success: Updating package lists +++
#
#  --- apt-utils already installed ---
#
#  --- Starting: Upgrading all system packages ---
#  Reading package lists...
#  Building dependency tree...
#  +++ Success: Upgrading all system packages +++
#
#  --- Starting: Removing unused packages ---
#  +++ Success: Removing unused packages +++
#
#  --- Starting: Cleaning up apt cache ---
#  +++ Success: Cleaning up apt cache +++
#
#  === All System Update Tasks Complete ===
#
#  *** System reboot required ***
#
# --------------------------------------------------------------------------------
#  CHANGELOG
# --------------------------------------------------------------------------------
#  2025-12-23 v1.1.0 Updated to Limehawk Script Framework
#  2024-11-18 v1.0.0 Initial release
# ================================================================================

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
