Import-Module $SuperOpsModule
$ErrorActionPreference = 'Stop'

<#
██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
================================================================================
 SCRIPT   : Set Always-On Power Profile v2.0.0
 VERSION  : v2.0.0
================================================================================
 FILE     : set_always_on_power_profile.ps1
--------------------------------------------------------------------------------
 README
--------------------------------------------------------------------------------
 PURPOSE

  Creates a custom "Always On - Limehawk" power plan optimized for workstations
  that should never sleep while on AC power. If the plan already exists, it will
  be reused and reconfigured. The plan is based on High Performance settings and
  includes configurable timeouts for display, hard disk, sleep, and hibernation.

 DATA SOURCES & PRIORITY

  - Local System WMI/CIM: Used to detect the presence of a battery
    (Win32_Battery class) to determine if hibernation should be disabled
    or configured with timeouts
  - Windows Power Plans: Creates or modifies custom plan via powercfg.exe
  - High Performance Plan: Used as the base template for the custom plan

 REQUIRED INPUTS

  All inputs are hardcoded in the script body:
    - $customPlanName     : Name of the custom power plan (non-empty string)
    - $displayTimeoutAC   : Display timeout on AC power (minutes, 0-999)
    - $displayTimeoutDC   : Display timeout on battery (minutes, 0-999)
    - $diskTimeoutAC      : Hard disk timeout on AC power (minutes, 0-999)
    - $diskTimeoutDC      : Hard disk timeout on battery (minutes, 0-999)
    - $standbyTimeoutAC   : Sleep timeout on AC power (minutes, 0-999, 0=never)
    - $standbyTimeoutDC   : Sleep timeout on battery (minutes, 0-999)
    - $hibernateTimeoutAC : Hibernate timeout on AC power (minutes, 0-999, 0=never)
    - $hibernateTimeoutDC : Hibernate timeout on battery (minutes, 0-999)

 SETTINGS

  Custom Plan Configuration:
    - Plan Name                : Always On - Limehawk
    - Display Timeout (AC)     : 30 minutes
    - Display Timeout (DC)     : 10 minutes
    - Disk Timeout (AC)        : 60 minutes
    - Disk Timeout (DC)        : 30 minutes
    - Standby Timeout (AC)     : 0 (Never)
    - Standby Timeout (DC)     : 20 minutes
    - Hibernate Timeout (AC)   : 0 (Never, if battery present)
    - Hibernate Timeout (DC)   : 45 minutes (if battery present)

  Plan Management:
    - If plan exists: Reuses existing plan GUID and reconfigures settings
    - If plan does not exist: Creates new plan by duplicating High Performance
    - The custom plan is automatically set as the active power plan
    - Original power plans are not modified

  Hibernation Behavior:
    - Desktop systems (no battery): Hibernation is fully disabled via powercfg -h off
    - Laptop systems (battery detected): Hibernation timeouts are configured
    - Changes take effect immediately without requiring a reboot

 BEHAVIOR

  The script performs the following actions in order:
  1. Validates all hardcoded timeout values and plan name
  2. Verifies script is running with Administrator privileges
  3. Reports current host name and previously active power plan
  4. Checks if custom power plan already exists by name
  5. If plan exists, retrieves its GUID and reports reuse
  6. If plan does not exist, duplicates High Performance plan to create it
  7. Sets the custom plan as the active power plan
  8. Sets AC and DC timeouts for display, hard disk, and sleep
  9. Checks for the presence of a system battery via WMI
  10. If no battery found (desktop): disables hibernation completely
  11. If battery found (laptop): sets hibernation timeouts for AC and DC
  12. Reports final success status with new active plan name

 PREREQUISITES

  - PowerShell 5.1 or later
  - Must be run with local Administrator rights
  - Network access is not required
  - Windows OS with powercfg.exe utility
  - High Performance power plan must exist on the system

 SECURITY NOTES

  - This script must be run from an elevated PowerShell session
  - No secrets are handled or logged
  - All operations are local to the machine running the script
  - No network connections are made
  - Creates a new power plan but does not delete existing plans

 ENDPOINTS

  Not applicable - this script does not connect to any network endpoints

 EXIT CODES

  0 = Success - custom power plan created/configured and activated
  1 = Failure - input validation failed or insufficient privileges

 EXAMPLE RUN

  [ INPUT VALIDATION ]
  --------------------------------------------------------------
   All required inputs are valid

  [ INITIALIZING SCRIPT ]
  --------------------------------------------------------------
   Privilege Check          : Administrator
   Host Name                : WKSTN-LIMEHAWK
   Previous Active Plan     : Lenovo Default

  [ POWER PLAN SETUP ]
  --------------------------------------------------------------
   Custom Plan Name         : Always On - Limehawk
   Plan Status              : Already exists (reusing)
   Plan GUID                : a1b2c3d4-e5f6-7890-1234-567890abcdef
   Active Plan              : Always On - Limehawk

  [ APPLYING POWER SETTINGS ]
  --------------------------------------------------------------
   Display Timeout (AC)     : 30 minutes
   Display Timeout (DC)     : 10 minutes
   Disk Timeout (AC)        : 60 minutes
   Disk Timeout (DC)        : 30 minutes
   Standby Timeout (AC)     : 0 (Never)
   Standby Timeout (DC)     : 20 minutes

  [ CONFIGURING HIBERNATION ]
  --------------------------------------------------------------
   Battery Status           : NOT DETECTED
   Hibernation              : DISABLED

  [ FINAL STATUS ]
  --------------------------------------------------------------
   Power plan configured successfully
   Active plan is now: Always On - Limehawk
   Settings are effective immediately

  [ SCRIPT COMPLETED ]
  --------------------------------------------------------------

