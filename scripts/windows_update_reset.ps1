$ErrorActionPreference = 'Stop'

<#
â–ˆâ–ˆâ•—     â–ˆâ–ˆâ•—â–ˆâ–ˆâ–ˆâ•—   â–ˆâ–ˆâ–ˆâ•—â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•—â–ˆâ–ˆâ•—  â–ˆâ–ˆâ•— â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•— â–ˆâ–ˆâ•—    â–ˆâ–ˆâ•—â–ˆâ–ˆâ•—  â–ˆâ–ˆâ•—
â–ˆâ–ˆâ•‘     â–ˆâ–ˆâ•‘â–ˆâ–ˆâ–ˆâ–ˆâ•— â–ˆâ–ˆâ–ˆâ–ˆâ•‘â–ˆâ–ˆâ•”â•â•â•â•â•â–ˆâ–ˆâ•‘  â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•”â•â•â–ˆâ–ˆâ•—â–ˆâ–ˆâ•‘    â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•‘ â–ˆâ–ˆâ•”â•
â–ˆâ–ˆâ•‘     â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•”â–ˆâ–ˆâ–ˆâ–ˆâ•”â–ˆâ–ˆâ•‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•—  â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•‘â–ˆâ–ˆâ•‘ â–ˆâ•— â–ˆâ–ˆâ•‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•”â•
â–ˆâ–ˆâ•‘     â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•‘â•šâ–ˆâ–ˆâ•”â•â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•”â•â•â•  â–ˆâ–ˆâ•”â•â•â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•”â•â•â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•‘â–ˆâ–ˆâ–ˆâ•—â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•”â•â–ˆâ–ˆâ•—
â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•—â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•‘ â•šâ•â• â–ˆâ–ˆâ•‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•—â–ˆâ–ˆâ•‘  â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•‘  â–ˆâ–ˆâ•‘â•šâ–ˆâ–ˆâ–ˆâ•”â–ˆâ–ˆâ–ˆâ•”â•â–ˆâ–ˆâ•‘  â–ˆâ–ˆâ•—
â•šâ•â•â•â•â•â•â•â•šâ•â•â•šâ•â•     â•šâ•â•â•šâ•â•â•â•â•â•â•â•šâ•â•  â•šâ•â•â•šâ•â•  â•šâ•â• â•šâ•â•â•â•šâ•â•â• â•šâ•â•  â•šâ•â•
================================================================================
 SCRIPT   : Windows Update Reset                                         v1.0.1
 AUTHOR   : Limehawk.io
 DATE      : December 2025
 USAGE    : .\windows_update_reset.ps1
================================================================================
 FILE     : windows_update_reset.ps1
DESCRIPTION : Resets Windows Update components and clears cache
--------------------------------------------------------------------------------
 README
--------------------------------------------------------------------------------
 PURPOSE

 Completely resets Windows Update components by stopping services, clearing
 caches, resetting security descriptors, re-registering DLLs, and restarting
 services. Fixes most Windows Update problems.

 DATA SOURCES & PRIORITY

 1) Hardcoded values (defined within the script body)
 2) Windows Update services and components

 REQUIRED INPUTS

 - RebootAfterReset : Whether to reboot after reset (default: $false)

 SETTINGS

 - Stops: BITS, wuauserv, appidsvc, cryptsvc
 - Clears: SoftwareDistribution, catroot2, QMGR data
 - Resets: BITS and wuauserv security descriptors
 - Registers: 30+ Windows Update related DLLs
 - Resets: Winsock

 BEHAVIOR

 1. Stops all Windows Update related services
 2. Flushes DNS cache
 3. Clears BITS download queue data
 4. Renames SoftwareDistribution and catroot2 folders
 5. Resets Windows Update policies in registry
 6. Resets BITS and wuauserv security descriptors
 7. Re-registers all Windows Update DLLs
 8. Resets Winsock
 9. Restarts all services
 10. Optionally reboots system

 PREREQUISITES

 - Windows 10/11
 - Admin privileges required
 - Internet connectivity for updates after reset

 SECURITY NOTES

 - No secrets in logs
 - Modifies system registry and service configurations
 - Creates .bak folders for recovery

 EXIT CODES

 - 0: Success
 - 1: Failure

 EXAMPLE RUN

 [ INPUT VALIDATION ]
 --------------------------------------------------------------
 Reboot After Reset : False

 [ STOPPING SERVICES ]
 --------------------------------------------------------------
 Stopping BITS...
 Stopping wuauserv...
 Stopping appidsvc...
 Stopping cryptsvc...

 [ CLEARING CACHES ]
 --------------------------------------------------------------
 Flushing DNS...
 Clearing QMGR data...
 Renaming SoftwareDistribution...
 Renaming catroot2...

 [ RESETTING COMPONENTS ]
 --------------------------------------------------------------
 Resetting security descriptors...
 Re-registering DLLs...
 Resetting Winsock...

 [ STARTING SERVICES ]
 --------------------------------------------------------------
 Starting BITS...
 Starting wuauserv...
 Starting appidsvc...
 Starting cryptsvc...

 [ RESULT ]
 --------------------------------------------------------------
 Status : Success

 [ SCRIPT COMPLETED ]
 --------------------------------------------------------------
