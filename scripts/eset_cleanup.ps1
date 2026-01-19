<#
██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝

================================================================================
 SCRIPT    : ESET Antivirus Complete Cleanup 1.1.2
 AUTHOR    : Limehawk.io
 DATE      : January 2026
 USAGE     : .\eset_cleanup.ps1
 FILE      : eset_cleanup.ps1
 DESCRIPTION : Completely removes ESET antivirus remnants from Windows systems
================================================================================
 README
--------------------------------------------------------------------------------

PURPOSE

Performs a complete cleanup of ESET antivirus software from Windows systems.
This script removes services, processes, files, registry entries, and scheduled
tasks left behind after ESET uninstallation. Useful when standard uninstall
fails or leaves remnants that interfere with new AV deployment.

DATA SOURCES & PRIORITY

1. Windows Services - Detect and remove ESET services
2. Running Processes - Kill active ESET processes
3. File System - Remove ESET installation directories
4. Registry - Remove ESET configuration keys
5. Task Scheduler - Remove ESET scheduled tasks

REQUIRED INPUTS

No inputs required. All cleanup targets are predefined based on standard ESET
installation paths and patterns.

SETTINGS

- Service removal: All services matching *ESET* pattern
- Process termination: egui.exe and ekrn.exe (main ESET processes)
- Folder removal: Program Files, ProgramData, AppData (user and local)
- Registry cleanup: HKLM and HKCU software keys
- Task removal: All scheduled tasks matching *ESET* pattern

BEHAVIOR

1. Validates Administrator privileges (required for cleanup)
2. Stops and removes all ESET services
3. Terminates active ESET processes
4. Removes ESET installation folders
5. Removes ESET registry keys
6. Removes ESET scheduled tasks
7. Reports comprehensive cleanup status

PREREQUISITES

- Windows PowerShell 5.1 or PowerShell 7+
- Administrator privileges (required)
- No modules required

SECURITY NOTES

- No secrets logged or displayed
- Requires elevation (will fail if not admin)
- Forcefully terminates processes (may lose unsaved ESET settings)
- Registry modifications are permanent
- Backup important data before running

ENDPOINTS

- None (local system operations only)

EXIT CODES

- 0: Success - ESET cleanup completed
- 1: Failure - Error during cleanup or insufficient privileges

EXAMPLE RUN

PS> .\eset_cleanup.ps1

[INFO] SETUP
==============================================================
Script started : 2025-11-02 09:15:42
Administrator  : Yes

[RUN] SERVICE CLEANUP
==============================================================
Scanning for ESET services...
Services found : 3
Stopping ekrn...
Deleting ekrn...
Stopping ESET Service...
Deleting ESET Service...
Services removed : 3

[RUN] PROCESS CLEANUP
==============================================================
Scanning for ESET processes...
Processes found : 2
Terminating egui.exe...
Terminating ekrn.exe...
Processes terminated : 2

[RUN] FOLDER CLEANUP
==============================================================
Removing ESET directories...
Removed : C:\Program Files\ESET
Removed : C:\ProgramData\ESET
Skipped : C:\Users\Admin\AppData\Roaming\ESET (not found)
Folders removed : 2 of 4

[RUN] REGISTRY CLEANUP
==============================================================
Removing ESET registry keys...
Removed : HKLM:\SOFTWARE\ESET
Removed : HKLM:\SOFTWARE\Wow6432Node\ESET
Skipped : HKCU:\SOFTWARE\ESET (not found)
Registry keys removed : 2 of 3

[RUN] SCHEDULED TASK CLEANUP
==============================================================
Removing ESET scheduled tasks...
Tasks found : 1
Deleted : ESET NOD32 Update
Tasks removed : 1

[INFO] FINAL STATUS
==============================================================
Services removed         : 3
Processes terminated     : 2
Folders removed          : 2
Registry keys removed    : 2
Scheduled tasks removed  : 1
Cleanup status           : Complete

[OK] SCRIPT COMPLETED
==============================================================
Script completed successfully
Exit code : 0
--------------------------------------------------------------------------------
 CHANGELOG
--------------------------------------------------------------------------------
 2026-01-19 v1.1.2 Fixed EXAMPLE RUN section formatting
 2026-01-19 v1.1.1 Updated to two-line ASCII console output style
 2025-12-23 v1.1.0 Updated to Limehawk Script Framework
 2025-11-02 v1.0.0 Initial migration from SuperOps
#>

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# ============================================================================
# HARDCODED INPUTS
# ============================================================================

# ESET installation folders to remove
$foldersToRemove = @(
    "C:\Program Files\ESET",
    "C:\ProgramData\ESET",
    "$env:AppData\ESET",
    "$env:LocalAppData\ESET"
)

# ESET registry paths to remove
$registryPaths = @(
    "HKLM:\SOFTWARE\ESET",
    "HKLM:\SOFTWARE\Wow6432Node\ESET",
    "HKCU:\SOFTWARE\ESET"
)

# ============================================================================
# SETUP
# ============================================================================

Write-Host ""
Write-Host "[INFO] SETUP"
Write-Host "=============================================================="

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host ""
    Write-Host "[ERROR] PRIVILEGE CHECK FAILED"
    Write-Host "=============================================================="
    Write-Host "This script requires Administrator privileges"
    Write-Host ""
    Write-Host "Troubleshooting:"
    Write-Host "- Right-click PowerShell and select 'Run as Administrator'"
    Write-Host "- Or run from RMM platform with SYSTEM privileges"
    Write-Host ""
    exit 1
}

Write-Host "Script started : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "Administrator  : Yes"

# ============================================================================
# SERVICE CLEANUP
# ============================================================================

