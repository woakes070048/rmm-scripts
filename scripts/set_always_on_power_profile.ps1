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
 SCRIPT   : Set Always-On Power Profile v1.0.0
 VERSION  : v1.0.0
================================================================================
 FILE     : set_always_on_power_profile.ps1
--------------------------------------------------------------------------------
 README
--------------------------------------------------------------------------------
 PURPOSE

  Configures the active Windows power profile to an always-on state suitable
  for workstations. Adjusts timeouts for display, hard disk, sleep, and
  hibernation to prevent the machine from sleeping while plugged in, while
  applying conservative settings for battery use.

 DATA SOURCES & PRIORITY

  - Local System WMI/CIM: Used to detect the presence of a battery
    (Win32_Battery class) to determine if hibernation should be disabled
    or configured with timeouts
  - Active Power Plan: Modified via powercfg.exe commands

 REQUIRED INPUTS

  All inputs are hardcoded in the script body:
    - $displayTimeoutAC   : Display timeout on AC power (minutes, 0-999)
    - $displayTimeoutDC   : Display timeout on battery (minutes, 0-999)
    - $diskTimeoutAC      : Hard disk timeout on AC power (minutes, 0-999)
    - $diskTimeoutDC      : Hard disk timeout on battery (minutes, 0-999)
    - $standbyTimeoutAC   : Sleep timeout on AC power (minutes, 0-999, 0=never)
    - $standbyTimeoutDC   : Sleep timeout on battery (minutes, 0-999)
    - $hibernateTimeoutAC : Hibernate timeout on AC power (minutes, 0-999, 0=never)
    - $hibernateTimeoutDC : Hibernate timeout on battery (minutes, 0-999)

 SETTINGS

  Default Configuration:
    - Display Timeout (AC)     : 30 minutes
    - Display Timeout (DC)     : 10 minutes
    - Disk Timeout (AC)        : 60 minutes
    - Disk Timeout (DC)        : 30 minutes
    - Standby Timeout (AC)     : 0 (Never)
    - Standby Timeout (DC)     : 20 minutes
    - Hibernate Timeout (AC)   : 0 (Never, if battery present)
    - Hibernate Timeout (DC)   : 45 minutes (if battery present)

  Hibernation Behavior:
    - Desktop systems (no battery): Hibernation is fully disabled via powercfg -h off
    - Laptop systems (battery detected): Hibernation timeouts are configured
    - All settings apply to the currently active power plan
    - Changes take effect immediately without requiring a reboot

 BEHAVIOR

  The script performs the following actions in order:
  1. Validates all hardcoded timeout values are non-negative integers
  2. Verifies script is running with Administrator privileges
  3. Reports current host name and active power plan
  4. Sets AC and DC timeouts for display, hard disk, and sleep
  5. Checks for the presence of a system battery via WMI
  6. If no battery found (desktop): disables hibernation completely
  7. If battery found (laptop): sets hibernation timeouts for AC and DC
  8. Reports final success status

 PREREQUISITES

  - PowerShell 5.1 or later
  - Must be run with local Administrator rights
  - Network access is not required
  - Windows OS with powercfg.exe utility

 SECURITY NOTES

  - This script must be run from an elevated PowerShell session
  - No secrets are handled or logged
  - All operations are local to the machine running the script
  - No network connections are made

 ENDPOINTS

  Not applicable - this script does not connect to any network endpoints

 EXIT CODES

  0 = Success - power profile configured successfully
  1 = Failure - input validation failed or insufficient privileges

 EXAMPLE RUN

  [ INPUT VALIDATION ]
  --------------------------------------------------------------
   All required inputs are valid

  [ INITIALIZING SCRIPT ]
  --------------------------------------------------------------
   Privilege Check          : Administrator
   Host Name                : WKSTN-LIMEHAWK
   Active Power Plan        : Balanced

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
   Power profile has been configured successfully
   Settings are effective immediately

  [ SCRIPT COMPLETED ]
  --------------------------------------------------------------

--------------------------------------------------------------------------------
 CHANGELOG
 2025-09-12 v1.0.0 Initial Style A compliant version for workstation power
                   profile management
================================================================================
#>

Set-StrictMode -Version Latest

# ============================================================================
# HARDCODED INPUTS
# ============================================================================

$displayTimeoutAC   = 30   # Minutes until display turns off on AC power
$displayTimeoutDC   = 10   # Minutes until display turns off on battery
$diskTimeoutAC      = 60   # Minutes until hard disk spins down on AC power
$diskTimeoutDC      = 30   # Minutes until hard disk spins down on battery
$standbyTimeoutAC   = 0    # Minutes until system sleeps on AC power (0 = never)
$standbyTimeoutDC   = 20   # Minutes until system sleeps on battery
$hibernateTimeoutAC = 0    # Minutes until system hibernates on AC (0 = never)
$hibernateTimeoutDC = 45   # Minutes until system hibernates on battery

# ============================================================================
# INPUT VALIDATION
# ============================================================================

Write-Host ""
Write-Host "[ INPUT VALIDATION ]"
Write-Host "--------------------------------------------------------------"

$errorOccurred = $false
$errorText     = ""

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
$activePlanName = if ($activePlanRaw -match '\(([^)]+)\)') { $matches[1] } else { "Unknown" }
Write-Host (" {0} : {1}" -f "Active Power Plan".PadRight(24), $activePlanName)

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
Write-Host " Power profile has been configured successfully"
Write-Host " Settings are effective immediately"

Write-Host ""
Write-Host "[ SCRIPT COMPLETED ]"
Write-Host "--------------------------------------------------------------"
exit 0