--------------------------------------------------------------------------------
 CHANGELOG
--------------------------------------------------------------------------------
 2025-12-23 v1.0.1 Updated to Limehawk Script Framework
 2025-11-29 v1.0.0 Initial Style A implementation
================================================================================
#>

Set-StrictMode -Version Latest

# ==== STATE ====
$errorOccurred = $false
$errorText = ""

# ==== HARDCODED INPUTS ====
$RebootAfterReset = $false

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

# ==== RUNTIME OUTPUT ====
Write-Host ""
Write-Host "[ INPUT VALIDATION ]"
Write-Host "--------------------------------------------------------------"
Write-Host "Reboot After Reset : $RebootAfterReset"

# ==== STOP SERVICES ====
Write-Host ""
Write-Host "[ STOPPING SERVICES ]"
Write-Host "--------------------------------------------------------------"

$services = @('bits', 'wuauserv', 'appidsvc', 'cryptsvc')
foreach ($svc in $services) {
    Write-Host "Stopping $svc..."
    Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
    $retries = 0
    while ((Get-Service -Name $svc -ErrorAction SilentlyContinue).Status -ne 'Stopped' -and $retries -lt 3) {
        Start-Sleep -Seconds 2
        Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
        $retries++
    }
}

# ==== CLEAR CACHES ====
Write-Host ""
Write-Host "[ CLEARING CACHES ]"
Write-Host "--------------------------------------------------------------"

try {
    Write-Host "Flushing DNS..."
    ipconfig /flushdns | Out-Null

    Write-Host "Clearing QMGR data..."
    Remove-Item -Path "$env:ALLUSERSPROFILE\Application Data\Microsoft\Network\Downloader\qmgr*.dat" -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:ALLUSERSPROFILE\Microsoft\Network\Downloader\qmgr*.dat" -Force -ErrorAction SilentlyContinue

    Write-Host "Clearing Windows Update logs..."
    Remove-Item -Path "$env:SYSTEMROOT\Logs\WindowsUpdate\*" -Recurse -Force -ErrorAction SilentlyContinue

    # Rename SoftwareDistribution
    Write-Host "Renaming SoftwareDistribution..."
    $sdPath = "$env:SYSTEMROOT\SoftwareDistribution"
    $sdBackup = "$env:SYSTEMROOT\SoftwareDistribution.bak"
    if (Test-Path $sdBackup) {
        Remove-Item -Path $sdBackup -Recurse -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path $sdPath) {
        Rename-Item -Path $sdPath -NewName "SoftwareDistribution.bak" -Force -ErrorAction Stop
    }

    # Rename catroot2
    Write-Host "Renaming catroot2..."
    $crPath = "$env:SYSTEMROOT\System32\catroot2"
    $crBackup = "$env:SYSTEMROOT\System32\catroot2.bak"
    if (Test-Path $crBackup) {
        Remove-Item -Path $crBackup -Recurse -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path $crPath) {
        Rename-Item -Path $crPath -NewName "catroot2.bak" -Force -ErrorAction Stop
    }

} catch {
    Write-Host "Warning: Some cache operations failed: $($_.Exception.Message)"
}

