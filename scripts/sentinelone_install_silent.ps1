<#
██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
================================================================================
 SCRIPT   : SentinelOne Silent Installation v1.0.1
 AUTHOR   : Limehawk.io
 DATE     : December 2024
 USAGE    : .\sentinelone_install_silent.ps1
================================================================================
 FILE     : sentinelone_install_silent.ps1
--------------------------------------------------------------------------------
 README
--------------------------------------------------------------------------------

PURPOSE

Installs SentinelOne agent silently on Windows systems using the MSI installer
package. Requires a valid SentinelOne site token for agent registration with
the management console. Designed for mass deployment via RMM platforms.

DATA SOURCES & PRIORITY

1. Local MSI file path - Must be accessible on target system
2. Site token - Obtained from SentinelOne management console

REQUIRED INPUTS

$installerPath  - Full path to SentinelOne MSI installer
                  Must be a valid .msi file
                  Example: "C:\Temp\SentinelInstaller.msi"

$siteToken      - SentinelOne site token for agent registration
                  Obtained from SentinelOne console > Sentinels > Site Token
                  Must be valid for the target site
                  Example: "eyJYWFhYWFhYWCI6ICJodHRwczovL2V4YW1wbGUuc2VudGluZWxvbmUubmV0Iiwg..."

SETTINGS

- Installation mode: Silent (/qn flag)
- Installer: Windows MSI (msiexec.exe)
- Site registration: Automatic using provided token
- User interaction: None required
- Reboot: Not forced (agent will activate on next reboot if needed)

BEHAVIOR

1. Validates inputs (installer path exists, token provided)
2. Validates installer is MSI format
3. Executes silent installation with site token
4. Monitors installation exit code
5. Reports installation status

PREREQUISITES

- Windows PowerShell 5.1 or PowerShell 7+
- Administrator privileges (required for agent installation)
- SentinelOne MSI installer downloaded locally
- Valid site token from SentinelOne console
- No modules required

SECURITY NOTES

- Site token is logged but not displayed (use RMM secure variables in production)
- Installer must be from trusted source only
- Agent establishes outbound connection to SentinelOne cloud
- No secrets displayed in console output

ENDPOINTS

- SentinelOne cloud (outbound connection established by agent post-install)

EXIT CODES

- 0: Success - SentinelOne installed successfully
- 1: Failure - Installation failed or validation error

EXAMPLE RUN

PS> .\sentinelone_install_silent.ps1

[ INPUT VALIDATION ]
--------------------------------------------------------------
Validating configuration...
Installer path : C:\Temp\SentinelInstaller_windows_64bit.msi
Installer type : MSI
Site token     : Configured
Input validation passed

[ INSTALLATION ]
--------------------------------------------------------------
Starting SentinelOne installation...
Installation mode : Silent
Using site token  : Yes
Installing...
Installation completed

[ FINAL STATUS ]
--------------------------------------------------------------
Installation exit code : 0
Installation status    : Success

[ SCRIPT COMPLETED ]
--------------------------------------------------------------
Script completed successfully
Exit code : 0

--------------------------------------------------------------------------------
 CHANGELOG
--------------------------------------------------------------------------------
 2024-12-23 v1.0.1 Updated to Limehawk Script Framework
 2025-11-02 v1.0.0 Initial migration from SuperOps
================================================================================
#>

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# ============================================================================
# HARDCODED INPUTS
# ============================================================================

# Path to SentinelOne MSI installer
# Example: "C:\Temp\SentinelInstaller_windows_64bit.msi"
$installerPath = "C:\Temp\SentinelInstaller.msi"

# SentinelOne site token (obtain from SentinelOne console)
# Navigate to: Sentinels > Actions > Download Agent > Copy Site Token
# Example: "eyJYWFhYWFhYWCI6ICJodHRwczovL2V4YW1wbGUuc2VudGluZWxvbmUubmV0Iiwg..."
$siteToken = ""

# ============================================================================
# INPUT VALIDATION
# ============================================================================

Write-Host ""
Write-Host "[ INPUT VALIDATION ]"
Write-Host "--------------------------------------------------------------"
Write-Host "Validating configuration..."

$errorOccurred = $false
$errorText = ""

# Validate installer path
if ([string]::IsNullOrWhiteSpace($installerPath)) {
    $errorOccurred = $true
    $errorText += "- Installer path is required`n"
}

# Validate site token
if ([string]::IsNullOrWhiteSpace($siteToken)) {
    $errorOccurred = $true
    $errorText += "- Site token is required`n"
}

if ($errorOccurred) {
    Write-Host ""
    Write-Host "[ ERROR OCCURRED ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host "Input validation failed:"
    Write-Host ""
    Write-Host $errorText
    Write-Host "Troubleshooting:"
    Write-Host "- Set installerPath to full path of SentinelOne MSI"
    Write-Host "- Set siteToken from SentinelOne console"
    Write-Host "- Update hardcoded values in script before running"
    Write-Host ""
    exit 1
}

