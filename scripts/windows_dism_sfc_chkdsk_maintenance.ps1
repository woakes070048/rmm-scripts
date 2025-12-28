$ErrorActionPreference = 'Stop'

<#
██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝ 
██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗ 
███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
================================================================================
 SCRIPT   : Windows DISM SFC Chkdsk Maintenance                          v1.2.0
 AUTHOR   : Limehawk.io
 DATE     : December 2024
 USAGE    : .\windows_dism_sfc_chkdsk_maintenance.ps1
================================================================================
 FILE     : windows_dism_sfc_chkdsk_maintenance.ps1
--------------------------------------------------------------------------------
 README
--------------------------------------------------------------------------------
 PURPOSE
 Runs standard Windows health checks and repair commands including DISM image
 health scans, disk checks, system file verification, and component cleanup.
 Designed for unattended execution in RMM environments to perform routine
 system maintenance and repair operations.

 DATA SOURCES & PRIORITY
 1) Hardcoded values (defined within the script body)
 2) System commands (DISM, chkdsk, sfc)
 3) Error

 REQUIRED INPUTS
 - RunDismScan       : $true
   (Whether to run DISM ScanHealth to check for image corruption.)
 - RunDismRestore    : $true
   (Whether to run DISM RestoreHealth to repair image corruption.)
 - RunChkdsk         : $false
   (Whether to run chkdsk on local drives. Requires reboot to complete.)
 - RunSfc            : $true
   (Whether to run System File Checker to verify and repair system files.)
 - RunDismCleanup    : $true
   (Whether to run DISM component cleanup to remove superseded components.)
 - ChkdskParameters  : '/scan'
   (Parameters for chkdsk. Use '/scan' for quick scan or '/f /r' for full check.)
 - RebootAfterMaintenance : $false
   (Whether to reboot the system after maintenance with a 5-minute warning.)

 SETTINGS
 - All maintenance operations are optional via hardcoded input flags.
 - DISM operations use online mode against the running Windows installation.
 - chkdsk runs against all fixed local drives (DriveType = 3).
 - Commands run synchronously with full output captured for logging.

 BEHAVIOR
 - Script runs each enabled maintenance operation in sequence.
 - Each operation's success or failure is tracked individually.
 - DISM log file is checked for access denied errors.
 - chkdsk requires admin rights and may schedule operations on next reboot.
 - Failed operations are reported but script continues to next operation.

 PREREQUISITES
 - PowerShell 5.1 or later.
 - Administrator privileges required.
 - Windows 8.1/Server 2012 R2 or later for DISM commands.
 - Sufficient disk space for repair operations.

 SECURITY NOTES
 - No secrets are printed to the console.
 - Requires elevated permissions to modify system components.
 - Operations may cause system modifications and require reboots.

 ENDPOINTS
 - N/A (local system commands only)

 EXIT CODES
 - 0 success (all enabled operations completed)
 - 1 failure (one or more operations failed)

 EXAMPLE RUN

 [ INPUT VALIDATION ]
 --------------------------------------------------------------
 RunDismScan      : True
 RunDismRestore   : True
 RunChkdsk        : False
 RunSfc           : True
 RunDismCleanup   : True
 ChkdskParameters : /scan
 RebootAfterMaintenance : False

 [ DISM SCAN HEALTH ]
 --------------------------------------------------------------
 Starting DISM image scan...
 Operation completed successfully
 Result : Success

 [ DISM RESTORE HEALTH ]
 --------------------------------------------------------------
 Starting DISM image repair...
 Operation completed successfully
 Result : Success

 [ SYSTEM FILE CHECK ]
 --------------------------------------------------------------
 Starting system file verification...
 Windows Resource Protection found corrupt files and repaired them
 Result : Success

 [ FINAL STATUS ]
 --------------------------------------------------------------
 Operations Run    : 3
 Operations Passed : 3
 Operations Failed : 0
 Overall Result    : Success

 [ SCRIPT COMPLETED ]
 --------------------------------------------------------------

 # Example with RebootAfterMaintenance set to True

 [ INPUT VALIDATION ]
 --------------------------------------------------------------
 RunDismScan      : True
 RunDismRestore   : True
 RunChkdsk        : False
 RunSfc           : True
 RunDismCleanup   : True
 ChkdskParameters : /scan
 RebootAfterMaintenance : True

 [ DISM SCAN HEALTH ]
 --------------------------------------------------------------
 Starting DISM image scan...
 Operation completed successfully
 Result : Success

 [ DISM RESTORE HEALTH ]
 --------------------------------------------------------------
 Starting DISM image repair...
 Operation completed successfully
 Result : Success

 [ SYSTEM FILE CHECK ]
 --------------------------------------------------------------
 Starting system file verification...
 Windows Resource Protection found corrupt files and repaired them
 Result : Success

 [ FINAL STATUS ]
 --------------------------------------------------------------
 Operations Run    : 3
 Operations Passed : 3
 Operations Failed : 0
 Overall Result    : Success

 [ SCRIPT COMPLETED ]
 --------------------------------------------------------------

 [ REBOOT SCHEDULE ]
 --------------------------------------------------------------
 Scheduling system reboot in 5 minutes...
 Please save any open work.
 Reboot command issued.
