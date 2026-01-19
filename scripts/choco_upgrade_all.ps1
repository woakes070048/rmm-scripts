$ErrorActionPreference = 'Stop'
<#
██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝

================================================================================
 SCRIPT   : Chocolatey Upgrade All                                       v1.2.1
 AUTHOR   : Limehawk.io
 DATE     : January 2026
 USAGE    : .\choco_upgrade_all.ps1
================================================================================
 FILE     : choco_upgrade_all.ps1
 DESCRIPTION : Upgrades all Chocolatey-managed packages to latest versions
--------------------------------------------------------------------------------
 README
--------------------------------------------------------------------------------
 PURPOSE

   Upgrades all Chocolatey-managed packages to their latest versions using the
   choco upgrade all command with automatic confirmation.

 DATA SOURCES & PRIORITY

   - Chocolatey package manager: Local package database and configured sources
   - Internet: Package downloads from Chocolatey community repository or
     configured private feeds

 REQUIRED INPUTS

   All inputs are hardcoded in the script body:
     - None required - script operates on all installed Chocolatey packages

 SETTINGS

   Configuration details and default values:
     - Auto-confirm: Enabled (-y flag) to allow unattended operation
     - Scope: All packages managed by Chocolatey

 BEHAVIOR

   The script performs the following actions in order:
   1. Checks if Chocolatey is installed on the system
   2. Runs choco upgrade all with auto-confirmation flag
   3. Reports final upgrade status

 PREREQUISITES

   - Windows OS
   - Administrator privileges
   - Chocolatey package manager installed

 SECURITY NOTES

   - No secrets in logs
   - Package downloads use configured Chocolatey sources
   - Requires elevated privileges for package installation

 ENDPOINTS

   - https://community.chocolatey.org - Default Chocolatey community repository
   - Additional endpoints depend on configured Chocolatey sources

 EXIT CODES

   0 = Success
   1 = Failure (Chocolatey not installed)

 EXAMPLE RUN

   [INFO] CHOCOLATEY CHECK
   ==============================================================
     Checking for Chocolatey...
     Chocolatey is installed

   [RUN] UPGRADE
   ==============================================================
     Upgrading all Chocolatey packages...
     [Chocolatey output...]
     Upgrade completed

   [OK] FINAL STATUS
   ==============================================================
     Result : SUCCESS
     All packages upgraded

   [OK] SCRIPT COMPLETED
   ==============================================================

--------------------------------------------------------------------------------
 CHANGELOG
--------------------------------------------------------------------------------
 2026-01-19 v1.2.1 Updated to two-line ASCII console output style
 2026-01-19 v1.2.0 Updated to corner bracket style section headers
 2025-12-23 v1.1.0 Updated to Limehawk Script Framework
 2024-12-01 v1.0.0 Initial release - migrated from SuperOps
================================================================================
#>
Set-StrictMode -Version Latest

# ==============================================================================
# CHOCOLATEY CHECK
# ==============================================================================
Write-Host ""
Write-Host "[INFO] CHOCOLATEY CHECK"
Write-Host "=============================================================="

Write-Host "  Checking for Chocolatey..."

if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host ""
    Write-Host "[ERROR] ERROR OCCURRED"
    Write-Host "=============================================================="
    Write-Host "  Chocolatey is not installed on this system"
    Write-Host "  Install Chocolatey first: https://chocolatey.org/install"
    exit 1
}

Write-Host "  Chocolatey is installed"

# ==============================================================================
# UPGRADE
# ==============================================================================
Write-Host ""
Write-Host "[RUN] UPGRADE"
Write-Host "=============================================================="

Write-Host "  Upgrading all Chocolatey packages..."
choco upgrade all -y
Write-Host "  Upgrade completed"

# ==============================================================================
# FINAL STATUS
# ==============================================================================
Write-Host ""
Write-Host "[OK] FINAL STATUS"
Write-Host "=============================================================="
Write-Host "  Result : SUCCESS"
Write-Host "  All packages upgraded"

Write-Host ""
Write-Host "[OK] SCRIPT COMPLETED"
Write-Host "=============================================================="

exit 0
