$ErrorActionPreference = 'Stop'

<#
██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
================================================================================
 SCRIPT   : Disk Cleanup                                                 v1.2.1
 AUTHOR   : Limehawk.io
 DATE     : January 2026
 USAGE    : .\disk_cleanup.ps1
================================================================================
 FILE     : disk_cleanup.ps1
 DESCRIPTION : Runs Windows Disk Cleanup plus SoftwareDistribution/WinSxS cleanup
--------------------------------------------------------------------------------
 README
--------------------------------------------------------------------------------
 PURPOSE

 Runs Windows Disk Cleanup utility on all fixed local drives, plus targeted
 cleanups for SoftwareDistribution, WinSxS, and Search Index to free up disk space.
 Shows disk space before/after and progress updates during long-running operations.

 DATA SOURCES & PRIORITY

 1) Hardcoded values (CleanupProfile defined within the script body)
 2) System query (WMI to enumerate fixed drives)

 REQUIRED INPUTS

 - CleanupProfile : 'verylow' (hardcoded) - Determines cleanup aggressiveness.
 - CleanmgrTimeout : 1800 (hardcoded) - Maximum seconds to wait for cleanmgr.
 - StatusInterval : 60 (hardcoded) - Seconds between progress updates.

 SETTINGS

 - DriveType filter: 3 (fixed local disks only)
 - Cleanups run sequentially to avoid conflicts
 - DISM targets system-wide (C: only)
 - Progress updates shown every 60 seconds during cleanmgr

 BEHAVIOR

 1. Checks/elevates to admin
 2. Queries WMI for fixed drives
 3. Shows free space before cleanup
 4. Runs cleanmgr.exe per drive with /verylowdisk flag (with progress updates)
 5. Performs targeted cleanups on C: (SoftwareDistribution, WinSxS, Search Index)
 6. Shows free space after cleanup and total freed

 PREREQUISITES

 - Windows 10/11 with cleanmgr.exe and DISM
 - WMI service running
 - Admin privileges for DISM/services

 SECURITY NOTES

 - No secrets in logs
 - Targeted deletions only (no user files)

 EXIT CODES

 - 0: Success
 - 1: Failure (validation/WMI/admin check)

 EXAMPLE RUN

 [INFO] INPUT VALIDATION
 ==============================================================
 Cleanup Profile   : verylow
 Cleanmgr Timeout  : 1800 seconds
 Status Interval   : 60 seconds
 Running as Admin  : True

 [RUN] DISK CLEANUP
 ==============================================================
 Querying fixed local drives...
 Found 2 drive(s) : C:, D:

 [RUN] CLEANUP DRIVE C:
 ==============================================================
 Free space before : 45.2 GB
 Running cleanmgr /verylowdisk (this may take 10-30 minutes)...
   [still running... 1 min elapsed]
   [still running... 2 min elapsed]
 Free space after  : 52.8 GB
 Freed             : 7.6 GB

 [RUN] TARGETED CLEANUPS
 ==============================================================
 Running SoftwareDistribution cleanup...
   Completed (folder cleared)
 Running WinSxS cleanup via DISM...
   Completed (superseded components removed)
 Rebuilding Search Index...
   Completed (DB deleted; will rebuild automatically)

 [INFO] RESULT
 ==============================================================
 Status            : Success
 Drives Processed  : 2 of 2
 Targeted Cleanups : 3 of 3
 Total Freed       : 8.4 GB

 [OK] FINAL STATUS
 ==============================================================
 Disk cleanup completed successfully. Reboot recommended for full effect.

 [OK] SCRIPT COMPLETED
 ==============================================================
--------------------------------------------------------------------------------
 CHANGELOG
--------------------------------------------------------------------------------
 2026-01-29 v1.2.1 Increased script timeout to 180 minutes in metadata
 2026-01-29 v1.2.0 Added progress updates and disk space reporting during cleanup
 2025-12-23 v1.1.1 Updated to Limehawk Script Framework
 2025-11-29 v1.1.0 Added SoftwareDistribution, DISM WinSxS, Search Index; admin check
 2025-10-28 v1.0.0 Initial implementation
================================================================================
#>

Set-StrictMode -Version Latest

# ==== STATE ====
$errorOccurred = $false
$errorText = ""
$processedCount = 0
$targetedCleanups = 0
$totalTargeted = 3  # SoftwareDist, WinSxS, Search
$totalFreedBytes = 0

