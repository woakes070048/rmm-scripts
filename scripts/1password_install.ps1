$ErrorActionPreference = 'Stop'
<#
██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
================================================================================
 SCRIPT   : 1Password Install                                            v1.2.1
 AUTHOR   : Limehawk.io
 DATE     : January 2026
 USAGE    : .\1password_install.ps1
================================================================================
 FILE     : 1password_install.ps1
 DESCRIPTION : Downloads and silently installs 1Password using official MSI
--------------------------------------------------------------------------------
 README
--------------------------------------------------------------------------------
 PURPOSE

   Downloads and silently installs the latest version of 1Password for Windows
   using the official MSI installer with configurable deployment options.

 DATA SOURCES & PRIORITY

   - Official 1Password download URL (hardcoded)
   - No external dependencies

 REQUIRED INPUTS

   All inputs are hardcoded in the script body:
     - $downloadUrl        : URL to download 1Password MSI installer
     - $preventRestart     : Prevent automatic restart after install (true/false)
     - $manageUpdates      : Disable user-initiated updates (true/false)
     - $removeOtherInstalls: Remove other 1Password installations (true/false)

 SETTINGS

   Configuration defaults:
     - Download URL: https://downloads.1password.com/win/1PasswordSetup-latest.msi
     - Prevent Restart: true
     - Manage Updates: false
     - Remove Other Installs: true

 BEHAVIOR

   The script performs the following actions in order:
   1. Validates input parameters
   2. Downloads 1Password MSI installer to temp directory
   3. Builds MSI arguments based on deployment options
   4. Installs silently using msiexec
   5. Cleans up installer file

 PREREQUISITES

   - Windows PowerShell 5.1 or later
   - Administrator privileges
   - Internet connectivity

 SECURITY NOTES

   - No secrets in logs
   - Downloads from official 1Password URL only

 ENDPOINTS

   - https://downloads.1password.com - Official 1Password download server

 EXIT CODES

   0 = Success
   1 = Failure (error occurred)

 EXAMPLE RUN

   [INFO] INPUT VALIDATION
   ==============================================================
     Download URL          : https://downloads.1password.com/win/1PasswordSetup-latest.msi
     Prevent Restart       : True
     Manage Updates        : False
     Remove Other Installs : True
     Inputs validated successfully

   [RUN] DOWNLOAD
   ==============================================================
     Downloading 1Password installer...
     Download completed successfully

   [RUN] INSTALLATION
   ==============================================================
     Installing 1Password silently...
     Option: Prevent restart enabled
     Option: Remove other installations enabled
     Installation completed successfully

   [RUN] CLEANUP
   ==============================================================
     Removing installer file...
     Cleanup completed

   [OK] FINAL STATUS
   ==============================================================
     Result : SUCCESS
     1Password installed successfully

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
# HARDCODED INPUTS
# ==============================================================================
$downloadUrl         = 'https://downloads.1password.com/win/1PasswordSetup-latest.msi'
$preventRestart      = $true
$manageUpdates       = $false
$removeOtherInstalls = $true

# ==============================================================================
# INPUT VALIDATION
# ==============================================================================

Write-Host ""
Write-Host "[INFO] INPUT VALIDATION"
Write-Host "=============================================================="

$errorOccurred = $false
$errorText = ""

if ([string]::IsNullOrWhiteSpace($downloadUrl)) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- Download URL is required"
}

if ($errorOccurred) {
    Write-Host ""
    Write-Host "[ERROR] ERROR OCCURRED"
    Write-Host "=============================================================="
    Write-Host $errorText
    Write-Host ""
    Write-Host "[ERROR] SCRIPT COMPLETED"
    Write-Host "=============================================================="
    exit 1
}

Write-Host "  Download URL          : $downloadUrl"
Write-Host "  Prevent Restart       : $preventRestart"
Write-Host "  Manage Updates        : $manageUpdates"
Write-Host "  Remove Other Installs : $removeOtherInstalls"
Write-Host "  Inputs validated successfully"

# ==============================================================================
# DOWNLOAD
# ==============================================================================

Write-Host ""
Write-Host "[RUN] DOWNLOAD"
Write-Host "=============================================================="

$installerPath = Join-Path $env:TEMP "1PasswordSetup-latest.msi"

try {
    Write-Host "  Downloading 1Password installer..."
    Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath -UseBasicParsing

    if (-not (Test-Path $installerPath)) {
        throw "Installer file was not downloaded"
    }

    Write-Host "  Download completed successfully"
}
catch {
    Write-Host ""
    Write-Host "[ERROR] ERROR OCCURRED"
    Write-Host "=============================================================="
    Write-Host "  Failed to download 1Password installer"
    Write-Host "  Error : $($_.Exception.Message)"
    Write-Host ""
    Write-Host "[ERROR] SCRIPT COMPLETED"
    Write-Host "=============================================================="
    exit 1
}

# ==============================================================================
# INSTALLATION
# ==============================================================================

Write-Host ""
Write-Host "[RUN] INSTALLATION"
Write-Host "=============================================================="

try {
    Write-Host "  Installing 1Password silently..."

    $msiArgs = @("/i", "`"$installerPath`"", "/qn")

    if ($preventRestart) {
        $msiArgs += "/norestart"
        Write-Host "  Option: Prevent restart enabled"
    }

    if ($manageUpdates) {
        $msiArgs += "MANAGED_UPDATE=1"
        Write-Host "  Option: User updates disabled"
    }

    if ($removeOtherInstalls) {
        $msiArgs += "MANAGED_INSTALL=1"
        Write-Host "  Option: Remove other installations enabled"
    }

    $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $msiArgs -Wait -PassThru -NoNewWindow

    if ($process.ExitCode -ne 0) {
        throw "MSI installation failed with exit code: $($process.ExitCode)"
    }

    Write-Host "  Installation completed successfully"
}
catch {
    Write-Host ""
    Write-Host "[ERROR] ERROR OCCURRED"
    Write-Host "=============================================================="
    Write-Host "  Failed to install 1Password"
    Write-Host "  Error : $($_.Exception.Message)"
    Write-Host ""
    Write-Host "[ERROR] SCRIPT COMPLETED"
    Write-Host "=============================================================="
    exit 1
}

# ==============================================================================
# CLEANUP
# ==============================================================================

Write-Host ""
Write-Host "[RUN] CLEANUP"
Write-Host "=============================================================="
Write-Host "  Removing installer file..."
Remove-Item -Path $installerPath -Force -ErrorAction SilentlyContinue
Write-Host "  Cleanup completed"

# ==============================================================================
# FINAL STATUS
# ==============================================================================

Write-Host ""
Write-Host "[OK] FINAL STATUS"
Write-Host "=============================================================="
Write-Host "  Result : SUCCESS"
Write-Host "  1Password installed successfully"

# ==============================================================================
# SCRIPT COMPLETED
# ==============================================================================

Write-Host ""
Write-Host "[OK] SCRIPT COMPLETED"
Write-Host "=============================================================="

exit 0