Write-Host "Installer path : $installerPath"
Write-Host "Site token     : Configured"

# Validate installer file exists
try {
    if (-not (Test-Path -Path $installerPath)) {
        Write-Host ""
        Write-Host "[ ERROR OCCURRED ]"
        Write-Host "--------------------------------------------------------------"
        Write-Host "Installer file not found"
        Write-Host ""
        Write-Host "Path checked : $installerPath"
        Write-Host ""
        Write-Host "Troubleshooting:"
        Write-Host "- Verify the installer file exists at specified path"
        Write-Host "- Ensure full path is provided (e.g., C:\Temp\installer.msi)"
        Write-Host "- Check file permissions allow access"
        Write-Host ""
        exit 1
    }

    # Validate MSI extension
    if ($installerPath -notmatch '\.msi$') {
        Write-Host ""
        Write-Host "[ ERROR OCCURRED ]"
        Write-Host "--------------------------------------------------------------"
        Write-Host "Installer must be an MSI file"
        Write-Host ""
        Write-Host "File provided : $installerPath"
        Write-Host ""
        Write-Host "Troubleshooting:"
        Write-Host "- SentinelOne Windows agent uses .msi installer format"
        Write-Host "- Download the correct Windows agent from SentinelOne console"
        Write-Host ""
        exit 1
    }

    Write-Host "Installer type : MSI"
    Write-Host "Input validation passed"

} catch {
    Write-Host ""
    Write-Host "[ ERROR OCCURRED ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host "Failed to validate installer file"
    Write-Host ""
    Write-Host "Error details:"
    Write-Host $_.Exception.Message
    Write-Host ""
    exit 1
}

# ============================================================================
# INSTALLATION
# ============================================================================

Write-Host ""
Write-Host "[ INSTALLATION ]"
Write-Host "--------------------------------------------------------------"
Write-Host "Starting SentinelOne installation..."

try {
    Write-Host "Installation mode : Silent"
    Write-Host "Using site token  : Yes"
    Write-Host "Installing..."

    # Execute silent installation with site token
    $arguments = "/i `"$installerPath`" /qn SITE_TOKEN=`"$siteToken`""

    $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $arguments -NoNewWindow -Wait -PassThru

    $exitCode = $process.ExitCode

    if ($exitCode -eq 0) {
        Write-Host "Installation completed"
    } else {
        Write-Host ""
        Write-Host "[ ERROR OCCURRED ]"
        Write-Host "--------------------------------------------------------------"
        Write-Host "Installation failed"
        Write-Host ""
        Write-Host "MSI exit code : $exitCode"
        Write-Host ""
        Write-Host "Common exit codes:"
        Write-Host "- 1603: Fatal error during installation"
        Write-Host "- 1618: Another installation is in progress"
        Write-Host "- 1619: Installation package could not be opened"
        Write-Host "- 1622: Error opening installation log file"
        Write-Host "- 1625: This installation is forbidden by system policy"
        Write-Host ""
        Write-Host "Troubleshooting:"
        Write-Host "- Ensure no other installations are running"
        Write-Host "- Verify Administrator privileges"
        Write-Host "- Check if another AV is blocking installation"
        Write-Host "- Verify site token is valid and not expired"
        Write-Host "- Review Windows Event Log for details"
        Write-Host ""
        exit 1
    }

} catch {
    Write-Host ""
    Write-Host "[ ERROR OCCURRED ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host "Installation process failed"
    Write-Host ""
    Write-Host "Error details:"
    Write-Host $_.Exception.Message
    Write-Host ""
    Write-Host "Troubleshooting:"
    Write-Host "- Ensure msiexec.exe is available"
    Write-Host "- Verify Administrator privileges"
    Write-Host "- Check installer file is not corrupted"
    Write-Host ""
    exit 1
}

# ============================================================================
# FINAL STATUS
# ============================================================================

Write-Host ""
Write-Host "[ FINAL STATUS ]"
Write-Host "--------------------------------------------------------------"
Write-Host "Installation exit code : 0"
Write-Host "Installation status    : Success"
Write-Host ""
Write-Host "Next steps:"
Write-Host "- Verify agent appears in SentinelOne console"
Write-Host "- Check agent status and policy assignment"
Write-Host "- A reboot may be required for full activation"

# ============================================================================
# SCRIPT COMPLETED
# ============================================================================

Write-Host ""
Write-Host "[ SCRIPT COMPLETED ]"
Write-Host "--------------------------------------------------------------"
Write-Host "Script completed successfully"
Write-Host "Exit code : 0"
Write-Host ""

exit 0