--------------------------------------------------------------------------------
 CHANGELOG
--------------------------------------------------------------------------------
 2024-12-28 v1.2.0 Use exit codes instead of string parsing for DISM/SFC result detection
 2024-12-23 v1.1.0 Updated to Limehawk Script Framework
 2025-10-31 v1.0.3 Added full command output display for all operations (DISM and SFC)
 2025-10-31 v1.0.2 Fixed DISM component cleanup access denied errors
 2025-10-31 v1.0.1 Added optional reboot functionality with 5-minute warning
 2025-10-31 v1.0.0 Initial release
================================================================================
#>

Set-StrictMode -Version Latest

# ==== STATE (NO ARRAYS/LISTS) ====
$errorOccurred = $false
$errorText     = ""
$operationsRun = 0
$operationsPassed = 0
$operationsFailed = 0

# ==== HARDCODED INPUTS (MANDATORY) ====
# --- Operation Run Flags ---
$RunDismScan      = $true  # Whether to run DISM ScanHealth to check for image corruption.
$RunDismRestore   = $true  # Whether to run DISM RestoreHealth to repair image corruption.
$RunChkdsk        = $false # Whether to run chkdsk on local drives. Requires reboot to complete.
$RunSfc           = $true  # Whether to run System File Checker to verify and repair system files.
$RunDismCleanup   = $true  # Whether to run DISM component cleanup to remove superseded components.

# --- Operation Parameters ---
$ChkdskParameters = '/scan'  # Parameters for chkdsk. Use '/scan' for quick scan or '/f /r' for full check.

# --- Post-Operation Actions ---
$RebootAfterMaintenance = $false # Set to $true to reboot the system after maintenance with a 5-minute warning.

# ==== VALIDATION ====
if ($RunDismScan -isnot [bool]) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- RunDismScan must be a boolean value."
}
if ($RunDismRestore -isnot [bool]) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- RunDismRestore must be a boolean value."
}
if ($RunChkdsk -isnot [bool]) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- RunChkdsk must be a boolean value."
}
if ($RunSfc -isnot [bool]) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- RunSfc must be a boolean value."
}
if ($RunDismCleanup -isnot [bool]) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- RunDismCleanup must be a boolean value."
}
if ([string]::IsNullOrWhiteSpace($ChkdskParameters)) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- ChkdskParameters cannot be empty."
}
if ($RebootAfterMaintenance -isnot [bool]) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- RebootAfterMaintenance must be a boolean value."
}

if ($errorOccurred) {
    Write-Host ""
    Write-Host "[ ERROR OCCURRED ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host "Input validation failed:"
    Write-Host $errorText

    Write-Host ""
    Write-Host "[ RESULT ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host "Status : Failure"

    Write-Host ""
    Write-Host "[ FINAL STATUS ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host "Script cannot proceed due to invalid hardcoded inputs."

    Write-Host ""
    Write-Host "[ SCRIPT COMPLETED ]"
    Write-Host "--------------------------------------------------------------"
    exit 1
}

# ==== RUNTIME OUTPUT (Style A) ====
Write-Host ""
Write-Host "[ INPUT VALIDATION ]"
Write-Host "--------------------------------------------------------------"
Write-Host "RunDismScan      : $RunDismScan"
Write-Host "RunDismRestore   : $RunDismRestore"
Write-Host "RunChkdsk        : $RunChkdsk"
Write-Host "RunSfc           : $RunSfc"
Write-Host "RunDismCleanup   : $RunDismCleanup"
Write-Host "ChkdskParameters : $ChkdskParameters"

# ==== DISM SCAN HEALTH ====
if ($RunDismScan) {
    Write-Host ""
    Write-Host "[ DISM SCAN HEALTH ]"
    Write-Host "--------------------------------------------------------------"

    $operationsRun++
    $opSuccess = $false

    try {
        Write-Host "Starting DISM image scan..."
        Write-Host ""
        $dismScanResult = & DISM.exe /Online /Cleanup-Image /ScanHealth 2>&1
        $dismScanExitCode = $LASTEXITCODE
        $dismScanOutput = $dismScanResult -join "`n"

        # Display the actual output
        Write-Host $dismScanOutput
        Write-Host ""

        # Check exit code as primary indicator (DISM: 0 = success)
        if ($dismScanExitCode -eq 0) {
            Write-Host "Result : Success"
            $operationsPassed++
            $opSuccess = $true
        }
        elseif ($dismScanOutput -match "Error: 5|Access is denied") {
            Write-Host "Result : Failed - Access Denied"
            $operationsFailed++
        }
        else {
            Write-Host "Result : Failed (exit code: $dismScanExitCode)"
            $operationsFailed++
        }

    } catch {
        Write-Host "Exception occurred during DISM scan"
        Write-Host "Error : $($_.Exception.Message)"
        Write-Host "Result : Failed"
        $operationsFailed++
    }
}