--------------------------------------------------------------------------------
 CHANGELOG
 2025-09-12 v1.0.0 Initial Style A compliant version for workstation power
                   profile management
 2025-11-19 v2.0.0 Changed to create custom "Always On - Limehawk" plan instead
                   of modifying existing active plan
================================================================================
#>

Set-StrictMode -Version Latest

# ============================================================================
# HARDCODED INPUTS
# ============================================================================

$customPlanName     = "Always On - Limehawk.io"   # Name of the custom power plan
$displayTimeoutAC   = 30   # Minutes until display turns off on AC power
$displayTimeoutDC   = 10   # Minutes until display turns off on battery
$diskTimeoutAC      = 60   # Minutes until hard disk spins down on AC power
$diskTimeoutDC      = 30   # Minutes until hard disk spins down on battery
$standbyTimeoutAC   = 0    # Minutes until system sleeps on AC power (0 = never)
$standbyTimeoutDC   = 20   # Minutes until system sleeps on battery
$hibernateTimeoutAC = 0    # Minutes until system hibernates on AC (0 = never)
$hibernateTimeoutDC = 45   # Minutes until system hibernates on battery

# High Performance plan GUID (standard across Windows installations)
$highPerfGuid = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"

# ============================================================================
# INPUT VALIDATION
# ============================================================================

Write-Host ""
Write-Host "[ INPUT VALIDATION ]"
Write-Host "--------------------------------------------------------------"

$errorOccurred = $false
$errorText     = ""

if ([string]::IsNullOrWhiteSpace($customPlanName)) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- Custom plan name cannot be empty"
}

if ($displayTimeoutAC -lt 0 -or $displayTimeoutAC -gt 999) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- Display timeout (AC) must be between 0-999 minutes"
}

if ($displayTimeoutDC -lt 0 -or $displayTimeoutDC -gt 999) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- Display timeout (DC) must be between 0-999 minutes"
}

if ($diskTimeoutAC -lt 0 -or $diskTimeoutAC -gt 999) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- Disk timeout (AC) must be between 0-999 minutes"
}

if ($diskTimeoutDC -lt 0 -or $diskTimeoutDC -gt 999) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- Disk timeout (DC) must be between 0-999 minutes"
}

if ($standbyTimeoutAC -lt 0 -or $standbyTimeoutAC -gt 999) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- Standby timeout (AC) must be between 0-999 minutes"
}