# ==== RESET COMPONENTS ====
Write-Host ""
Write-Host "[ RESETTING COMPONENTS ]"
Write-Host "--------------------------------------------------------------"

try {
    # Reset Windows Update policies
    Write-Host "Resetting Windows Update policies..."
    $regPaths = @(
        "HKCU:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\WindowsUpdate",
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\WindowsUpdate"
    )
    foreach ($path in $regPaths) {
        if (Test-Path $path) {
            Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    # Reset security descriptors
    Write-Host "Resetting service security descriptors..."
    sc.exe sdset bits "D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU)" | Out-Null
    sc.exe sdset wuauserv "D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU)" | Out-Null

    # Re-register DLLs
    Write-Host "Re-registering Windows Update DLLs..."
    $dlls = @(
        "atl.dll", "urlmon.dll", "mshtml.dll", "shdocvw.dll", "browseui.dll",
        "jscript.dll", "vbscript.dll", "scrrun.dll", "msxml.dll", "msxml3.dll",
        "msxml6.dll", "actxprxy.dll", "softpub.dll", "wintrust.dll", "dssenh.dll",
        "rsaenh.dll", "gpkcsp.dll", "sccbase.dll", "slbcsp.dll", "cryptdlg.dll",
        "oleaut32.dll", "ole32.dll", "shell32.dll", "initpki.dll", "wuapi.dll",
        "wuaueng.dll", "wuaueng1.dll", "wucltui.dll", "wups.dll", "wups2.dll",
        "wuweb.dll", "qmgr.dll", "qmgrprxy.dll", "wucltux.dll", "muweb.dll",
        "wuwebv.dll", "wudriver.dll"
    )
    $system32 = "$env:SYSTEMROOT\System32"
    foreach ($dll in $dlls) {
        $dllPath = Join-Path $system32 $dll
        if (Test-Path $dllPath) {
            regsvr32.exe /s $dllPath 2>$null
        }
    }

    # Reset Winsock
    Write-Host "Resetting Winsock..."
    netsh winsock reset | Out-Null
    netsh winsock reset proxy | Out-Null

    # Set services to auto start
    Write-Host "Configuring service startup types..."
    sc.exe config wuauserv start= auto | Out-Null
    sc.exe config bits start= auto | Out-Null
    sc.exe config DcomLaunch start= auto | Out-Null

} catch {
    $errorOccurred = $true
    $errorText = $_.Exception.Message
}

# ==== START SERVICES ====
Write-Host ""
Write-Host "[ STARTING SERVICES ]"
Write-Host "--------------------------------------------------------------"

foreach ($svc in $services) {
    Write-Host "Starting $svc..."
    Start-Service -Name $svc -ErrorAction SilentlyContinue
}

if ($errorOccurred) {
    Write-Host ""
    Write-Host "[ ERROR OCCURRED ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host $errorText
}

Write-Host ""
Write-Host "[ RESULT ]"
Write-Host "--------------------------------------------------------------"
if ($errorOccurred) {
    Write-Host "Status : Partial Success (some operations failed)"
} else {
    Write-Host "Status : Success"
}

Write-Host ""
Write-Host "[ FINAL STATUS ]"
Write-Host "--------------------------------------------------------------"
Write-Host "Windows Update components have been reset."
Write-Host "A reboot is recommended to complete the process."

if ($RebootAfterReset) {
    Write-Host "Initiating reboot in 60 seconds..."
    shutdown /g /f /t 60 /c "Windows Update reset complete. Rebooting..."
}

Write-Host ""
Write-Host "[ SCRIPT COMPLETED ]"
Write-Host "--------------------------------------------------------------"

if ($errorOccurred) {
    exit 1
} else {
    exit 0
}