# ==== DISM RESTORE HEALTH ====
if ($RunDismRestore) {
    Write-Host ""
    Write-Host "[ DISM RESTORE HEALTH ]"
    Write-Host "--------------------------------------------------------------"

    $operationsRun++
    $opSuccess = $false

    try {
        Write-Host "Starting DISM image repair..."
        Write-Host ""
        $dismRestoreResult = & DISM.exe /Online /Cleanup-Image /RestoreHealth 2>&1
        $dismRestoreExitCode = $LASTEXITCODE
        $dismRestoreOutput = $dismRestoreResult -join "`n"

        # Display the actual output
        Write-Host $dismRestoreOutput
        Write-Host ""

        # Check exit code as primary indicator (DISM: 0 = success)
        if ($dismRestoreExitCode -eq 0) {
            Write-Host "Result : Success"
            $operationsPassed++
            $opSuccess = $true
        }
        elseif ($dismRestoreOutput -match "Error: 5|Access is denied") {
            Write-Host "Result : Failed - Access Denied"
            $operationsFailed++
        }
        else {
            Write-Host "Result : Failed (exit code: $dismRestoreExitCode)"
            $operationsFailed++
        }

    } catch {
        Write-Host "Exception occurred during DISM restore"
        Write-Host "Error : $($_.Exception.Message)"
        Write-Host "Result : Failed"
        $operationsFailed++
    }
}

# ==== DISK CHECK ====
if ($RunChkdsk) {
    Write-Host ""
    Write-Host "[ DISK CHECK ]"
    Write-Host "--------------------------------------------------------------"

    try {
        $drives = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType = 3" -ErrorAction Stop

        if ($drives) {
            foreach ($drive in $drives) {
                $driveLetter = $drive.DeviceID
                $operationsRun++

                try {
                    Write-Host "Checking drive $driveLetter with parameters: $ChkdskParameters"

                    # Note: chkdsk may schedule operation for next reboot on system drive
                    $chkdskCmd = "chkdsk.exe $driveLetter $ChkdskParameters"
                    $chkdskResult = & cmd.exe /c "echo y | chkdsk $driveLetter $ChkdskParameters" 2>&1

                    if ($LASTEXITCODE -eq 0 -or $chkdskResult -match "scheduled|will check") {
                        Write-Host "Drive $driveLetter check completed or scheduled"
                        Write-Host "Result : Success"
                        $operationsPassed++
                    } else {
                        Write-Host "Drive $driveLetter check encountered issues"
                        Write-Host "Result : Check output above"
                        $operationsFailed++
                    }

                } catch {
                    Write-Host "Error checking drive $driveLetter"
                    Write-Host "Error : $($_.Exception.Message)"
                    Write-Host "Result : Failed"
                    $operationsFailed++
                }
            }
        } else {
            Write-Host "No fixed drives found to check"
        }

    } catch {
        Write-Host "Failed to enumerate drives"
        Write-Host "Error : $($_.Exception.Message)"
    }
}

# ==== SYSTEM FILE CHECK ====
if ($RunSfc) {
    Write-Host ""
    Write-Host "[ SYSTEM FILE CHECK ]"
    Write-Host "--------------------------------------------------------------"

    $operationsRun++
    $opSuccess = $false

    try {
        Write-Host "Starting system file verification..."
        Write-Host ""
        $sfcResult = & sfc.exe /scannow 2>&1
        $sfcExitCode = $LASTEXITCODE
        $sfcOutput = $sfcResult -join "`n"

        # Display the actual output
        Write-Host $sfcOutput
        Write-Host ""

        # Check exit code as primary indicator (more reliable than string parsing)
        # SFC exit codes: 0 = no issues, 1 = repaired, 2 = couldn't repair some
        if ($sfcExitCode -eq 0) {
            Write-Host "Result : Success (no integrity violations)"
            $operationsPassed++
            $opSuccess = $true
        }
        elseif ($sfcExitCode -eq 1) {
            Write-Host "Result : Success (corrupt files were repaired)"
            $operationsPassed++
            $opSuccess = $true
        }
        elseif ($sfcExitCode -eq 2) {
            Write-Host "Result : Manual intervention required (some files could not be repaired)"
            $operationsFailed++
        }
        else {
            Write-Host "Result : Failed (exit code: $sfcExitCode)"
            $operationsFailed++
        }

    } catch {
        Write-Host "Exception occurred during system file check"
        Write-Host "Error : $($_.Exception.Message)"
        Write-Host "Result : Failed"
        $operationsFailed++
    }
}