if ($standbyTimeoutDC -lt 0 -or $standbyTimeoutDC -gt 999) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- Standby timeout (DC) must be between 0-999 minutes"
}

if ($hibernateTimeoutAC -lt 0 -or $hibernateTimeoutAC -gt 999) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- Hibernate timeout (AC) must be between 0-999 minutes"
}

if ($hibernateTimeoutDC -lt 0 -or $hibernateTimeoutDC -gt 999) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- Hibernate timeout (DC) must be between 0-999 minutes"
}

if ($errorOccurred) {
    Write-Host ""
    Write-Host "[ ERROR OCCURRED ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host "Input validation failed:"
    Write-Host $errorText
    Write-Host ""
    Write-Host "[ SCRIPT COMPLETED ]"
    Write-Host "--------------------------------------------------------------"
    exit 1
}

Write-Host " All required inputs are valid"

# ============================================================================
# PRIVILEGE CHECK AND INITIALIZATION
# ============================================================================

Write-Host ""
Write-Host "[ INITIALIZING SCRIPT ]"
Write-Host "--------------------------------------------------------------"

$identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
if (-not $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host ""
    Write-Host "[ ERROR OCCURRED ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host "This script must be run with Administrator privileges"
    Write-Host "Right-click PowerShell and select 'Run as Administrator'"
    Write-Host ""
    Write-Host "[ SCRIPT COMPLETED ]"
    Write-Host "--------------------------------------------------------------"
    exit 1
}

$privilegeCheck = "Administrator"
Write-Host (" {0} : {1}" -f "Privilege Check".PadRight(24), $privilegeCheck)

$hostName = $env:COMPUTERNAME
Write-Host (" {0} : {1}" -f "Host Name".PadRight(24), $hostName)

$activePlanRaw = powercfg /getactivescheme
$previousPlanName = if ($activePlanRaw -match '\(([^)]+)\)') { $matches[1] } else { "Unknown" }
Write-Host (" {0} : {1}" -f "Previous Active Plan".PadRight(24), $previousPlanName)

# ============================================================================
# CREATE OR REUSE CUSTOM POWER PLAN
# ============================================================================

Write-Host ""
Write-Host "[ POWER PLAN SETUP ]"
Write-Host "--------------------------------------------------------------"

Write-Host (" {0} : {1}" -f "Custom Plan Name".PadRight(24), $customPlanName)

$allPlansRaw = powercfg /list
$customPlanGuid = $null

foreach ($line in $allPlansRaw) {
    if ($line -match '([a-f0-9-]{36}).*\((.+)\)') {
        $guid = $matches[1]
        $name = $matches[2]
        if ($name -eq $customPlanName) {
            $customPlanGuid = $guid
            break
        }
    }
}

if ($customPlanGuid) {
    Write-Host (" {0} : {1}" -f "Plan Status".PadRight(24), "Already exists (reusing)")
    Write-Host (" {0} : {1}" -f "Plan GUID".PadRight(24), $customPlanGuid)
}
else {
    Write-Host (" {0} : {1}" -f "Plan Status".PadRight(24), "Creating new plan")

    $duplicateOutput = powercfg /duplicatescheme $highPerfGuid

    if ($duplicateOutput -match '([a-f0-9-]{36})') {
        $customPlanGuid = $matches[1]
        Write-Host (" {0} : {1}" -f "Plan GUID".PadRight(24), $customPlanGuid)

        powercfg /changename $customPlanGuid $customPlanName "Limehawk managed always-on power plan for workstations" | Out-Null
        Write-Host (" {0} : {1}" -f "Plan Created".PadRight(24), "Based on High Performance")
    }
    else {
        Write-Host ""
        Write-Host "[ ERROR OCCURRED ]"
        Write-Host "--------------------------------------------------------------"
        Write-Host "Failed to create custom power plan"
        Write-Host "Could not duplicate High Performance plan"
        Write-Host ""
        Write-Host "[ SCRIPT COMPLETED ]"
        Write-Host "--------------------------------------------------------------"
        exit 1
    }
}

powercfg /setactive $customPlanGuid
Write-Host (" {0} : {1}" -f "Active Plan".PadRight(24), $customPlanName)

