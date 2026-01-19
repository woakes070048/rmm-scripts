$ErrorActionPreference = 'Stop'
<#
██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝

================================================================================
SCRIPT  : Synology Active Backup Agent Install v1.1.2
AUTHOR  : Limehawk.io
DATE    : January 2026
USAGE   : .\synology_backup_agent_install.ps1
FILE    : synology_backup_agent_install.ps1
DESCRIPTION : Installs Synology Active Backup for Business Agent via winget
================================================================================
README
--------------------------------------------------------------------------------
PURPOSE:
    Installs the Synology Active Backup for Business Agent on Windows using
    winget. This agent enables centralized backup management from a Synology NAS.

REQUIRED INPUTS:
    $packageId : Winget package ID for Synology Active Backup Agent

BEHAVIOR:
    1. Validates winget is available
    2. Installs Synology Active Backup for Business Agent silently
    3. Reports final status

PREREQUISITES:
    - Windows 10 1809+ or Windows 11
    - Administrator privileges
    - winget (App Installer) installed
    - Synology NAS with Active Backup for Business package

SECURITY NOTES:
    - No secrets in logs
    - Installs from official winget repository

EXIT CODES:
    0 = Success
    1 = Failure

EXAMPLE RUN:
    [RUN] WINGET CHECK
    ==============================================================
    Checking for winget...
    winget is available

    [RUN] INSTALLATION
    ==============================================================
    Installing Synology Active Backup for Business Agent...
    Installation completed successfully

    [OK] FINAL STATUS
    ==============================================================
    Result : SUCCESS
    Connect to your Synology NAS to configure backup tasks

    [INFO] SCRIPT COMPLETED
    ==============================================================

CHANGELOG
--------------------------------------------------------------------------------
2026-01-19 v1.1.2 Fixed EXAMPLE RUN section formatting
2026-01-19 v1.1.1 Updated to two-line ASCII console output style
2025-12-23 v1.1.0 Updated to Limehawk Script Framework
2024-12-01 v1.0.0 Initial release - migrated from SuperOps
================================================================================
#>
Set-StrictMode -Version Latest

# ============================================================================
# HARDCODED INPUTS
# ============================================================================
$packageId = 'Synology.ActiveBackupForBusinessAgent'

# ============================================================================
# WINGET CHECK
# ============================================================================
Write-Host ""
Write-Host "[INFO] WINGET CHECK"
Write-Host "=============================================================="

Write-Host "[RUN] Checking for winget..."

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host ""
    Write-Host "[ERROR] WINGET NOT FOUND"
    Write-Host "=============================================================="
    Write-Host "winget is not installed on this system"
    Write-Host "Install App Installer from Microsoft Store"
    exit 1
}

Write-Host "[OK] winget is available"

# ============================================================================
# INSTALLATION
# ============================================================================
Write-Host ""
Write-Host "[INFO] INSTALLATION"
Write-Host "=============================================================="

try {
    Write-Host "[RUN] Installing Synology Active Backup for Business Agent..."
    $result = winget install --id=$packageId -e --silent --accept-package-agreements --accept-source-agreements 2>&1
    Write-Host $result
    Write-Host "[OK] Installation completed successfully"
}
catch {
    Write-Host ""
    Write-Host "[ERROR] INSTALLATION FAILED"
    Write-Host "=============================================================="
    Write-Host "Failed to install Synology Active Backup Agent"
    Write-Host "Error : $($_.Exception.Message)"
    exit 1
}

# ============================================================================
# FINAL STATUS
# ============================================================================
Write-Host ""
Write-Host "[INFO] FINAL STATUS"
Write-Host "=============================================================="
Write-Host "Result : SUCCESS"
Write-Host "Connect to your Synology NAS to configure backup tasks"

Write-Host ""
Write-Host "[INFO] SCRIPT COMPLETED"
Write-Host "=============================================================="

exit 0