# ==== COMPONENT CLEANUP ====
if ($RunDismCleanup) {
    Write-Host ""
    Write-Host "[ COMPONENT CLEANUP ]"
    Write-Host "--------------------------------------------------------------"

    $operationsRun++
    $opSuccess = $false
    $wuServiceWasStopped = $false

    try {
        # Stop Windows Update service to release component store locks
        Write-Host "Checking Windows Update service status..."
        $wuService = Get-Service -Name wuauserv -ErrorAction SilentlyContinue

        if ($wuService -and $wuService.Status -eq 'Running') {
            Write-Host "Stopping Windows Update service..."
            Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
            $wuServiceWasStopped = $true
            Write-Host "Windows Update service stopped"
        } else {
            Write-Host "Windows Update service is not running"
        }

        # Retry logic for component cleanup
        $maxRetries = 2
        $retryCount = 0
        $cleanupSuccess = $false

        while ($retryCount -le $maxRetries -and -not $cleanupSuccess) {
            if ($retryCount -gt 0) {
                Write-Host "Retry attempt $retryCount of $maxRetries..."
                Start-Sleep -Seconds 3
            }

            Write-Host "Starting component cleanup..."
            Write-Host ""
            $dismCleanupResult = & DISM.exe /Online /Cleanup-Image /StartComponentCleanup 2>&1
            $dismCleanupExitCode = $LASTEXITCODE
            $dismCleanupOutput = $dismCleanupResult -join "`n"

            # Display the actual output
            Write-Host $dismCleanupOutput
            Write-Host ""

            # Check exit code as primary indicator (DISM: 0 = success)
            if ($dismCleanupExitCode -eq 0) {
                Write-Host "Result : Success"
                $operationsPassed++
                $opSuccess = $true
                $cleanupSuccess = $true
            }
            elseif ($dismCleanupOutput -match "Error: 5|Access is denied") {
                Write-Host "Access denied error detected on attempt $($retryCount + 1)"
                $retryCount++
            }
            else {
                Write-Host "Failed on attempt $($retryCount + 1) (exit code: $dismCleanupExitCode)"
                $retryCount++
            }
        }

        # If all retries failed, show diagnostic info
        if (-not $cleanupSuccess) {
            Write-Host "Component cleanup failed after $($retryCount) attempts"

            # Check for active Windows Update operations
            $wuProcess = Get-Process -Name TiWorker -ErrorAction SilentlyContinue
            if ($wuProcess) {
                Write-Host "Note: TrustedInstaller (TiWorker.exe) is running - Windows Update may be active"
            }

            Write-Host "Result : Failed - Unable to complete cleanup"
            $operationsFailed++
        }

    } catch {
        Write-Host "Exception occurred during component cleanup"
        Write-Host "Error : $($_.Exception.Message)"
        Write-Host "Result : Failed"
        $operationsFailed++
    }
    finally {
        # Always restart Windows Update service if we stopped it
        if ($wuServiceWasStopped) {
            Write-Host "Restarting Windows Update service..."
            Start-Service -Name wuauserv -ErrorAction SilentlyContinue
            Write-Host "Windows Update service restarted"
        }
    }
}

# ==== FINAL STATUS ====
Write-Host ""
Write-Host "[ FINAL STATUS ]"
Write-Host "--------------------------------------------------------------"
Write-Host "Operations Run    : $operationsRun"
Write-Host "Operations Passed : $operationsPassed"
Write-Host "Operations Failed : $operationsFailed"

if ($operationsFailed -eq 0) {
    Write-Host "Overall Result    : Success"
} else {
    Write-Host "Overall Result    : Some operations failed"
}

Write-Host ""
Write-Host "[ SCRIPT COMPLETED ]"
Write-Host "--------------------------------------------------------------"

if ($operationsFailed -gt 0) {
    exit 1
} else {
    # Schedule reboot if enabled
    if ($RebootAfterMaintenance) {
        Write-Host ""
        Write-Host "[ REBOOT SCHEDULE ]"
        Write-Host "--------------------------------------------------------------"
        Write-Host "Scheduling system reboot in 5 minutes..."
        Write-Host "Please save any open work."
        & shutdown.exe /r /t 300 /c "Windows system maintenance is complete. Your computer will reboot in 5 minutes. Please save your work."
        Write-Host "Reboot command issued."
        exit 0 # Exit immediately after scheduling reboot
    } else {
        exit 0
    }
}