Write-Host ""
Write-Host "[RUN] SERVICE CLEANUP"
Write-Host "=============================================================="
Write-Host "Scanning for ESET services..."

$servicesRemoved = 0
$esetServices = Get-Service | Where-Object { $_.Name -like "*ESET*" }

if ($esetServices) {
    Write-Host "Services found : $($esetServices.Count)"

    foreach ($service in $esetServices) {
        try {
            Write-Host "Stopping $($service.Name)..."
            Stop-Service -Name $service.Name -Force -ErrorAction SilentlyContinue

            Write-Host "Deleting $($service.Name)..."
            & sc.exe delete $service.Name | Out-Null
            $servicesRemoved++
        } catch {
            Write-Host "Warning: Could not remove service $($service.Name)"
        }
    }

    Write-Host "Services removed : $servicesRemoved"
} else {
    Write-Host "Services found : 0"
}

# ============================================================================
# PROCESS CLEANUP
# ============================================================================

Write-Host ""
Write-Host "[RUN] PROCESS CLEANUP"
Write-Host "=============================================================="
Write-Host "Scanning for ESET processes..."

$processesKilled = 0
$esetProcesses = Get-Process | Where-Object {
    $_.ProcessName -like "*egui*" -or $_.ProcessName -like "*ekrn*"
}

if ($esetProcesses) {
    Write-Host "Processes found : $($esetProcesses.Count)"

    foreach ($process in $esetProcesses) {
        try {
            Write-Host "Terminating $($process.ProcessName).exe..."
            Stop-Process -Id $process.Id -Force -ErrorAction Stop
            $processesKilled++
        } catch {
            Write-Host "Warning: Could not terminate process $($process.ProcessName)"
        }
    }

    Write-Host "Processes terminated : $processesKilled"
} else {
    Write-Host "Processes found : 0"
}

# ============================================================================
# FOLDER CLEANUP
# ============================================================================

Write-Host ""
Write-Host "[RUN] FOLDER CLEANUP"
Write-Host "=============================================================="
Write-Host "Removing ESET directories..."

$foldersRemoved = 0

foreach ($folder in $foldersToRemove) {
    if (Test-Path $folder) {
        try {
            Remove-Item -Path $folder -Recurse -Force -ErrorAction Stop
            Write-Host "Removed : $folder"
            $foldersRemoved++
        } catch {
            Write-Host "Warning : Could not remove $folder"
        }
    } else {
        Write-Host "Skipped : $folder (not found)"
    }
}

Write-Host "Folders removed : $foldersRemoved of $($foldersToRemove.Count)"

# ============================================================================
# REGISTRY CLEANUP
# ============================================================================

Write-Host ""
Write-Host "[RUN] REGISTRY CLEANUP"
Write-Host "=============================================================="
Write-Host "Removing ESET registry keys..."

$registryKeysRemoved = 0

foreach ($regPath in $registryPaths) {
    if (Test-Path $regPath) {
        try {
            Remove-Item -Path $regPath -Recurse -Force -ErrorAction Stop
            Write-Host "Removed : $regPath"
            $registryKeysRemoved++
        } catch {
            Write-Host "Warning : Could not remove $regPath"
        }
    } else {
        Write-Host "Skipped : $regPath (not found)"
    }
}

Write-Host "Registry keys removed : $registryKeysRemoved of $($registryPaths.Count)"

# ============================================================================
# SCHEDULED TASK CLEANUP
# ============================================================================

Write-Host ""
Write-Host "[RUN] SCHEDULED TASK CLEANUP"
Write-Host "=============================================================="
Write-Host "Removing ESET scheduled tasks..."

$tasksRemoved = 0

try {
    # Get ESET tasks using PowerShell cmdlet
    $esetTasks = Get-ScheduledTask | Where-Object { $_.TaskName -like "*ESET*" } -ErrorAction SilentlyContinue

    if ($esetTasks) {
        Write-Host "Tasks found : $($esetTasks.Count)"

        foreach ($task in $esetTasks) {
            try {
                Unregister-ScheduledTask -TaskName $task.TaskName -Confirm:$false -ErrorAction Stop
                Write-Host "Deleted : $($task.TaskName)"
                $tasksRemoved++
            } catch {
                Write-Host "Warning : Could not delete task $($task.TaskName)"
            }
        }

        Write-Host "Tasks removed : $tasksRemoved"
    } else {
        Write-Host "Tasks found : 0"
    }
} catch {
    Write-Host "Warning : Could not enumerate scheduled tasks"
}

# ============================================================================
# FINAL STATUS
# ============================================================================

Write-Host ""
Write-Host "[INFO] FINAL STATUS"
Write-Host "=============================================================="
Write-Host "Services removed         : $servicesRemoved"
Write-Host "Processes terminated     : $processesKilled"
Write-Host "Folders removed          : $foldersRemoved"
Write-Host "Registry keys removed    : $registryKeysRemoved"
Write-Host "Scheduled tasks removed  : $tasksRemoved"

$totalItemsRemoved = $servicesRemoved + $processesKilled + $foldersRemoved + $registryKeysRemoved + $tasksRemoved

if ($totalItemsRemoved -gt 0) {
    Write-Host "Cleanup status           : Complete ($totalItemsRemoved items removed)"
} else {
    Write-Host "Cleanup status           : No ESET components found"
}

Write-Host ""
Write-Host "Note: A system reboot is recommended to complete cleanup"

# ============================================================================
# SCRIPT COMPLETED
# ============================================================================

Write-Host ""
Write-Host "[OK] SCRIPT COMPLETED"
Write-Host "=============================================================="
Write-Host "Script completed successfully"
Write-Host "Exit code : 0"
Write-Host ""

exit 0
