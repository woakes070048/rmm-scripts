#!/bin/bash
#
# ██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
# ██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
# ██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
# ██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
# ███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
# ╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
# ================================================================================
#  SCRIPT   : Ubuntu/Debian System Update (Verbose)                        v1.1.2
#  AUTHOR   : Limehawk.io
#  DATE     : January 2026
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
#  DATA SOURCES & PRIORITY
#
#    Not applicable - uses system-configured apt repositories
#
#  REQUIRED INPUTS
#
#    All inputs are hardcoded in the SETTINGS section:
#      - ENSURE_APT_UTILS: Install apt-utils if missing
#      - ENABLE_FULL_UPGRADE: Use dist-upgrade instead of upgrade
#      - ENABLE_AUTOREMOVE: Remove unused packages after upgrade
#      - ENABLE_CACHE_CLEAN: Clean apt cache to free disk space
#      - ENABLE_COLOR_OUTPUT: Use colored terminal output
#
#  ENDPOINTS
#
#    System-configured apt repositories (varies by installation)
#
#  SETTINGS
#
#    - ENSURE_APT_UTILS: Install apt-utils if missing (recommended: true)
#    - ENABLE_FULL_UPGRADE: Use dist-upgrade instead of upgrade (default: false)
#    - ENABLE_AUTOREMOVE: Remove unused packages after upgrade (default: true)
#    - ENABLE_CACHE_CLEAN: Clean apt cache to free disk space (default: true)
#    - ENABLE_COLOR_OUTPUT: Use colored terminal output (default: true)
#
#  BEHAVIOR
#
#    1. Updates package lists from repositories
#    2. Ensures apt-utils is installed for proper configuration
#    3. Upgrades all system packages (or performs dist-upgrade if enabled)
#    4. Removes unused packages and dependencies if enabled
#    5. Cleans apt cache if enabled
#    6. Checks if system reboot is required and notifies user
#
#  PREREQUISITES
#
#    - Root/sudo access required
#    - Ubuntu or Debian-based Linux distribution
#    - Network connectivity to package repositories
#    - apt package manager
#
#  SECURITY NOTES
#
#    - No secrets exposed in output
#    - Uses DEBIAN_FRONTEND=noninteractive to prevent interactive prompts
#    - Runs with elevated privileges (sudo required)
#
#  EXIT CODES
#
#    0 = Success (all updates completed)
#    1 = Failure (error occurred during execution)
#
#  EXAMPLE RUN
#
#    [RUN] STARTING SYSTEM UPDATE
#    ==============================================================
#
#    [RUN] Updating package lists
#    ==============================================================
#    Hit:1 http://archive.ubuntu.com/ubuntu jammy InRelease
#    [OK] Updating package lists
#
#    [INFO] apt-utils already installed
#
#    [RUN] Upgrading all system packages
#    ==============================================================
#    Reading package lists...
#    Building dependency tree...
#    [OK] Upgrading all system packages
#
#    [RUN] Removing unused packages
#    ==============================================================
#    [OK] Removing unused packages
#
#    [RUN] Cleaning up apt cache
#    ==============================================================
#    [OK] Cleaning up apt cache
#
#    [OK] ALL SYSTEM UPDATE TASKS COMPLETE
#    ==============================================================
#
#    [WARN] System reboot required
#
# --------------------------------------------------------------------------------
#  CHANGELOG
# --------------------------------------------------------------------------------
#  2026-01-20 v1.1.2 Fixed README structure for framework compliance
#  2026-01-19 v1.1.1 Updated to two-line ASCII console output style
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

    echo ""
    echo -e "${YELLOW}[RUN] $description${NC}"
    echo "=============================================================="

    "$@"
    local status=$?

    if [ $status -eq 0 ]; then
        echo -e "${GREEN}[OK] $description${NC}"
    else
        echo ""
        echo -e "${RED}[ERROR] $description (Exit Code: $status)${NC}"
        echo "=============================================================="
        echo -e "${RED}Halting script due to error.${NC}"
        exit 1
    fi
}

# ============================================================================
# MAIN SCRIPT EXECUTION
# ============================================================================
echo ""
echo -e "${GREEN}[RUN] STARTING SYSTEM UPDATE${NC}"
echo "=============================================================="

run_task_verbose "Updating package lists" apt-get update

# Ensure apt-utils is installed first (only installs if missing)
if [ "$ENSURE_APT_UTILS" = true ]; then
    if ! dpkg -l | grep -q "^ii.*apt-utils"; then
        run_task_verbose "Installing apt-utils for proper package configuration" apt-get install -y apt-utils
    else
        echo -e "${GREEN}[INFO] apt-utils already installed${NC}"
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

echo ""
echo -e "${GREEN}[OK] ALL SYSTEM UPDATE TASKS COMPLETE${NC}"
echo "=============================================================="

if [ -f /var/run/reboot-required ]; then
    echo ""
    echo -e "${YELLOW}[WARN] System reboot required${NC}"
fi

exit 0
