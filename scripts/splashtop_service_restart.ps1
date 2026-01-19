$ErrorActionPreference = 'Stop'
<#
██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
================================================================================
 SCRIPT   : Splashtop Service Restart                                   v1.0.3
 AUTHOR   : Limehawk.io
 DATE     : January 2026
 USAGE    : .\splashtop_service_restart.ps1
================================================================================
 FILE     : splashtop_service_restart.ps1
 DESCRIPTION : Restarts Splashtop Remote Service to resolve connectivity issues
--------------------------------------------------------------------------------
 README
--------------------------------------------------------------------------------
 PURPOSE

   Restarts the Splashtop Remote Service to resolve connectivity or
   performance issues with Splashtop remote access.

 DATA SOURCES & PRIORITY

   - Hardcoded service name (defined within the script body)

 REQUIRED INPUTS

   All inputs are hardcoded in the script body:
     - $serviceName : Name of the Splashtop service to restart

 SETTINGS

   - Default service: SplashtopRemoteService
   - Wait time after restart: 3 seconds

 BEHAVIOR

   1. Validates service name input
   2. Checks if service exists
   3. Restarts the service
   4. Reports final status

 PREREQUISITES

   - Windows OS
   - Administrator privileges
   - Splashtop Streamer installed

 SECURITY NOTES

   - No secrets in logs

 ENDPOINTS

   Not applicable - this script does not connect to any network endpoints

 EXIT CODES

   0 = Success
   1 = Failure

 EXAMPLE RUN

   [INFO] INPUT VALIDATION
   ==============================================================
   Service Name : SplashtopRemoteService
   Inputs validated successfully

   [RUN] SERVICE RESTART
   ==============================================================
   Restarting SplashtopRemoteService...
   Service restarted successfully

   [OK] FINAL STATUS
   ==============================================================
   Result : SUCCESS
   Service Name : SplashtopRemoteService
   Status : Running

   [OK] SCRIPT COMPLETED
   ==============================================================

--------------------------------------------------------------------------------
 CHANGELOG
--------------------------------------------------------------------------------
 2026-01-19 v1.0.3 Updated to two-line ASCII console output style
 2026-01-14 v1.0.2 Fixed header formatting for framework compliance
 2025-12-23 v1.0.1 Updated to Limehawk Script Framework
 2024-12-01 v1.0.0 Initial release - migrated from SuperOps
================================================================================
#>
Set-StrictMode -Version Latest

# ============================================================================
# HARDCODED INPUTS
# ============================================================================
$serviceName = 'SplashtopRemoteService'

# ============================================================================
# INPUT VALIDATION
# ============================================================================
Write-Host ""
Write-Host "[INFO] INPUT VALIDATION"
Write-Host "=============================================================="

$errorOccurred = $false
$errorText = ""

if ([string]::IsNullOrWhiteSpace($serviceName)) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- Service name is required"
}

if ($errorOccurred) {
    Write-Host ""
    Write-Host "[ERROR] VALIDATION FAILED"
    Write-Host "=============================================================="
    Write-Host $errorText
    exit 1
}

Write-Host "Service Name : $serviceName"
Write-Host "Inputs validated successfully"

# ============================================================================
# SERVICE RESTART
# ============================================================================
Write-Host ""
Write-Host "[RUN] SERVICE RESTART"
Write-Host "=============================================================="

try {
    $service = Get-Service -Name $serviceName -ErrorAction Stop
    Write-Host "Restarting $serviceName..."
    Restart-Service -InputObject $service -Force
    Start-Sleep -Seconds 3
    Write-Host "Service restarted successfully"
}
catch [Microsoft.PowerShell.Commands.ServiceCommandException] {
    Write-Host ""
    Write-Host "[ERROR] SERVICE NOT FOUND"
    Write-Host "=============================================================="
    Write-Host "Service $serviceName could not be found"
    Write-Host "Ensure Splashtop Streamer is installed"
    exit 1
}
catch {
    Write-Host ""
    Write-Host "[ERROR] RESTART FAILED"
    Write-Host "=============================================================="
    Write-Host "Failed to restart service"
    Write-Host "Error : $($_.Exception.Message)"
    exit 1
}

# ============================================================================
# FINAL STATUS
# ============================================================================
$finalService = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
Write-Host ""
if ($finalService -and $finalService.Status -eq 'Running') {
    Write-Host "[OK] FINAL STATUS"
    Write-Host "=============================================================="
    Write-Host "Result : SUCCESS"
    Write-Host "Service Name : $serviceName"
    Write-Host "Status : $($finalService.Status)"
} else {
    Write-Host "[WARN] FINAL STATUS"
    Write-Host "=============================================================="
    Write-Host "Result : WARNING"
    Write-Host "Service may not be running properly"
    Write-Host "Status : $($finalService.Status)"
}

Write-Host ""
Write-Host "[OK] SCRIPT COMPLETED"
Write-Host "=============================================================="

exit 0
