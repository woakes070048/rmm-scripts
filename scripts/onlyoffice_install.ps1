$ErrorActionPreference = 'Stop'
<#
██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝

================================================================================
SCRIPT  : OnlyOffice Install v1.0.2
AUTHOR  : Limehawk.io
DATE      : January 2026
USAGE   : .\onlyoffice_install.ps1
FILE    : onlyoffice_install.ps1
DESCRIPTION : Downloads and silently installs OnlyOffice Desktop Editors
================================================================================
README
--------------------------------------------------------------------------------
PURPOSE:
    Downloads and silently installs OnlyOffice Desktop Editors, a free office
    suite compatible with Microsoft Office formats.

REQUIRED INPUTS:
    $downloadUrl : URL to download OnlyOffice MSI installer

BEHAVIOR:
    1. Validates input parameters
    2. Downloads OnlyOffice MSI installer to temp directory
    3. Installs silently using msiexec
    4. Cleans up installer file

PREREQUISITES:
    - Windows OS (64-bit)
    - Administrator privileges
    - Internet connectivity

SECURITY NOTES:
    - No secrets in logs
    - Downloads from official OnlyOffice website

EXIT CODES:
    0 = Success
    1 = Failure

EXAMPLE RUN:
    [INFO] INPUT VALIDATION
    ==============================================================
    Download URL : https://download.onlyoffice.com/install/desktop/...
    [OK] Inputs validated successfully

    [INFO] DOWNLOAD
    ==============================================================
    [RUN] Downloading OnlyOffice Desktop Editors...
    [OK] Download completed successfully

    [INFO] INSTALLATION
    ==============================================================
    [RUN] Installing OnlyOffice silently...
    [OK] Installation completed successfully

    [INFO] CLEANUP
    ==============================================================
    [RUN] Removing installer file...
    [OK] Cleanup completed

    [INFO] FINAL STATUS
    ==============================================================
    Result : SUCCESS
    OnlyOffice Desktop Editors installed successfully

    [INFO] SCRIPT COMPLETED
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
# HARDCODED INPUTS
# ============================================================================
$downloadUrl = 'https://download.onlyoffice.com/install/desktop/editors/windows/distrib/onlyoffice/DesktopEditors_x64.msi'

# ============================================================================
# INPUT VALIDATION
# ============================================================================
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
    Write-Host "[ERROR] VALIDATION FAILED"
    Write-Host "=============================================================="
    Write-Host $errorText
    exit 1
}

Write-Host "Download URL : $downloadUrl"
Write-Host "[OK] Inputs validated successfully"

# ============================================================================
# DOWNLOAD
# ============================================================================
Write-Host ""
Write-Host "[INFO] DOWNLOAD"
Write-Host "=============================================================="

$installerPath = Join-Path $env:TEMP "DesktopEditors_x64.msi"

try {
    Write-Host "[RUN] Downloading OnlyOffice Desktop Editors..."
    Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath -UseBasicParsing

    if (-not (Test-Path $installerPath)) {
        throw "Installer file was not downloaded"
    }

    Write-Host "[OK] Download completed successfully"
}
catch {
    Write-Host ""
    Write-Host "[ERROR] DOWNLOAD FAILED"
    Write-Host "=============================================================="
    Write-Host "Failed to download OnlyOffice"
    Write-Host "Error : $($_.Exception.Message)"
    exit 1
}

# ============================================================================
# INSTALLATION
# ============================================================================
Write-Host ""
Write-Host "[INFO] INSTALLATION"
Write-Host "=============================================================="

try {
    Write-Host "[RUN] Installing OnlyOffice silently..."
    $process = Start-Process "msiexec.exe" -ArgumentList "/i `"$installerPath`" /quiet /norestart" -Wait -PassThru -NoNewWindow

    if ($process.ExitCode -ne 0) {
        throw "MSI installation failed with exit code: $($process.ExitCode)"
    }

    Write-Host "[OK] Installation completed successfully"
}
catch {
    Write-Host ""
    Write-Host "[ERROR] INSTALLATION FAILED"
    Write-Host "=============================================================="
    Write-Host "Failed to install OnlyOffice"
    Write-Host "Error : $($_.Exception.Message)"
    exit 1
}

# ============================================================================
# CLEANUP
# ============================================================================
Write-Host ""
Write-Host "[INFO] CLEANUP"
Write-Host "=============================================================="

Write-Host "[RUN] Removing installer file..."
Remove-Item -Path $installerPath -Force -ErrorAction SilentlyContinue
Write-Host "[OK] Cleanup completed"

# ============================================================================
# FINAL STATUS
# ============================================================================
Write-Host ""
Write-Host "[INFO] FINAL STATUS"
Write-Host "=============================================================="
Write-Host "Result : SUCCESS"
Write-Host "OnlyOffice Desktop Editors installed successfully"

Write-Host ""
Write-Host "[INFO] SCRIPT COMPLETED"
Write-Host "=============================================================="

exit 0
