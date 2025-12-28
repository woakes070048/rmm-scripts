$ErrorActionPreference = 'Stop'

<#
â–ˆâ–ˆâ•—     â–ˆâ–ˆâ•—â–ˆâ–ˆâ–ˆâ•—   â–ˆâ–ˆâ–ˆâ•—â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•—â–ˆâ–ˆâ•—  â–ˆâ–ˆâ•— â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•— â–ˆâ–ˆâ•—    â–ˆâ–ˆâ•—â–ˆâ–ˆâ•—  â–ˆâ–ˆâ•—
â–ˆâ–ˆâ•‘     â–ˆâ–ˆâ•‘â–ˆâ–ˆâ–ˆâ–ˆâ•— â–ˆâ–ˆâ–ˆâ–ˆâ•‘â–ˆâ–ˆâ•”â•â•â•â•â•â–ˆâ–ˆâ•‘  â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•”â•â•â–ˆâ–ˆâ•—â–ˆâ–ˆâ•‘    â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•‘ â–ˆâ–ˆâ•”â•
â–ˆâ–ˆâ•‘     â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•”â–ˆâ–ˆâ–ˆâ–ˆâ•”â–ˆâ–ˆâ•‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•—  â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•‘â–ˆâ–ˆâ•‘ â–ˆâ•— â–ˆâ–ˆâ•‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•”â•
â–ˆâ–ˆâ•‘     â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•‘â•šâ–ˆâ–ˆâ•”â•â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•”â•â•â•  â–ˆâ–ˆâ•”â•â•â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•”â•â•â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•‘â–ˆâ–ˆâ–ˆâ•—â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•”â•â–ˆâ–ˆâ•—
â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•—â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•‘ â•šâ•â• â–ˆâ–ˆâ•‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•—â–ˆâ–ˆâ•‘  â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•‘  â–ˆâ–ˆâ•‘â•šâ–ˆâ–ˆâ–ˆâ•”â–ˆâ–ˆâ–ˆâ•”â•â–ˆâ–ˆâ•‘  â–ˆâ–ˆâ•—
â•šâ•â•â•â•â•â•â•â•šâ•â•â•šâ•â•     â•šâ•â•â•šâ•â•â•â•â•â•â•â•šâ•â•  â•šâ•â•â•šâ•â•  â•šâ•â• â•šâ•â•â•â•šâ•â•â• â•šâ•â•  â•šâ•â•
================================================================================
 SCRIPT   : Disk Cleanup                                                 v1.1.1
 AUTHOR   : Limehawk.io
 DATE      : December 2025
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

 DATA SOURCES & PRIORITY

 1) Hardcoded values (CleanupProfile defined within the script body)
 2) System query (WMI to enumerate fixed drives)

 REQUIRED INPUTS

 - CleanupProfile : 'verylow' (hardcoded) - Determines cleanup aggressiveness.

 SETTINGS

 - DriveType filter: 3 (fixed local disks only)
 - Cleanups run sequentially to avoid conflicts
 - DISM targets system-wide (C: only)

 BEHAVIOR

 1. Checks/elevates to admin
 2. Queries WMI for fixed drives
 3. Runs cleanmgr.exe per drive with /verylowdisk flag
 4. Performs targeted cleanups on C: (SoftwareDistribution, WinSxS, Search Index)
 5. Reports progress/completion

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

 [ INPUT VALIDATION ]
 --------------------------------------------------------------
 Cleanup Profile : verylow
 Running as Admin : True

 [ OPERATION ]
 --------------------------------------------------------------
 Querying fixed local drives...
 Found 2 drive(s) : C:, D:
 Running cleanup for drive C: (cleanmgr)
 Running cleanup for drive D: (cleanmgr)
 Running SoftwareDistribution cleanup...
 Running WinSxS cleanup via DISM...
 Rebuilding Search Index...

 [ RESULT ]
 --------------------------------------------------------------
 Status : Success
 Drives Processed : 2
 Targeted Cleanups : 3/3

 [ FINAL STATUS ]
 --------------------------------------------------------------
 Disk cleanup completed successfully. Reboot recommended for full effect.

 [ SCRIPT COMPLETED ]
 --------------------------------------------------------------
--------------------------------------------------------------------------------
 CHANGELOG
--------------------------------------------------------------------------------
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

# ==== HARDCODED INPUTS ====
$CleanupProfile = 'verylow'

# ==== ADMIN CHECK ====
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host ""
    Write-Host "[ ERROR OCCURRED ]"
    Write-Host "--------------------------------------------------------------"
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
    Write-Host "[ ERROR OCCURRED ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host $errorText
    exit 1
}

# ==== RUNTIME OUTPUT ====
Write-Host ""
Write-Host "[ INPUT VALIDATION ]"
Write-Host "--------------------------------------------------------------"
Write-Host "Cleanup Profile  : $CleanupProfile"
Write-Host "Running as Admin : $isAdmin"

Write-Host ""
Write-Host "[ OPERATION ]"
Write-Host "--------------------------------------------------------------"

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
    Write-Host "[ ERROR OCCURRED ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host $errorText
    exit 1
}

# Run cleanmgr for each drive
foreach ($drive in $drives) {
    $driveLetter = $drive.DeviceID
    Write-Host "Running cleanup for drive $driveLetter (cleanmgr)..."

    try {
        Start-Process -FilePath "cleanmgr.exe" -ArgumentList "/verylowdisk", "/d", $driveLetter -Wait -NoNewWindow -ErrorAction Stop
        $processedCount++
    } catch {
        Write-Host "Warning: cleanmgr failed for $driveLetter : $($_.Exception.Message)"
    }
}

# Targeted cleanups (C: only)
if ($drives | Where-Object { $_.DeviceID -eq 'C:' }) {
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
        Write-Host "  Warning: $($_.Exception.Message)"
    }

    # 2. WinSxS via DISM
    Write-Host "Running WinSxS cleanup via DISM..."
    try {
        $dismProcess = Start-Process -FilePath "Dism.exe" -ArgumentList "/Online", "/Cleanup-Image", "/StartComponentCleanup" -Wait -NoNewWindow -PassThru -ErrorAction Stop
        if ($dismProcess.ExitCode -eq 0) {
            $targetedCleanups++
            Write-Host "  Completed (superseded components removed)"
        } else {
            Write-Host "  Warning: DISM exited with code $($dismProcess.ExitCode)"
        }
    } catch {
        Write-Host "  Warning: $($_.Exception.Message)"
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
        Write-Host "  Warning: $($_.Exception.Message)"
    }
} else {
    Write-Host "Warning: C: drive not found; skipping targeted cleanups."
}

Write-Host ""
Write-Host "[ RESULT ]"
Write-Host "--------------------------------------------------------------"
$overallStatus = if ($processedCount -eq $driveCount -and $targetedCleanups -eq $totalTargeted) { "Success" } else { "Partial Success" }
Write-Host "Status            : $overallStatus"
Write-Host "Drives Processed  : $processedCount of $driveCount"
Write-Host "Targeted Cleanups : $targetedCleanups of $totalTargeted"

Write-Host ""
Write-Host "[ FINAL STATUS ]"
Write-Host "--------------------------------------------------------------"
if ($overallStatus -eq "Success") {
    Write-Host "Disk cleanup completed successfully for all drives and targets."
    Write-Host "Reboot recommended to finalize changes."
} else {
    Write-Host "Disk cleanup completed with warnings. Check output above."
}

Write-Host ""
Write-Host "[ SCRIPT COMPLETED ]"
Write-Host "--------------------------------------------------------------"
exit 0
