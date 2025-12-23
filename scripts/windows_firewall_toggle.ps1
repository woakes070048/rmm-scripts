$ErrorActionPreference = 'Stop'

<#
██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
================================================================================
 SCRIPT   : Windows Firewall Toggle                                      v1.0.1
 AUTHOR   : Limehawk.io
 DATE     : December 2024
 USAGE    : .\windows_firewall_toggle.ps1
================================================================================
 FILE     : windows_firewall_toggle.ps1
--------------------------------------------------------------------------------
 README
--------------------------------------------------------------------------------
 PURPOSE

 Toggles Windows Firewall state for all profiles (Domain, Private, Public).
 If firewall is ON, turns it OFF. If firewall is OFF, turns it ON.

 DATA SOURCES & PRIORITY

 1) Windows Firewall current state
 2) Hardcoded values (defined within the script body)

 REQUIRED INPUTS

 None - script automatically detects current state and toggles.

 SETTINGS

 - Affects all firewall profiles: Domain, Private, Public
 - Toggle behavior: ON -> OFF, OFF -> ON

 BEHAVIOR

 1. Queries current firewall state for all profiles
 2. Determines if firewall is currently enabled or disabled
 3. Toggles to opposite state
 4. Verifies new state

 PREREQUISITES

 - Windows 10/11
 - Admin privileges required

 SECURITY NOTES

 - No secrets in logs
 - WARNING: Disabling firewall reduces system security
 - Use with caution in production environments

 EXIT CODES

 - 0: Success
 - 1: Failure

 EXAMPLE RUN

 [ CURRENT STATE ]
 --------------------------------------------------------------
 Domain Profile  : ON
 Private Profile : ON
 Public Profile  : ON

 [ OPERATION ]
 --------------------------------------------------------------
 Firewall is currently ON
 Turning firewall OFF...

 [ NEW STATE ]
 --------------------------------------------------------------
 Domain Profile  : OFF
 Private Profile : OFF
 Public Profile  : OFF

 [ RESULT ]
 --------------------------------------------------------------
 Status : Success
 Action : Firewall disabled

 [ SCRIPT COMPLETED ]
 --------------------------------------------------------------
--------------------------------------------------------------------------------
 CHANGELOG
--------------------------------------------------------------------------------
 2024-12-23 v1.0.1 Updated to Limehawk Script Framework
 2025-11-29 v1.0.0 Initial Style A implementation
================================================================================
#>

Set-StrictMode -Version Latest

# ==== STATE ====
$errorOccurred = $false
$errorText = ""

# ==== ADMIN CHECK ====
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host ""
    Write-Host "[ ERROR OCCURRED ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host "Script requires admin privileges."
    Write-Host "Please relaunch as Administrator."
    exit 1
}

# ==== GET CURRENT STATE ====
Write-Host ""
Write-Host "[ CURRENT STATE ]"
Write-Host "--------------------------------------------------------------"

try {
    $domainProfile = (Get-NetFirewallProfile -Name Domain).Enabled
    $privateProfile = (Get-NetFirewallProfile -Name Private).Enabled
    $publicProfile = (Get-NetFirewallProfile -Name Public).Enabled

    $domainState = if ($domainProfile) { "ON" } else { "OFF" }
    $privateState = if ($privateProfile) { "ON" } else { "OFF" }
    $publicState = if ($publicProfile) { "ON" } else { "OFF" }

    Write-Host "Domain Profile  : $domainState"
    Write-Host "Private Profile : $privateState"
    Write-Host "Public Profile  : $publicState"

    # Determine overall state (if any profile is ON, consider firewall ON)
    $isFirewallOn = $domainProfile -or $privateProfile -or $publicProfile

} catch {
    $errorOccurred = $true
    $errorText = "Failed to query firewall state: $($_.Exception.Message)"
}

if ($errorOccurred) {
    Write-Host ""
    Write-Host "[ ERROR OCCURRED ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host $errorText
    exit 1
}

# ==== TOGGLE FIREWALL ====
Write-Host ""
Write-Host "[ OPERATION ]"
Write-Host "--------------------------------------------------------------"

try {
    if ($isFirewallOn) {
        Write-Host "Firewall is currently ON"
        Write-Host "Turning firewall OFF..."
        Set-NetFirewallProfile -All -Enabled False -ErrorAction Stop
        $actionTaken = "Firewall disabled"
    } else {
        Write-Host "Firewall is currently OFF"
        Write-Host "Turning firewall ON..."
        Set-NetFirewallProfile -All -Enabled True -ErrorAction Stop
        $actionTaken = "Firewall enabled"
    }
} catch {
    $errorOccurred = $true
    $errorText = "Failed to toggle firewall: $($_.Exception.Message)"
}

if ($errorOccurred) {
    Write-Host ""
    Write-Host "[ ERROR OCCURRED ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host $errorText
}

# ==== VERIFY NEW STATE ====
Write-Host ""
Write-Host "[ NEW STATE ]"
Write-Host "--------------------------------------------------------------"

try {
    $newDomainProfile = (Get-NetFirewallProfile -Name Domain).Enabled
    $newPrivateProfile = (Get-NetFirewallProfile -Name Private).Enabled
    $newPublicProfile = (Get-NetFirewallProfile -Name Public).Enabled

    $newDomainState = if ($newDomainProfile) { "ON" } else { "OFF" }
    $newPrivateState = if ($newPrivateProfile) { "ON" } else { "OFF" }
    $newPublicState = if ($newPublicProfile) { "ON" } else { "OFF" }

    Write-Host "Domain Profile  : $newDomainState"
    Write-Host "Private Profile : $newPrivateState"
    Write-Host "Public Profile  : $newPublicState"

} catch {
    Write-Host "Warning: Could not verify new state"
}

Write-Host ""
Write-Host "[ RESULT ]"
Write-Host "--------------------------------------------------------------"
if ($errorOccurred) {
    Write-Host "Status : Failure"
} else {
    Write-Host "Status : Success"
    Write-Host "Action : $actionTaken"
}

Write-Host ""
Write-Host "[ FINAL STATUS ]"
Write-Host "--------------------------------------------------------------"
if ($errorOccurred) {
    Write-Host "Firewall toggle failed. See error above."
} else {
    Write-Host "Firewall state has been toggled successfully."
    if (-not $isFirewallOn) {
        Write-Host "Firewall is now ENABLED for all profiles."
    } else {
        Write-Host "WARNING: Firewall is now DISABLED. System security reduced."
    }
}

Write-Host ""
Write-Host "[ SCRIPT COMPLETED ]"
Write-Host "--------------------------------------------------------------"

if ($errorOccurred) {
    exit 1
} else {
    exit 0
}
