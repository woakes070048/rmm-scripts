$ErrorActionPreference = 'Stop'

<#
██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
================================================================================
 SCRIPT   : Dell Command Update v1.0.0
 VERSION  : v1.0.0
================================================================================
 FILE     : dell_command_update.ps1
--------------------------------------------------------------------------------
 README
--------------------------------------------------------------------------------
 PURPOSE

 Installs Dell Command Update via Chocolatey and runs it to scan and apply
 driver/firmware updates silently. Designed for automated Dell system maintenance
 in RMM environments.

 DATA SOURCES & PRIORITY

 1) Hardcoded values (defined within the script body)
 2) Chocolatey package manager
 3) Dell Command Update CLI

 REQUIRED INPUTS

 - DcuCliPath    : Path to Dell Command Update CLI executable
 - DcuLogPath    : Directory for DCU log files
 - PackageName   : Chocolatey package name for Dell Command Update

 SETTINGS

 - Uses Chocolatey for package management
 - Configures DCU to auto-suspend BitLocker and disable user consent prompts
 - Applies updates without rebooting (reboot=disable)
 - Logs scan and apply operations to C:\dell\logs

 BEHAVIOR

 1. Verifies Chocolatey is installed
 2. Installs Dell Command Update UWP package if not present
 3. Verifies DCU CLI exists
 4. Configures DCU for silent operation
 5. Scans for available updates
 6. Applies updates without rebooting

 PREREQUISITES

 - Chocolatey package manager installed
 - Dell system (script will fail on non-Dell hardware)
 - Admin privileges for installation and updates

 SECURITY NOTES

 - No secrets in logs
 - Only affects Dell driver/firmware components

 EXIT CODES

 - 0: Success
 - 1: Failure (Chocolatey not found, DCU not installed, etc.)

 EXAMPLE RUN

 [ INPUT VALIDATION ]
 --------------------------------------------------------------
 DCU CLI Path : C:\Program Files\Dell\CommandUpdate\dcu-cli.exe
 DCU Log Path : C:\dell\logs
 Package Name : DellCommandUpdate-UWP

 [ OPERATION ]
 --------------------------------------------------------------
 Checking for Chocolatey...
 Installing Dell Command Update...
 Configuring Dell Command Update...
 Scanning for updates...
 Applying updates...

 [ RESULT ]
 --------------------------------------------------------------
 Status : Success

 [ SCRIPT COMPLETED ]
 --------------------------------------------------------------
--------------------------------------------------------------------------------
 CHANGELOG
 2025-11-29 v1.0.0 Initial Style A implementation
================================================================================
#>

Set-StrictMode -Version Latest

# ==== STATE ====
$errorOccurred = $false
$errorText = ""

# ==== HARDCODED INPUTS ====
$DcuCliPath = "C:\Program Files\Dell\CommandUpdate\dcu-cli.exe"
$DcuLogPath = "C:\dell\logs"
$PackageName = "DellCommandUpdate-UWP"

# ==== VALIDATION ====
if ([string]::IsNullOrWhiteSpace($DcuCliPath)) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- DcuCliPath is required."
}
if ([string]::IsNullOrWhiteSpace($DcuLogPath)) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- DcuLogPath is required."
}
if ([string]::IsNullOrWhiteSpace($PackageName)) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- PackageName is required."
}

if ($errorOccurred) {
    Write-Host ""
    Write-Host "[ ERROR OCCURRED ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host $errorText
    exit 1
}

# ==== RUNTIME OUTPUT ====
Write-Host ""
Write-Host "[ INPUT VALIDATION ]"
Write-Host "--------------------------------------------------------------"
Write-Host "DCU CLI Path : $DcuCliPath"
Write-Host "DCU Log Path : $DcuLogPath"
Write-Host "Package Name : $PackageName"

Write-Host ""
Write-Host "[ OPERATION ]"
Write-Host "--------------------------------------------------------------"

try {
    # Check for Chocolatey
    Write-Host "Checking for Chocolatey..."
    if (-not (Get-Command "choco" -ErrorAction SilentlyContinue)) {
        throw "Chocolatey is not installed. Please install Chocolatey first."
    }
    Write-Host "Chocolatey found"

    # Install Dell Command Update if not present
    Write-Host "Checking for Dell Command Update..."
    $installed = choco list --local-only 2>$null | Select-String $PackageName
    if (-not $installed) {
        Write-Host "Installing $PackageName..."
        $result = choco install $PackageName -y 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to install $PackageName"
        }
        Write-Host "Installation complete"
    } else {
        Write-Host "Dell Command Update already installed"
    }

    # Verify DCU CLI exists
    if (-not (Test-Path $DcuCliPath)) {
        throw "DCU CLI not found at $DcuCliPath. Installation may have failed."
    }

    # Ensure log directory exists
    if (-not (Test-Path $DcuLogPath)) {
        New-Item -Path $DcuLogPath -ItemType Directory -Force | Out-Null
        Write-Host "Created log directory: $DcuLogPath"
    }

    # Configure DCU for silent operation
    Write-Host "Configuring Dell Command Update..."
    & $DcuCliPath /configure -silent -autoSuspendBitLocker=enable -userConsent=disable
    Write-Host "Configuration complete"

    # Scan for updates
    Write-Host "Scanning for updates..."
    & $DcuCliPath /scan -outputLog="$DcuLogPath\scan.log"
    Write-Host "Scan complete (log: $DcuLogPath\scan.log)"

    # Apply updates without rebooting
    Write-Host "Applying updates..."
    & $DcuCliPath /applyUpdates -reboot=disable -outputLog="$DcuLogPath\applyUpdates.log"
    Write-Host "Updates applied (log: $DcuLogPath\applyUpdates.log)"

} catch {
    $errorOccurred = $true
    $errorText = $_.Exception.Message
}

if ($errorOccurred) {
    Write-Host ""
    Write-Host "[ ERROR OCCURRED ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host $errorText

    Write-Host ""
    Write-Host "[ RESULT ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host "Status : Failure"
} else {
    Write-Host ""
    Write-Host "[ RESULT ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host "Status : Success"
}

Write-Host ""
Write-Host "[ FINAL STATUS ]"
Write-Host "--------------------------------------------------------------"
if ($errorOccurred) {
    Write-Host "Dell Command Update process failed. See error above."
} else {
    Write-Host "Dell Command Update completed successfully."
    Write-Host "Reboot may be required for some updates to take effect."
}

Write-Host ""
Write-Host "[ SCRIPT COMPLETED ]"
Write-Host "--------------------------------------------------------------"

if ($errorOccurred) {
    exit 1
} else {
    exit 0
}
