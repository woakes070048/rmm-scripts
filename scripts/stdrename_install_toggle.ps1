$ErrorActionPreference = 'Stop'

<#
██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
================================================================================
 SCRIPT   : stdrename Install Toggle v1.1.1
 AUTHOR   : Limehawk.io
 DATE      : January 2026
 USAGE    : .\stdrename_install_toggle.ps1
================================================================================
 FILE     : stdrename_install_toggle.ps1
DESCRIPTION : Toggles installation of stdrename file renaming utility
--------------------------------------------------------------------------------
 README
--------------------------------------------------------------------------------
 PURPOSE

 Toggles installation of stdrename - a command-line file/folder renaming utility.
 If installed, uninstalls it. If not installed, downloads and installs it.
 Installs to System32 for system-wide availability.

 DATA SOURCES & PRIORITY

 1) Hardcoded values (download URL, install path)
 2) GitHub releases for stdrename

 REQUIRED INPUTS

 - DownloadUrl  : URL to download stdrename.exe
 - InstallPath  : Installation directory (default: System32)

 SETTINGS

 - Downloads from GitHub releases (latest version)
 - Installs to C:\Windows\System32 for PATH accessibility
 - Toggle behavior: installed -> uninstall, not installed -> install

 BEHAVIOR

 1. Checks if stdrename.exe exists in install path
 2. If exists: deletes the executable (uninstall)
 3. If not exists: downloads from GitHub and installs

 PREREQUISITES

 - Windows 10/11
 - Admin privileges required (writing to System32)
 - Internet connectivity for download

 SECURITY NOTES

 - Downloads from official GitHub releases
 - No secrets in logs
 - Modifies System32 directory

 EXIT CODES

 - 0: Success
 - 1: Failure

 EXAMPLE RUN

 [INFO] INPUT VALIDATION
 ==============================================================
 Download URL : https://github.com/Gadiguibou/stdrename/releases/latest/download/stdrename.exe
 Install Path : C:\Windows\System32
 Exe Path     : C:\Windows\System32\stdrename.exe

 [RUN] OPERATION
 ==============================================================
 Checking for existing installation...
 stdrename not found, downloading...
 Download complete

 [OK] RESULT
 ==============================================================
 Status : Success
 Action : Installed

 [INFO] SCRIPT COMPLETED
 ==============================================================
--------------------------------------------------------------------------------
 CHANGELOG
--------------------------------------------------------------------------------
 2026-01-19 v1.1.1 Updated to two-line ASCII console output style
 2025-12-23 v1.1.0 Updated to Limehawk Script Framework
 2025-11-29 v1.0.0 Initial Style A implementation
================================================================================
#>

Set-StrictMode -Version Latest

# ==== STATE ====
$errorOccurred = $false
$errorText = ""
$actionTaken = ""

# ==== HARDCODED INPUTS ====
$DownloadUrl = "https://github.com/Gadiguibou/stdrename/releases/latest/download/stdrename.exe"
$InstallPath = "$env:SystemRoot\System32"
$ExePath = Join-Path $InstallPath "stdrename.exe"

# ==== VALIDATION ====
if ([string]::IsNullOrWhiteSpace($DownloadUrl)) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- DownloadUrl is required."
}

if ($errorOccurred) {
    Write-Host ""
    Write-Host "[ERROR] ERROR OCCURRED"
    Write-Host "=============================================================="
    Write-Host $errorText
    exit 1
}

# ==== RUNTIME OUTPUT ====
Write-Host ""
Write-Host "[INFO] INPUT VALIDATION"
Write-Host "=============================================================="
Write-Host "Download URL : $DownloadUrl"
Write-Host "Install Path : $InstallPath"
Write-Host "Exe Path     : $ExePath"

Write-Host ""
Write-Host "[RUN] OPERATION"
Write-Host "=============================================================="

try {
    Write-Host "Checking for existing installation..."

    if (Test-Path -Path $ExePath) {
        # Uninstall
        Write-Host "stdrename found, uninstalling..."
        Remove-Item -Path $ExePath -Force -ErrorAction Stop
        $actionTaken = "Uninstalled"
        Write-Host "Uninstall complete"
    } else {
        # Install
        Write-Host "stdrename not found, downloading..."
        Invoke-WebRequest -Uri $DownloadUrl -OutFile $ExePath -UseBasicParsing -ErrorAction Stop

        if (Test-Path -Path $ExePath) {
            $actionTaken = "Installed"
            Write-Host "Download complete"
        } else {
            throw "Download completed but file not found at $ExePath"
        }
    }

} catch {
    $errorOccurred = $true
    $errorText = $_.Exception.Message
}

if ($errorOccurred) {
    Write-Host ""
    Write-Host "[ERROR] ERROR OCCURRED"
    Write-Host "=============================================================="
    Write-Host $errorText
}

Write-Host ""
if ($errorOccurred) {
    Write-Host "[ERROR] RESULT"
} else {
    Write-Host "[OK] RESULT"
}
Write-Host "=============================================================="
if ($errorOccurred) {
    Write-Host "Status : Failure"
} else {
    Write-Host "Status : Success"
    Write-Host "Action : $actionTaken"
}

Write-Host ""
if ($errorOccurred) {
    Write-Host "[ERROR] FINAL STATUS"
} else {
    Write-Host "[OK] FINAL STATUS"
}
Write-Host "=============================================================="
if ($errorOccurred) {
    Write-Host "stdrename toggle failed. See error above."
} else {
    if ($actionTaken -eq "Installed") {
        Write-Host "stdrename has been installed to $InstallPath"
        Write-Host "You can now use 'stdrename' from any command prompt."
    } else {
        Write-Host "stdrename has been uninstalled from $InstallPath"
    }
}

Write-Host ""
Write-Host "[INFO] SCRIPT COMPLETED"
Write-Host "=============================================================="

if ($errorOccurred) {
    exit 1
} else {
    exit 0
}