# ==== HARDCODED INPUTS ====
$CleanupProfile = 'verylow'
$CleanmgrTimeout = 1800  # 30 minutes max per drive
$StatusInterval = 60     # Show status every 60 seconds

# ==== HELPER FUNCTIONS ====
function Get-FreeSpaceBytes {
    $DriveLetter = $args[0]
    $drive = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$DriveLetter'" -ErrorAction SilentlyContinue
    if ($drive) { return $drive.FreeSpace }
    return 0
}

function Format-Bytes {
    $Bytes = [long]$args[0]
    if ($Bytes -ge 1GB) { return "{0:N1} GB" -f ($Bytes / 1GB) }
    if ($Bytes -ge 1MB) { return "{0:N1} MB" -f ($Bytes / 1MB) }
    if ($Bytes -ge 1KB) { return "{0:N1} KB" -f ($Bytes / 1KB) }
    return "$Bytes bytes"
}

# ==== ADMIN CHECK ====
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host ""
    Write-Host "[ERROR] ERROR OCCURRED"
    Write-Host "=============================================================="
    Write-Host "Script requires admin privileges for DISM and services."
    Write-Host "Please relaunch as Administrator."
    exit 1
}

# ==== VALIDATION ====
if ([string]::IsNullOrWhiteSpace($CleanupProfile)) {
    $errorOccurred = $true
    $errorText += "- CleanupProfile is required."
}

if ($errorOccurred) {
    Write-Host ""
    Write-Host "[ERROR] ERROR OCCURRED"
    Write-Host "=============================================================="
    Write-Host $errorText
    exit 1
}

# ==== RUNTIME OUTPUT ====
Write-Host ""
Write-Host "[INFO] INPUT VALIDATION"
Write-Host "=============================================================="
Write-Host "Cleanup Profile   : $CleanupProfile"
Write-Host "Cleanmgr Timeout  : $CleanmgrTimeout seconds"
Write-Host "Status Interval   : $StatusInterval seconds"
Write-Host "Running as Admin  : $isAdmin"

Write-Host ""
Write-Host "[RUN] DISK CLEANUP"
Write-Host "=============================================================="

# Query fixed local drives
Write-Host "Querying fixed local drives..."
try {
    $drives = Get-CimInstance Win32_LogicalDisk -ErrorAction Stop | Where-Object { $_.DriveType -eq 3 }

    if ($null -eq $drives -or @($drives).Count -eq 0) {
        $errorOccurred = $true
        $errorText += "- No fixed local drives found."
    } else {
        $driveList = ($drives | ForEach-Object { $_.DeviceID }) -join ', '
        $driveCount = @($drives).Count
        Write-Host "Found $driveCount drive(s) : $driveList"
    }
} catch {
    $errorOccurred = $true
    $errorText += "- CIM query failed: $($_.Exception.Message)"
}

if ($errorOccurred) {
    Write-Host ""
    Write-Host "[ERROR] ERROR OCCURRED"
    Write-Host "=============================================================="
    Write-Host $errorText
    exit 1
}

# Run cleanmgr for each drive with progress reporting
foreach ($drive in $drives) {
    $driveLetter = $drive.DeviceID

    Write-Host ""
    Write-Host "[RUN] CLEANUP DRIVE $driveLetter"
    Write-Host "=============================================================="

    # Get free space before
    $freeSpaceBefore = Get-FreeSpaceBytes -DriveLetter $driveLetter
    Write-Host "Free space before : $(Format-Bytes $freeSpaceBefore)"
    Write-Host "Running cleanmgr /verylowdisk (this may take 10-30 minutes)..."

    try {
        # Start cleanmgr as background process
        $cleanmgrProcess = Start-Process -FilePath "cleanmgr.exe" -ArgumentList "/verylowdisk", "/d", $driveLetter -PassThru -WindowStyle Hidden -ErrorAction Stop

        # Poll for completion with status updates
        $elapsed = 0
        while (-not $cleanmgrProcess.HasExited) {
            Start-Sleep -Seconds $StatusInterval
            $elapsed += $StatusInterval
            $elapsedMin = [math]::Floor($elapsed / 60)
            Write-Host "  [still running... $elapsedMin min elapsed]"

            if ($elapsed -ge $CleanmgrTimeout) {
                Write-Host "  [WARN] Timeout reached ($CleanmgrTimeout seconds). Stopping cleanmgr..."
                $cleanmgrProcess | Stop-Process -Force -ErrorAction SilentlyContinue
                break
            }
        }

        # Get free space after
        $freeSpaceAfter = Get-FreeSpaceBytes -DriveLetter $driveLetter
        $freedBytes = $freeSpaceAfter - $freeSpaceBefore
        $totalFreedBytes += $freedBytes

        Write-Host "Free space after  : $(Format-Bytes $freeSpaceAfter)"
        if ($freedBytes -gt 0) {
            Write-Host "Freed             : $(Format-Bytes $freedBytes)"
        } elseif ($freedBytes -lt 0) {
            Write-Host "Note              : Space decreased (files may have been created during cleanup)"
        } else {
            Write-Host "Freed             : 0 bytes (drive was already clean)"
        }

        $processedCount++
    } catch {
        Write-Host "[WARN] cleanmgr failed for $driveLetter : $($_.Exception.Message)"
    }
}

