$ErrorActionPreference = 'Stop'

<#
██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
================================================================================
SCRIPT  : Dell Command Update v2.1.1
AUTHOR  : Limehawk.io
DATE    : December 2024
USAGE   : .\dell_command_update.ps1
FILE    : dell_command_update.ps1
================================================================================
README
--------------------------------------------------------------------------------
 PURPOSE

 Installs Dell Command Update via winget and runs it to scan and apply
 driver/firmware updates silently. Designed for automated Dell system maintenance
 in RMM environments.

 DATA SOURCES & PRIORITY

 1) Hardcoded values (defined within the script body)
 2) winget package manager
 3) Dell Command Update CLI

 REQUIRED INPUTS

 - DcuCliPath    : Path to Dell Command Update CLI executable
 - DcuLogPath    : Directory for DCU log files
 - WingetId      : winget package ID for Dell Command Update

 SETTINGS

 - Uses winget for package management
 - Configures DCU to auto-suspend BitLocker and disable user consent prompts
 - Applies updates without rebooting (reboot=disable)
 - Logs scan and apply operations to C:\dell\logs

 BEHAVIOR

 1. Verifies winget is available
 2. Installs Dell Command Update if not present
 3. Verifies DCU CLI exists
 4. Configures DCU for silent operation
 5. Scans for available updates and outputs log to console
 6. Applies updates without rebooting and outputs log to console

 PREREQUISITES

 - Windows 10 1809+ or Windows 11 with winget
 - Dell system (script will fail on non-Dell hardware)
 - Admin privileges for installation and updates

 SECURITY NOTES

 - No secrets in logs
 - Only affects Dell driver/firmware components

 EXIT CODES

 - 0: Success
 - 1: Failure (winget not found, DCU not installed, etc.)

 EXAMPLE RUN

 [ INPUT VALIDATION ]
 --------------------------------------------------------------
 DCU CLI Path : C:\Program Files\Dell\CommandUpdate\dcu-cli.exe
 DCU Log Path : C:\dell\logs
 Winget ID    : Dell.CommandUpdate

 [ OPERATION ]
 --------------------------------------------------------------
 Checking for winget...
 winget found
 Checking for Dell Command Update...
 Dell Command Update already installed
 Configuring Dell Command Update...
 Configuration complete
 Scanning for updates...
 Scan complete

 [ SCAN LOG ]
 --------------------------------------------------------------
 <Dell Command Update scan results displayed here>

 [ OPERATION ]
 --------------------------------------------------------------
 Applying updates...
 Updates applied

 [ APPLY UPDATES LOG ]
 --------------------------------------------------------------
 <Dell Command Update apply results displayed here>

 [ RESULT ]
 --------------------------------------------------------------
 Status : Success

 [ SCRIPT COMPLETED ]
 --------------------------------------------------------------

CHANGELOG
--------------------------------------------------------------------------------
2024-12-23 v2.1.1 Updated to Limehawk Script Framework
2025-12-01 v2.1.0 Output scan and apply log contents to console for RMM visibility
2025-12-01 v2.0.0 Switched from Chocolatey to winget for package management
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
$WingetId = "Dell.CommandUpdate"

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
if ([string]::IsNullOrWhiteSpace($WingetId)) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- WingetId is required."
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
Write-Host "Winget ID    : $WingetId"

Write-Host ""
Write-Host "[ OPERATION ]"
Write-Host "--------------------------------------------------------------"

try {
    # Check for winget
    Write-Host "Checking for winget..."
    $wingetPath = Get-Command "winget" -ErrorAction SilentlyContinue
    if (-not $wingetPath) {
        throw "winget is not available. Windows 10 1809+ or Windows 11 required."
    }
    Write-Host "winget found"

    # Check if Dell Command Update is already installed
    Write-Host "Checking for Dell Command Update..."
    $installed = winget list -e --id $WingetId --accept-source-agreements 2>$null | Select-String $WingetId

    if (-not $installed) {
        Write-Host "Installing $WingetId..."
        $installResult = winget install -e --id $WingetId --silent --accept-package-agreements --accept-source-agreements 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to install $WingetId. Exit code: $LASTEXITCODE"
        }
        Write-Host "Installation complete"
    } else {
        Write-Host "Dell Command Update already installed"

        # Check for updates
        Write-Host "Checking for DCU updates..."
        $upgradeResult = winget upgrade -e --id $WingetId --silent --accept-package-agreements --accept-source-agreements 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "DCU upgraded to latest version"
        }
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
    Write-Host "Scan complete"

    # Output scan log
    Write-Host ""
    Write-Host "[ SCAN LOG ]"
    Write-Host "--------------------------------------------------------------"
    if (Test-Path "$DcuLogPath\scan.log") {
        Get-Content "$DcuLogPath\scan.log" | ForEach-Object { Write-Host $_ }
    } else {
        Write-Host "Scan log not found."
    }

    # Apply updates without rebooting
    Write-Host ""
    Write-Host "[ OPERATION ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host "Applying updates..."
    & $DcuCliPath /applyUpdates -reboot=disable -outputLog="$DcuLogPath\applyUpdates.log"
    Write-Host "Updates applied"

    # Output apply log
    Write-Host ""
    Write-Host "[ APPLY UPDATES LOG ]"
    Write-Host "--------------------------------------------------------------"
    if (Test-Path "$DcuLogPath\applyUpdates.log") {
        Get-Content "$DcuLogPath\applyUpdates.log" | ForEach-Object { Write-Host $_ }
    } else {
        Write-Host "Apply updates log not found."
    }

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
