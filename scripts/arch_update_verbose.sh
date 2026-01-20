#!/bin/bash
#
# ██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
# ██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
# ██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
# ██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
# ███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
# ╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
# ================================================================================
#  SCRIPT   : Arch/Omarchy System Update (Verbose)                          v1.0.0
#  AUTHOR   : Limehawk.io
#  DATE     : January 2026
#  USAGE    : sudo ./arch_update_verbose.sh
# ================================================================================
#  FILE     : arch_update_verbose.sh
#  DESCRIPTION : Updates all packages on Arch Linux/Omarchy with verbose output
# --------------------------------------------------------------------------------
#  README
# --------------------------------------------------------------------------------
#  PURPOSE
#
#    Automates system package updates for Arch Linux and Omarchy systems with
#    verbose output and error handling. Syncs package databases, upgrades all
#    packages, removes orphaned dependencies, and cleans package cache.
#    Provides color-coded status messages.
#
#  DATA SOURCES & PRIORITY
#
#    Not applicable - uses system-configured pacman mirrors
#
#  REQUIRED INPUTS
#
#    All inputs are hardcoded in the SETTINGS section:
#      - ENABLE_ORPHAN_REMOVAL: Remove orphaned packages after upgrade
#      - ENABLE_CACHE_CLEAN: Clean pacman cache to free disk space
#      - ENABLE_COLOR_OUTPUT: Use colored terminal output
#
#  ENDPOINTS
#
#    System-configured pacman mirrors (varies by installation)
#
#  SETTINGS
#
#    - ENABLE_ORPHAN_REMOVAL: Remove orphaned packages after upgrade (default: true)
#    - ENABLE_CACHE_CLEAN: Clean pacman cache to free disk space (default: true)
#    - ENABLE_COLOR_OUTPUT: Use colored terminal output (default: true)
#
#  BEHAVIOR
#
#    1. Syncs package databases and upgrades all system packages
#    2. Removes orphaned packages and dependencies if enabled
#    3. Cleans pacman cache if enabled (keeps last 2 versions)
#
#  PREREQUISITES
#
#    - Root/sudo access required
#    - Arch Linux or Arch-based distribution (Omarchy, EndeavourOS, Manjaro, etc.)
#    - Network connectivity to package mirrors
#    - pacman package manager
#
#  SECURITY NOTES
#
#    - No secrets exposed in output
#    - Uses --noconfirm to prevent interactive prompts
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
#    [RUN] Syncing databases and upgrading packages
#    ==============================================================
#    :: Synchronizing package databases...
#     core is up to date
#     extra is up to date
#    :: Starting full system upgrade...
#     there is nothing to do
#    [OK] Syncing databases and upgrading packages
#
#    [INFO] No orphaned packages found
#
#    [RUN] Cleaning pacman cache (keeping last 2 versions)
#    ==============================================================
#    [OK] Cleaning pacman cache (keeping last 2 versions)
#
#    [OK] ALL SYSTEM UPDATE TASKS COMPLETE
#    ==============================================================
#
# --------------------------------------------------------------------------------
#  CHANGELOG
# --------------------------------------------------------------------------------
#  2026-01-20 v1.0.0 Initial release
# ================================================================================

# ============================================================================
# CONFIGURATION SETTINGS - Modify these as needed
# ============================================================================
ENABLE_ORPHAN_REMOVAL=true            # Remove orphaned packages
ENABLE_CACHE_CLEAN=true               # Clean pacman cache
ENABLE_COLOR_OUTPUT=true              # Use colored output

# ============================================================================
# ENVIRONMENT SETTINGS
# ============================================================================

# --- Trap Handler for Interrupted Upgrades ---
cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        echo ""
        echo -e "${YELLOW}[WARN] Script interrupted${NC}"
        # Remove pacman lock if it exists and we were interrupted
        if [ -f /var/lib/pacman/db.lck ]; then
            echo -e "${YELLOW}[WARN] Removing pacman lock file...${NC}"
            rm -f /var/lib/pacman/db.lck
        fi
    fi
}
trap cleanup EXIT

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

# Full system upgrade (sync databases + upgrade all packages)
run_task_verbose "Syncing databases and upgrading packages" pacman -Syu --noconfirm

# Remove orphaned packages
if [ "$ENABLE_ORPHAN_REMOVAL" = true ]; then
    orphans=$(pacman -Qdtq 2>/dev/null)
    if [ -n "$orphans" ]; then
        run_task_verbose "Removing orphaned packages" pacman -Rns --noconfirm $orphans
    else
        echo ""
        echo -e "${GREEN}[INFO] No orphaned packages found${NC}"
    fi
fi

# Clean pacman cache (keep last 2 versions of each package)
if [ "$ENABLE_CACHE_CLEAN" = true ]; then
    if command -v paccache &> /dev/null; then
        run_task_verbose "Cleaning pacman cache (keeping last 2 versions)" paccache -rk2
    else
        echo ""
        echo -e "${YELLOW}[INFO] paccache not found, using pacman -Sc instead${NC}"
        run_task_verbose "Cleaning pacman cache" pacman -Sc --noconfirm
    fi
fi

echo ""
echo -e "${GREEN}[OK] ALL SYSTEM UPDATE TASKS COMPLETE${NC}"
echo "=============================================================="

exit 0