# Targeted cleanups (C: only)
if ($drives | Where-Object { $_.DeviceID -eq 'C:' }) {
    Write-Host ""
    Write-Host "[RUN] TARGETED CLEANUPS"
    Write-Host "=============================================================="

    # 1. SoftwareDistribution
    Write-Host "Running SoftwareDistribution cleanup..."
    try {
        $services = @('wuauserv', 'cryptSvc', 'bits', 'msiserver')
        foreach ($svc in $services) { Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue }
        Remove-Item -Path "C:\Windows\SoftwareDistribution\*" -Recurse -Force -ErrorAction SilentlyContinue
        foreach ($svc in $services) { Start-Service -Name $svc -ErrorAction SilentlyContinue }
        $targetedCleanups++
        Write-Host "  Completed (folder cleared)"
    } catch {
        Write-Host "  [WARN] $($_.Exception.Message)"
    }

    # 2. WinSxS via DISM
    Write-Host "Running WinSxS cleanup via DISM..."
    try {
        $dismProcess = Start-Process -FilePath "Dism.exe" -ArgumentList "/Online", "/Cleanup-Image", "/StartComponentCleanup" -Wait -NoNewWindow -PassThru -ErrorAction Stop
        if ($dismProcess.ExitCode -eq 0) {
            $targetedCleanups++
            Write-Host "  Completed (superseded components removed)"
        } else {
            Write-Host "  [WARN] DISM exited with code $($dismProcess.ExitCode)"
        }
    } catch {
        Write-Host "  [WARN] $($_.Exception.Message)"
    }

    # 3. Search Index Rebuild
    Write-Host "Rebuilding Search Index..."
    try {
        Stop-Service -Name "WSearch" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "C:\ProgramData\Microsoft\Search\Data\Applications\Windows\Windows.edb" -Force -ErrorAction SilentlyContinue
        Start-Service -Name "WSearch" -ErrorAction SilentlyContinue
        $targetedCleanups++
        Write-Host "  Completed (DB deleted; will rebuild automatically)"
    } catch {
        Write-Host "  [WARN] $($_.Exception.Message)"
    }
} else {
    Write-Host ""
    Write-Host "[WARN] C: drive not found; skipping targeted cleanups."
}

Write-Host ""
Write-Host "[INFO] RESULT"
Write-Host "=============================================================="
$overallStatus = if ($processedCount -eq $driveCount -and $targetedCleanups -eq $totalTargeted) { "Success" } else { "Partial Success" }
Write-Host "Status            : $overallStatus"
Write-Host "Drives Processed  : $processedCount of $driveCount"
Write-Host "Targeted Cleanups : $targetedCleanups of $totalTargeted"
Write-Host "Total Freed       : $(Format-Bytes $totalFreedBytes)"

Write-Host ""
if ($overallStatus -eq "Success") {
    Write-Host "[OK] FINAL STATUS"
    Write-Host "=============================================================="
    Write-Host "Disk cleanup completed successfully for all drives and targets."
    Write-Host "Reboot recommended to finalize changes."
} else {
    Write-Host "[WARN] FINAL STATUS"
    Write-Host "=============================================================="
    Write-Host "Disk cleanup completed with warnings. Check output above."
}

Write-Host ""
Write-Host "[OK] SCRIPT COMPLETED"
Write-Host "=============================================================="
exit 0
