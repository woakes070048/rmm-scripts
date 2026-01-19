$ErrorActionPreference = 'Stop'

<#
██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
================================================================================
 SCRIPT   : Time Sync Fix                                                v1.0.3
 AUTHOR   : Limehawk.io
 DATE     : January 2026
 USAGE    : .\time_sync_fix.ps1
================================================================================
 FILE     : time_sync_fix.ps1
DESCRIPTION : Fixes Windows time synchronization by resetting NTP configuration
--------------------------------------------------------------------------------
 README
--------------------------------------------------------------------------------
 PURPOSE

 Fixes Windows time synchronization by setting the timezone, resetting the
 Windows Time service, configuring NTP servers, and forcing a time sync.
 Resolves common time drift and synchronization issues.

 DATA SOURCES & PRIORITY

 1) Hardcoded values (defined within the script body)
 2) Windows Time service (w32time)

 REQUIRED INPUTS

 - TimeZone   : Windows timezone ID (e.g., "Eastern Standard Time")
 - NtpServers : Comma-separated list of NTP servers

 SETTINGS

 - Uses pool.ntp.org servers by default
 - Sets SpecialPollInterval to 86400 seconds (24 hours)
 - Configures w32time triggers for network on/off

 BEHAVIOR

 1. Sets the system timezone
 2. Stops the Windows Time service
 3. Unregisters and re-registers w32time
 4. Configures NTP poll interval in registry
 5. Sets service triggers for network connectivity
 6. Starts the Windows Time service
 7. Configures NTP server list
 8. Forces immediate time resync

 PREREQUISITES

 - Windows 10/11
 - Admin privileges required
 - Network connectivity to NTP servers

 SECURITY NOTES

 - No secrets in logs
 - Modifies system time settings
 - Uses public NTP servers

 EXIT CODES

 - 0: Success
 - 1: Failure

 EXAMPLE RUN

 [INFO] INPUT VALIDATION
 ==============================================================
 Time Zone   : Eastern Standard Time
 NTP Servers : 0.pool.ntp.org,1.pool.ntp.org,2.pool.ntp.org,3.pool.ntp.org

 [RUN] OPERATION
 ==============================================================
 Setting timezone...
 Stopping Windows Time service...
 Re-registering Windows Time service...
 Configuring NTP poll interval...
 Setting service triggers...
 Starting Windows Time service...
 Configuring NTP servers...
 Forcing time resync...

 [OK] RESULT
 ==============================================================
 Status    : Success
 Time Zone : Eastern Standard Time
 Time      : 2025-11-29 14:32:15

 [OK] SCRIPT COMPLETED
 ==============================================================
--------------------------------------------------------------------------------
 CHANGELOG
--------------------------------------------------------------------------------
 2026-01-19 v1.0.3 Fixed EXAMPLE RUN section formatting
 2026-01-19 v1.0.2 Updated to two-line ASCII console output style
 2025-12-23 v1.0.1 Updated to Limehawk Script Framework
 2025-11-29 v1.0.0 Initial Style A implementation
================================================================================
#>

Set-StrictMode -Version Latest

# ==== STATE ====
$errorOccurred = $false
$errorText = ""

# ==== HARDCODED INPUTS ====
$TimeZone = "Eastern Standard Time"
$NtpServers = "0.pool.ntp.org,1.pool.ntp.org,2.pool.ntp.org,3.pool.ntp.org"

# ==== VALIDATION ====
if ([string]::IsNullOrWhiteSpace($TimeZone)) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- TimeZone is required."
}
if ([string]::IsNullOrWhiteSpace($NtpServers)) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- NtpServers is required."
}

if ($errorOccurred) {
    Write-Host ""
    Write-Host "[ERROR] VALIDATION FAILED"
    Write-Host "=============================================================="
    Write-Host $errorText
    exit 1
}

# ==== RUNTIME OUTPUT ====
Write-Host ""
Write-Host "[INFO] INPUT VALIDATION"
Write-Host "=============================================================="
Write-Host "Time Zone   : $TimeZone"
Write-Host "NTP Servers : $NtpServers"

Write-Host ""
Write-Host "[RUN] OPERATION"
Write-Host "=============================================================="

try {
    # Set timezone
    Write-Host "[RUN] Setting timezone..."
    tzutil /s "$TimeZone"
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to set timezone. Verify timezone ID is valid."
    }

    # Stop Windows Time service
    Write-Host "[RUN] Stopping Windows Time service..."
    Stop-Service -Name w32time -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2

    # Unregister and re-register the service
    Write-Host "[RUN] Re-registering Windows Time service..."
    w32tm /unregister 2>$null
    Start-Sleep -Seconds 1
    w32tm /register 2>$null
    Start-Sleep -Seconds 1

    # Configure SpecialPollInterval (24 hours = 86400 seconds)
    Write-Host "[RUN] Configuring NTP poll interval..."
    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\NtpClient"
    Set-ItemProperty -Path $regPath -Name "SpecialPollInterval" -Value 86400 -Type DWord -Force

    # Set service triggers
    Write-Host "[RUN] Setting service triggers..."
    sc.exe triggerinfo w32time start/networkon stop/networkoff 2>$null

    # Start Windows Time service
    Write-Host "[RUN] Starting Windows Time service..."
    Start-Service -Name w32time -ErrorAction Stop
    Start-Sleep -Seconds 2

    # Configure NTP servers
    Write-Host "[RUN] Configuring NTP servers..."
    $peerList = ($NtpServers -split ',') | ForEach-Object { "$_,0x1" }
    $peerListString = $peerList -join ' '
    w32tm /config /manualpeerlist:"$peerListString" /syncfromflags:manual /update
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[WARN] NTP configuration returned non-zero exit code"
    }

    # Force resync
    Write-Host "[RUN] Forcing time resync..."
    Start-Sleep -Seconds 2
    w32tm /resync /force
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[WARN] Time resync returned non-zero exit code"
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

# Get current time info
$currentTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$currentTz = (Get-TimeZone).Id

Write-Host ""
Write-Host "[INFO] RESULT"
Write-Host "=============================================================="
if ($errorOccurred) {
    Write-Host "[ERROR] Status : Failure"
} else {
    Write-Host "[OK] Status    : Success"
    Write-Host "Time Zone : $currentTz"
    Write-Host "Time      : $currentTime"
}

Write-Host ""
Write-Host "[INFO] FINAL STATUS"
Write-Host "=============================================================="
if ($errorOccurred) {
    Write-Host "[ERROR] Time synchronization fix failed. See error above."
} else {
    Write-Host "[OK] Time synchronization has been reset and configured."
}

Write-Host ""
Write-Host "[INFO] SCRIPT COMPLETED"
Write-Host "=============================================================="

if ($errorOccurred) {
    exit 1
} else {
    exit 0
}
