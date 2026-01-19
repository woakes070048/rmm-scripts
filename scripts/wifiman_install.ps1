$ErrorActionPreference = 'Stop'
<#
██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝

================================================================================
SCRIPT  : WiFiman Install v1.0.2
AUTHOR  : Limehawk.io
DATE    : January 2026
USAGE   : .\wifiman_install.ps1
FILE    : wifiman_install.ps1
DESCRIPTION : Installs Ubiquiti WiFiman Desktop via winget
================================================================================
README
--------------------------------------------------------------------------------
PURPOSE:
    Installs Ubiquiti WiFiman Desktop application using winget. Automatically
    installs winget if not present on the system.

REQUIRED INPUTS:
    $packageId : Winget package ID for WiFiman

BEHAVIOR:
    1. Validates input parameters
    2. Checks if winget is installed
    3. If winget not found, installs via PowerShell Gallery
    4. Installs WiFiman using winget
    5. Reports final status

PREREQUISITES:
    - Windows 10 1809+ or Windows 11
    - Administrator privileges
    - Internet connectivity

SECURITY NOTES:
    - No secrets in logs
    - Installs from official Microsoft winget repository

EXIT CODES:
    0 = Success
    1 = Failure

EXAMPLE RUN:
    [INFO] INPUT VALIDATION
    ==============================================================
    Package ID : UbiquitiInc.WiFimanDesktop
    [OK] Inputs validated successfully

    [INFO] WINGET CHECK
    ==============================================================
    [RUN] Checking for winget...
    [OK] winget is already installed

    [INFO] INSTALLATION
    ==============================================================
    [RUN] Installing WiFiman via winget...
    [OK] Installation completed successfully

    [INFO] FINAL STATUS
    ==============================================================
    Result : SUCCESS
    WiFiman installed successfully

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
$packageId = 'UbiquitiInc.WiFimanDesktop'

# ============================================================================
# INPUT VALIDATION
# ============================================================================
Write-Host ""
Write-Host "[INFO] INPUT VALIDATION"
Write-Host "=============================================================="

$errorOccurred = $false
$errorText = ""

if ([string]::IsNullOrWhiteSpace($packageId)) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- Package ID is required"
}

if ($errorOccurred) {
    Write-Host ""
    Write-Host "[ERROR] VALIDATION FAILED"
    Write-Host "=============================================================="
    Write-Host $errorText
    exit 1
}

Write-Host "Package ID : $packageId"
Write-Host "[OK] Inputs validated successfully"

# ============================================================================
# WINGET CHECK
# ============================================================================
Write-Host ""
Write-Host "[INFO] WINGET CHECK"
Write-Host "=============================================================="

Write-Host "[RUN] Checking for winget..."

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "[WARN] winget not detected, installing via PowerShell Gallery..."

    try {
        if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
            Write-Host "[RUN] Installing NuGet provider..."
            Install-PackageProvider -Name NuGet -Force -ErrorAction Stop | Out-Null
        }

        Write-Host "[RUN] Installing winget-install script..."
        Install-Script winget-install -Force -ErrorAction Stop

        Write-Host "[RUN] Running winget-install..."
        & winget-install -Force 2>&1 | Out-Null

        if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
            throw "winget is still not available after installation"
        }

        Write-Host "[OK] winget installed successfully"
    }
    catch {
        Write-Host ""
        Write-Host "[ERROR] WINGET INSTALLATION FAILED"
        Write-Host "=============================================================="
        Write-Host "Failed to install winget"
        Write-Host "Error : $($_.Exception.Message)"
        exit 1
    }
} else {
    Write-Host "[OK] winget is already installed"
}

# ============================================================================
# INSTALLATION
# ============================================================================
Write-Host ""
Write-Host "[INFO] INSTALLATION"
Write-Host "=============================================================="

try {
    Write-Host "[RUN] Installing WiFiman via winget..."
    $result = winget install --id=$packageId -e --accept-package-agreements --accept-source-agreements 2>&1
    Write-Host $result
    Write-Host "[OK] Installation completed successfully"
}
catch {
    Write-Host ""
    Write-Host "[ERROR] INSTALLATION FAILED"
    Write-Host "=============================================================="
    Write-Host "Failed to install WiFiman"
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
Write-Host "WiFiman installed successfully"

Write-Host ""
Write-Host "[INFO] SCRIPT COMPLETED"
Write-Host "=============================================================="

exit 0
