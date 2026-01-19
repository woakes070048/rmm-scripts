$ErrorActionPreference = 'Stop'
<#
██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝

================================================================================
SCRIPT  : Google Update Task Trigger v1.0.2
AUTHOR  : Limehawk.io
DATE      : January 2026
USAGE   : .\google_update_trigger.ps1
FILE    : google_update_trigger.ps1
DESCRIPTION : Triggers Google Update scheduled task to check for Chrome updates
================================================================================
README
--------------------------------------------------------------------------------
PURPOSE:
    Triggers the Google Update scheduled task to force an immediate check for
    Chrome and other Google product updates.

REQUIRED INPUTS:
    None

BEHAVIOR:
    1. Searches for scheduled tasks matching "GoogleUpdateTaskMachineUA"
    2. Starts matching tasks
    3. Reports status

PREREQUISITES:
    - Windows 10/11
    - Google Chrome or other Google products installed
    - Administrator privileges

SECURITY NOTES:
    - No secrets in logs
    - Only triggers existing scheduled tasks

EXIT CODES:
    0 = Success
    1 = No matching tasks found or failure

EXAMPLE RUN:
    [RUN] FINDING GOOGLE UPDATE TASKS
    ==============================================================
    Found                : GoogleUpdateTaskMachineUA

    [RUN] TRIGGERING TASKS
    ==============================================================
    GoogleUpdateTaskMachineUA : Started

    [INFO] FINAL STATUS
    ==============================================================
    SCRIPT SUCCEEDED

    [OK] SCRIPT COMPLETED
    ==============================================================

CHANGELOG
--------------------------------------------------------------------------------
2026-01-19 v1.0.2 Updated to two-line ASCII console output style
2025-12-23 v1.0.1 Updated to Limehawk Script Framework
2024-12-01 v1.0.0 Initial release - migrated from SuperOps
================================================================================
#>
Set-StrictMode -Version Latest

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================
function Write-Section {
    param([string]$Title, [string]$Status = "INFO")
    Write-Host ""
    Write-Host ("[$Status] $Title")
    Write-Host "=============================================================="
}

function PrintKV([string]$label, [string]$value) {
    $lbl = $label.PadRight(24)
    Write-Host (" {0} : {1}" -f $lbl, $value)
}

# ============================================================================
# CONFIGURATION
# ============================================================================
$taskNamePart = "GoogleUpdateTaskMachineUA"

# ============================================================================
# MAIN SCRIPT
# ============================================================================
try {
    Write-Section "FINDING GOOGLE UPDATE TASKS" "RUN"

    $tasks = Get-ScheduledTask | Where-Object { $_.TaskName -like "*$taskNamePart*" }

    if (-not $tasks) {
        PrintKV "Status" "No matching tasks found"
        Write-Host ""
        Write-Host " Google Update task not found. Chrome may not be installed"
        Write-Host " or the scheduled task has a different name."
        Write-Section "SCRIPT FAILED" "ERROR"
        exit 1
    }

    foreach ($task in $tasks) {
        PrintKV "Found" $task.TaskName
    }

    Write-Section "TRIGGERING TASKS" "RUN"

    $successCount = 0
    foreach ($task in $tasks) {
        try {
            Start-ScheduledTask -TaskName $task.TaskName -ErrorAction Stop

            # Check task state
            $updatedTask = Get-ScheduledTask | Where-Object { $_.TaskName -eq $task.TaskName }

            if ($updatedTask.State -eq "Running") {
                PrintKV $task.TaskName "Running"
            } else {
                PrintKV $task.TaskName "Started (State: $($updatedTask.State))"
            }
            $successCount++
        } catch {
            PrintKV $task.TaskName "FAILED - $($_.Exception.Message)"
        }
    }

    Write-Section "FINAL STATUS"

    if ($successCount -gt 0) {
        Write-Host " SCRIPT SUCCEEDED"
        Write-Host " Triggered $successCount Google Update task(s)"
    } else {
        Write-Host " SCRIPT FAILED - No tasks were started"
    }

    Write-Section "SCRIPT COMPLETED" "OK"
    exit 0
}
catch {
    Write-Section "ERROR OCCURRED" "ERROR"
    PrintKV "Error Message" $_.Exception.Message
    PrintKV "Error Type" $_.Exception.GetType().FullName
    Write-Section "SCRIPT FAILED" "ERROR"
    exit 1
}
