$ErrorActionPreference = 'Stop'

<#
██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝

================================================================================
SCRIPT: Print Queue Reset                                       VERSION: 1.0.0
================================================================================
FILE: print_queue_reset.ps1

README
--------------------------------------------------------------
PURPOSE

This script resets and clears the Windows print queue by stopping the Print
Spooler service, removing all queued print jobs from the spooler directory,
and restarting the service. This resolves common printing issues caused by
stuck or corrupted print jobs that prevent new documents from printing.

DATA SOURCES & PRIORITY

1. Hardcoded service name and timeout values
2. System spooler directory path ($env:SystemRoot\System32\spool\PRINTERS)
3. Windows Print Spooler service status

REQUIRED INPUTS

- $serviceName: Name of the Print Spooler service (default: "Spooler")
- $stopTimeout: Maximum seconds to wait for service to stop (default: 30)
- $startTimeout: Maximum seconds to wait for service to start (default: 30)

SETTINGS

- Service stop timeout: 30 seconds
- Service start timeout: 30 seconds
- Spooler directory: %SystemRoot%\System32\spool\PRINTERS

BEHAVIOR

1. Validates hardcoded input values
2. Checks current status of Print Spooler service
3. Stops the Print Spooler service if running
4. Removes all print job files from the spooler directory
5. Restarts the Print Spooler service
6. Verifies service is running and reports final status

PREREQUISITES

- Windows operating system
- Administrator privileges (required to manage services and delete files)
- Print Spooler service must exist on the system

SECURITY NOTES

- No secrets in logs
- Requires elevated privileges to modify system services
- Only deletes files from the Windows spooler directory

ENDPOINTS

None - Local system operations only

EXIT CODES

0 = Success - Print queue cleared and service restarted
1 = Failure - Input validation failed, service operations failed, or errors

EXAMPLE RUN

[ INPUT VALIDATION ]
--------------------------------------------------------------
Service name validated
Stop timeout validated
Start timeout validated

[ SERVICE STATUS CHECK ]
--------------------------------------------------------------
Service : Spooler
Status  : Running

[ STOPPING PRINT SPOOLER ]
--------------------------------------------------------------
Stopping service Spooler
Service stopped successfully

[ CLEARING PRINT QUEUE ]
--------------------------------------------------------------
Spooler Directory : C:\Windows\System32\spool\PRINTERS
Files Removed     : 5
Queue cleared successfully

[ STARTING PRINT SPOOLER ]
--------------------------------------------------------------
Starting service Spooler
Service started successfully

[ FINAL STATUS ]
--------------------------------------------------------------
Service : Spooler
Status  : Running
Result  : Print queue cleared and service restarted successfully

[ SCRIPT COMPLETED ]
--------------------------------------------------------------

CHANGELOG
--------------------------------------------------------------
2025-01-17 v1.0.0 Initial release - Print queue reset script

================================================================================
#>

Set-StrictMode -Version Latest

# ============================================================================
# HARDCODED INPUTS
# ============================================================================

$serviceName  = 'Spooler'
$stopTimeout  = 30
$startTimeout = 30

# ============================================================================
# INPUT VALIDATION
# ============================================================================

Write-Host ""
Write-Host "[ INPUT VALIDATION ]"
Write-Host "--------------------------------------------------------------"

$errorOccurred = $false
$errorText     = ""

if ([string]::IsNullOrWhiteSpace($serviceName)) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- Service name is required"
}

if ($stopTimeout -lt 1) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- Stop timeout must be at least 1 second"
}

if ($startTimeout -lt 1) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- Start timeout must be at least 1 second"
}

if ($errorOccurred) {
    Write-Host ""
    Write-Host "[ ERROR OCCURRED ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host "Input validation failed:"
    Write-Host $errorText
    Write-Host ""
    exit 1
}

Write-Host "Service name validated"
Write-Host "Stop timeout validated"
Write-Host "Start timeout validated"

# ============================================================================
# MAIN SCRIPT
# ============================================================================

try {
    # Check service status
    Write-Host ""
    Write-Host "[ SERVICE STATUS CHECK ]"
    Write-Host "--------------------------------------------------------------"

    $service = Get-Service -Name $serviceName
    Write-Host "Service : $($service.Name)"
    Write-Host "Status  : $($service.Status)"

    # Stop the Print Spooler service if running
    Write-Host ""
    Write-Host "[ STOPPING PRINT SPOOLER ]"
    Write-Host "--------------------------------------------------------------"

    if ($service.Status -eq 'Running') {
        Write-Host "Stopping service $serviceName"
        Stop-Service -Name $serviceName -Force

        $waitCount = 0
        while ((Get-Service -Name $serviceName).Status -ne 'Stopped' -and $waitCount -lt $stopTimeout) {
            Start-Sleep -Seconds 1
            $waitCount++
        }

        $service = Get-Service -Name $serviceName
        if ($service.Status -ne 'Stopped') {
            throw "Service failed to stop within $stopTimeout seconds"
        }

        Write-Host "Service stopped successfully"
    } else {
        Write-Host "Service is already stopped"
    }

    # Clear the print queue
    Write-Host ""
    Write-Host "[ CLEARING PRINT QUEUE ]"
    Write-Host "--------------------------------------------------------------"

    $spoolPath = "$env:SystemRoot\System32\spool\PRINTERS"
    Write-Host "Spooler Directory : $spoolPath"

    $files = Get-ChildItem -Path $spoolPath -File -ErrorAction SilentlyContinue
    $fileCount = if ($files) { $files.Count } else { 0 }

    if ($fileCount -gt 0) {
        Remove-Item -Path "$spoolPath\*.*" -Force -ErrorAction Stop
        Write-Host "Files Removed     : $fileCount"
        Write-Host "Queue cleared successfully"
    } else {
        Write-Host "Files Removed     : 0"
        Write-Host "No print jobs to clear"
    }

    # Start the Print Spooler service
    Write-Host ""
    Write-Host "[ STARTING PRINT SPOOLER ]"
    Write-Host "--------------------------------------------------------------"

    Write-Host "Starting service $serviceName"
    Start-Service -Name $serviceName

    $waitCount = 0
    while ((Get-Service -Name $serviceName).Status -ne 'Running' -and $waitCount -lt $startTimeout) {
        Start-Sleep -Seconds 1
        $waitCount++
    }

    $service = Get-Service -Name $serviceName
    if ($service.Status -ne 'Running') {
        throw "Service failed to start within $startTimeout seconds"
    }

    Write-Host "Service started successfully"

    # Final status
    Write-Host ""
    Write-Host "[ FINAL STATUS ]"
    Write-Host "--------------------------------------------------------------"

    $service = Get-Service -Name $serviceName
    Write-Host "Service : $($service.Name)"
    Write-Host "Status  : $($service.Status)"
    Write-Host "Result  : Print queue cleared and service restarted successfully"

    Write-Host ""
    Write-Host "[ SCRIPT COMPLETED ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host ""

    exit 0

} catch {
    Write-Host ""
    Write-Host "[ ERROR OCCURRED ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host "Failed to reset print queue"
    Write-Host ""
    Write-Host "Error Message : $($_.Exception.Message)"
    Write-Host "Error Location: $($_.InvocationInfo.ScriptLineNumber):$($_.InvocationInfo.OffsetInLine)"
    Write-Host ""
    Write-Host "Troubleshooting:"
    Write-Host "- Ensure script is running with administrator privileges"
    Write-Host "- Verify Print Spooler service exists on this system"
    Write-Host "- Check if another process is locking the spooler directory"
    Write-Host ""
    exit 1
}
