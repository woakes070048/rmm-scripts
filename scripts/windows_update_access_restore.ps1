$ErrorActionPreference = 'Stop'
<#
██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝

================================================================================
SCRIPT  : Windows Update Access Restore v1.0.2
AUTHOR  : Limehawk.io
DATE      : January 2026
USAGE   : .\windows_update_access_restore.ps1
FILE    : windows_update_access_restore.ps1
DESCRIPTION : Restores user access to Windows Update settings
================================================================================
README
--------------------------------------------------------------------------------
PURPOSE:
    Removes the SetDisableUXWUAccess registry key to restore user access to
    Windows Update settings in the Settings app.

REQUIRED INPUTS:
    None

BEHAVIOR:
    1. Checks for SetDisableUXWUAccess registry key
    2. Removes it if present
    3. Reports result

PREREQUISITES:
    - Windows 10/11
    - Administrator privileges

SECURITY NOTES:
    - No secrets in logs
    - Modifies Windows Update policy registry

EXIT CODES:
    0 = Success (key removed or didn't exist)
    1 = Failure

EXAMPLE RUN:

    [INFO] CHECKING REGISTRY
    ==============================================================
    Registry Path        : HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate
    Key Name             : SetDisableUXWUAccess
    Current State        : Key exists (value: 1)

    [RUN] REMOVING KEY
    ==============================================================
    Result               : Key removed successfully

    [OK] FINAL STATUS
    ==============================================================
    Users can now access Windows Update settings.
    SCRIPT SUCCEEDED

    [OK] SCRIPT COMPLETED
    ==============================================================

CHANGELOG
--------------------------------------------------------------------------------
2026-01-19 v1.0.2 Updated to two-line ASCII console output style
2025-12-23 v1.0.1 Updated to Limehawk Script Framework
2024-12-01 v1.0.0 Initial release - migrated from SuperOps
================================================================================
#>
Set-StrictMode -Version Latest

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================
function Write-Section {
    param([string]$prefix, [string]$title)
    Write-Host ""
    Write-Host ("[{0}] {1}" -f $prefix, $title)
    Write-Host "=============================================================="
}

function PrintKV([string]$label, [string]$value) {
    $lbl = $label.PadRight(24)
    Write-Host ("{0} : {1}" -f $lbl, $value)
}

# ============================================================================
# PRIVILEGE CHECK
# ============================================================================
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Section "ERROR" "ADMIN PRIVILEGES REQUIRED"
    Write-Host "This script requires administrative privileges to run."
    Write-Section "ERROR" "SCRIPT HALTED"
    exit 1
}

# ============================================================================
# CONFIGURATION
# ============================================================================
$registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
$registryName = "SetDisableUXWUAccess"

# ============================================================================
# MAIN SCRIPT
# ============================================================================
try {
    Write-Section "INFO" "CHECKING REGISTRY"

    PrintKV "Registry Path" $registryPath
    PrintKV "Key Name" $registryName

    if (-not (Test-Path $registryPath)) {
        PrintKV "Current State" "Registry path does not exist"
        Write-Section "OK" "FINAL STATUS"
        Write-Host "No action needed - Windows Update access is not restricted."
        Write-Host "SCRIPT SUCCEEDED"
        Write-Section "OK" "SCRIPT COMPLETED"
        exit 0
    }

    $registryKey = Get-ItemProperty -Path $registryPath -Name $registryName -ErrorAction SilentlyContinue

    if (-not $registryKey) {
        PrintKV "Current State" "Key does not exist"
        Write-Section "OK" "FINAL STATUS"
        Write-Host "No action needed - Windows Update access is not restricted."
        Write-Host "SCRIPT SUCCEEDED"
        Write-Section "OK" "SCRIPT COMPLETED"
        exit 0
    }

    $currentValue = $registryKey.$registryName
    PrintKV "Current State" "Key exists (value: $currentValue)"

    Write-Section "RUN" "REMOVING KEY"

    Remove-ItemProperty -Path $registryPath -Name $registryName -ErrorAction Stop
    PrintKV "Result" "Key removed successfully"

    Write-Section "OK" "FINAL STATUS"
    Write-Host "Users can now access Windows Update settings."
    Write-Host "SCRIPT SUCCEEDED"

    Write-Section "OK" "SCRIPT COMPLETED"
    exit 0
}
catch {
    Write-Section "ERROR" "ERROR OCCURRED"
    PrintKV "Error Message" $_.Exception.Message
    PrintKV "Error Type" $_.Exception.GetType().FullName
    Write-Section "ERROR" "SCRIPT HALTED"
    exit 1
}