# ============================================================================
# APPLY POWER SETTINGS
# ============================================================================

Write-Host ""
Write-Host "[ APPLYING POWER SETTINGS ]"
Write-Host "--------------------------------------------------------------"

powercfg.exe -change -monitor-timeout-ac $displayTimeoutAC
$displayACLabel = if ($displayTimeoutAC -eq 0) { "0 (Never)" } else { "$displayTimeoutAC minutes" }
Write-Host (" {0} : {1}" -f "Display Timeout (AC)".PadRight(24), $displayACLabel)

powercfg.exe -change -monitor-timeout-dc $displayTimeoutDC
$displayDCLabel = if ($displayTimeoutDC -eq 0) { "0 (Never)" } else { "$displayTimeoutDC minutes" }
Write-Host (" {0} : {1}" -f "Display Timeout (DC)".PadRight(24), $displayDCLabel)

powercfg.exe -change -disk-timeout-ac $diskTimeoutAC
$diskACLabel = if ($diskTimeoutAC -eq 0) { "0 (Never)" } else { "$diskTimeoutAC minutes" }
Write-Host (" {0} : {1}" -f "Disk Timeout (AC)".PadRight(24), $diskACLabel)

powercfg.exe -change -disk-timeout-dc $diskTimeoutDC
$diskDCLabel = if ($diskTimeoutDC -eq 0) { "0 (Never)" } else { "$diskTimeoutDC minutes" }
Write-Host (" {0} : {1}" -f "Disk Timeout (DC)".PadRight(24), $diskDCLabel)

powercfg.exe -change -standby-timeout-ac $standbyTimeoutAC
$standbyACLabel = if ($standbyTimeoutAC -eq 0) { "0 (Never)" } else { "$standbyTimeoutAC minutes" }
Write-Host (" {0} : {1}" -f "Standby Timeout (AC)".PadRight(24), $standbyACLabel)

powercfg.exe -change -standby-timeout-dc $standbyTimeoutDC
$standbyDCLabel = if ($standbyTimeoutDC -eq 0) { "0 (Never)" } else { "$standbyTimeoutDC minutes" }
Write-Host (" {0} : {1}" -f "Standby Timeout (DC)".PadRight(24), $standbyDCLabel)

# ============================================================================
# CONFIGURE HIBERNATION
# ============================================================================

Write-Host ""
Write-Host "[ CONFIGURING HIBERNATION ]"
Write-Host "--------------------------------------------------------------"

$battery = Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue

if ($null -eq $battery) {
    Write-Host (" {0} : {1}" -f "Battery Status".PadRight(24), "NOT DETECTED")
    powercfg.exe -h off
    Write-Host (" {0} : {1}" -f "Hibernation".PadRight(24), "DISABLED")
}
else {
    Write-Host (" {0} : {1}" -f "Battery Status".PadRight(24), "DETECTED")

    powercfg.exe -change -hibernate-timeout-ac $hibernateTimeoutAC
    $hibernateACLabel = if ($hibernateTimeoutAC -eq 0) { "0 (Never)" } else { "$hibernateTimeoutAC minutes" }
    Write-Host (" {0} : {1}" -f "Hibernate Timeout (AC)".PadRight(24), $hibernateACLabel)

    powercfg.exe -change -hibernate-timeout-dc $hibernateTimeoutDC
    $hibernateDCLabel = if ($hibernateTimeoutDC -eq 0) { "0 (Never)" } else { "$hibernateTimeoutDC minutes" }
    Write-Host (" {0} : {1}" -f "Hibernate Timeout (DC)".PadRight(24), $hibernateDCLabel)
}

# ============================================================================
# FINAL STATUS
# ============================================================================

Write-Host ""
Write-Host "[ FINAL STATUS ]"
Write-Host "--------------------------------------------------------------"
Write-Host " Power plan configured successfully"
Write-Host (" Active plan is now: {0}" -f $customPlanName)
Write-Host " Settings are effective immediately"

Write-Host ""
Write-Host "[ SCRIPT COMPLETED ]"
Write-Host "--------------------------------------------------------------"
exit 0
