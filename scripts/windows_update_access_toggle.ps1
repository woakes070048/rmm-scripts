$ErrorActionPreference = 'Stop'
<#
██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝

================================================================================
SCRIPT  : Windows Update Access Toggle v1.0.2
AUTHOR  : Limehawk.io
DATE      : January 2026
USAGE   : .\windows_update_access_toggle.ps1
FILE    : windows_update_access_toggle.ps1
DESCRIPTION : Toggles user access to Windows Update in Settings app
================================================================================
README
--------------------------------------------------------------------------------
PURPOSE:
    Toggles user access to Windows Update settings in the Settings app.
    If access is currently blocked, it will be enabled.
    If access is currently allowed, it will be blocked.

REQUIRED INPUTS:
    None

BEHAVIOR:
    1. Checks current state of SetDisableUXWUAccess registry key
    2. Toggles the state (add/remove key)
    3. Reports new state

PREREQUISITES:
    - Windows 10/11
    - Administrator privileges

SECURITY NOTES:
    - No secrets in logs
    - Modifies Windows Update policy registry

EXIT CODES:
    0 = Success
    1 = Failure

EXAMPLE RUN:

    [INFO] CHECKING CURRENT STATE
    ==============================================================
    Registry Path        : HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate
    Key Name             : SetDisableUXWUAccess
    Current State        : Access ALLOWED (key not present)

    [RUN] TOGGLING STATE
    ==============================================================
    Action               : Blocking access
    Result               : Key created with value 1

    [OK] FINAL STATUS
    ==============================================================
    New State            : Access BLOCKED
    Users cannot access Windows Update settings.
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
    Write-Section "INFO" "CHECKING CURRENT STATE"

    PrintKV "Registry Path" $registryPath
    PrintKV "Key Name" $registryName

    # Ensure path exists
    if (-not (Test-Path $registryPath)) {
        New-Item -Path $registryPath -Force | Out-Null
    }

    $registryKey = Get-ItemProperty -Path $registryPath -Name $registryName -ErrorAction SilentlyContinue

    $isCurrentlyBlocked = $false
    if ($registryKey) {
        $isCurrentlyBlocked = $true
        PrintKV "Current State" "Access BLOCKED (key value: $($registryKey.$registryName))"
    } else {
        PrintKV "Current State" "Access ALLOWED (key not present)"
    }

    Write-Section "RUN" "TOGGLING STATE"

    if ($isCurrentlyBlocked) {
        # Currently blocked - remove key to allow access
        PrintKV "Action" "Allowing access"
        Remove-ItemProperty -Path $registryPath -Name $registryName -ErrorAction Stop
        PrintKV "Result" "Key removed"

        Write-Section "OK" "FINAL STATUS"
        PrintKV "New State" "Access ALLOWED"
        Write-Host "Users can now access Windows Update settings."
    } else {
        # Currently allowed - add key to block access
        PrintKV "Action" "Blocking access"
        New-ItemProperty -Path $registryPath -Name $registryName -Value 1 -PropertyType DWORD -Force | Out-Null
        PrintKV "Result" "Key created with value 1"

        Write-Section "OK" "FINAL STATUS"
        PrintKV "New State" "Access BLOCKED"
        Write-Host "Users cannot access Windows Update settings."
    }

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
