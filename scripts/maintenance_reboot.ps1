$ErrorActionPreference = 'Stop'

<#
██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
================================================================================
 SCRIPT   : Maintenance Reboot                                            v8.1.0
 AUTHOR   : Limehawk.io
 DATE     : December 2025
 USAGE    : .\maintenance_reboot.ps1
================================================================================
 FILE     : maintenance_reboot.ps1
 DESCRIPTION : System reboot with graceful or force mode for maintenance
--------------------------------------------------------------------------------
 README
--------------------------------------------------------------------------------
 PURPOSE

   Performs system reboot when uptime exceeds threshold or reboot flags are
   detected. Supports two modes:

   GRACEFUL MODE (default) - For servers/workstations with active users
   - Warns users before rebooting (configurable delay)
   - Skips reboot if critical apps running (QuickBooks, SQL, etc.)
   - Apps get chance to save data and close cleanly

   FORCE MODE - For after-hours maintenance windows
   - Immediate forced reboot, no warning
   - Guaranteed to reboot regardless of running apps
   - Use when machine is known to be empty

 DATA SOURCES & PRIORITY
 1) RMM literal text replacement ($maxuptimedays)
 2) Environment variable (MAXUPTIMEDAYS)
 3) Default (7 days)

 REQUIRED INPUTS
 - Graceful Reboot:
   - RMM Name: '$graceful_true_or_false' (literal text placeholder)
   - Values: 'true' or 'false'
   - Default: true (graceful mode)

 - Max Uptime Days:
   - RMM Name: '$maxuptimedays' (literal text placeholder)
   - Env Name: 'MAXUPTIMEDAYS'
   - Constraints: Integer (1 or greater)
   - Default: 7

 SETTINGS (hardcoded in script)
 - $GracefulReboot        : Use graceful mode with warning (default: true)
 - $WarningMinutes        : Minutes of warning before graceful reboot (default: 5)
 - $CheckCriticalApps     : Skip reboot if critical apps running (default: true)
 - $CriticalProcessPatterns : Process names to check (QuickBooks, SQL, etc.)
 - $DefaultMaxUptimeDays  : Default uptime threshold if RMM/env not set (7)
 - $CheckCBSRebootPending : Check Component Based Servicing flag (default: true)
 - $CheckWURebootRequired : Check Windows Update flag (default: true)
 - $CheckPendingFileRename: Check Pending File Rename Operations (default: true)

 BEHAVIOR
 - Retrieves the system's last boot time to calculate current uptime in days
 - Checks Windows registry for reboot-pending flags
 - In graceful mode: checks for critical apps, skips if running
 - In graceful mode: schedules reboot with user warning
 - In force mode: immediate forced reboot
 - If neither uptime nor flags trigger, no action taken

 PREREQUISITES
 - PowerShell 5.1+
 - Must be run with local Administrator rights

 SECURITY NOTES
 - The script does not handle secrets or API keys
 - Graceful mode allows apps to save data before closing
 - Force mode will not prompt users - use for empty machines only

 ENDPOINTS
 - Not applicable. This script performs local actions only.

 EXIT CODES
 - 0 success (reboot initiated, skipped due to critical apps, or not needed)
 - 1 failure (input validation failed or command failed)

 EXAMPLE RUN - Graceful mode with critical app detected
 [ INPUT VALIDATION ]
 --------------------------------------------------------------
 Reboot Mode              : Graceful
 Warning Minutes          : 5
 Check Critical Apps      : Yes
 Max Uptime Days          : 7

 [ CRITICAL APP CHECK ]
 --------------------------------------------------------------
 Checking for critical processes...
 Critical Apps Running    : QBW32
 SKIPPING REBOOT - Critical applications are running

 [ FINAL STATUS ]
 --------------------------------------------------------------
 REBOOT SKIPPED (Critical applications running)

 [ SCRIPT COMPLETED ]
 --------------------------------------------------------------

 EXAMPLE RUN - Force mode reboot triggered
 [ INPUT VALIDATION ]
 --------------------------------------------------------------
 Reboot Mode              : Force
 Max Uptime Days          : 7

 [ REBOOT FLAG CHECK ]
 --------------------------------------------------------------
 CBS RebootPending        : Yes
 WU RebootRequired        : No
 PendingFileRename        : No
 Reboot Flags Detected    : Yes

 [ UPTIME CHECK ]
 --------------------------------------------------------------
 Last Boot Time           : 2025-12-20T03:00:00
 Current Uptime (Days)    : 8
 Threshold (Days)         : 7
 Uptime Exceeded          : Yes

 [ REBOOT ACTION ]
 --------------------------------------------------------------
 Trigger                  : Both: Reboot flags AND uptime exceeded
 Method                   : Force (immediate)
 Result                   : INITIATING REBOOT

 [ FINAL STATUS ]
 --------------------------------------------------------------
 OPERATION COMPLETED SUCCESSFULLY (REBOOT INITIATED)

 [ SCRIPT COMPLETED ]
 --------------------------------------------------------------
--------------------------------------------------------------------------------
 CHANGELOG
--------------------------------------------------------------------------------
 2025-12-28 v8.1.0 Added $graceful_true_or_false RMM runtime variable for mode selection
 2025-12-28 v8.0.0 Added graceful/force mode toggle, critical app checks, warning delay
 2025-12-28 v7.2.4 Removed template placeholder cruft
 2025-12-28 v7.2.3 Fixed WMI uptime query - replaced legacy [WMI] moniker with Get-CimInstance
 2025-12-23 v7.2.2 Updated to Limehawk Script Framework
 2025-12-18 v7.2.1 Renamed from invoke_reboot_on_uptime.ps1 to maintenance_reboot.ps1
 2025-12-15 v7.2.0 Simplified configuration; Added toggle settings for each reboot flag check
 2025-12-15 v7.0.0 Added reboot flag detection
 2025-09-25 v6.0.0 Reverted conditional logic to robust IF/ELSEIF/ELSE structure
================================================================================
#>

Set-StrictMode -Version Latest

# ==== REBOOT MODE SETTINGS ====
$RMMGracefulValue     = "`$graceful_true_or_false"
$DefaultGraceful      = $true
$WarningMinutes       = 5
$CheckCriticalApps    = $true

# Critical process names - reboot skipped if any are running (graceful mode only)
# QuickBooks: QBW32, QBW64, QBDBMgrN, QBCFMonitorService
# Databases: sqlservr, mysqld, postgres, mongod
$CriticalProcessPatterns = @(
    "QBW32",
    "QBW64",
    "QBDBMgrN",
    "QBCFMonitorService",
    "sqlservr",
    "mysqld",
    "postgres",
    "mongod"
)

# ==== UPTIME AND FLAG SETTINGS ====
$DefaultMaxUptimeDays   = 7
$CheckCBSRebootPending  = $true
$CheckWURebootRequired  = $true
$CheckPendingFileRename = $true
$RMMValue               = "`$maxuptimedays"

# ==== HELPER FUNCTIONS ====
function Write-Section {
    param([string]$title)
    Write-Host ""
    Write-Host ("[ {0} ]" -f $title)
    Write-Host ("-" * 62)
}

function PrintKV([string]$label, [string]$value) {
    $lbl = $label.PadRight(24)
    Write-Host (" {0} : {1}" -f $lbl, $value)
}

# ==== INPUT RESOLUTION (RMM -> Default) ====

# Resolve GracefulReboot (RMM -> Default)
$isGracefulRMMUsable = -not [string]::IsNullOrWhiteSpace($RMMGracefulValue) -and ($RMMGracefulValue -notmatch '^\$\w+$')
if ($isGracefulRMMUsable) {
    # RMM value provided - check if it's "true" or "false"
    $GracefulReboot = $RMMGracefulValue -match '^(true|1|yes)$'
}
else {
    $GracefulReboot = $DefaultGraceful
}

# Resolve MaxUptimeDays (RMM -> ENV -> Default)
$ResolvedInput = $null
$isRMMValueUsable = -not [string]::IsNullOrWhiteSpace($RMMValue) -and ($RMMValue -notmatch '^\$\w+$')

if ($isRMMValueUsable) {
    $ResolvedInput = $RMMValue
}
elseif (-not [string]::IsNullOrWhiteSpace($env:MAXUPTIMEDAYS)) {
    $ResolvedInput = $env:MAXUPTIMEDAYS
}
else {
    $ResolvedInput = $DefaultMaxUptimeDays
}

# ==== VALIDATE AND CAST ====
$errors = @()
if (-not ([int]::TryParse($ResolvedInput, [ref]$null) -and [int]$ResolvedInput -ge 1)) {
    $errors += "MaxUptimeDays must be an integer of 1 or greater. Value provided: '$ResolvedInput'."
}
$MaxUptimeDays = [int]$ResolvedInput

if ($errors.Count -gt 0) {
    Write-Section "ERROR OCCURRED"
    foreach ($e in $errors) { PrintKV "Message" $e }
    Write-Section "FINAL STATUS"
    Write-Host " INPUT VALIDATION FAILED"
    Write-Section "SCRIPT COMPLETED"
    exit 1
}

# ==== INPUT VALIDATION OUTPUT ====
Write-Section "INPUT VALIDATION"
PrintKV "Reboot Mode" $(if ($GracefulReboot) { "Graceful" } else { "Force" })
if ($GracefulReboot) {
    PrintKV "Warning Minutes" $WarningMinutes
    PrintKV "Check Critical Apps" $(if ($CheckCriticalApps) { "Yes" } else { "No" })
}
PrintKV "Max Uptime Days" $MaxUptimeDays
PrintKV "Check CBS Pending" $(if ($CheckCBSRebootPending) { "Yes" } else { "No" })
PrintKV "Check WU Required" $(if ($CheckWURebootRequired) { "Yes" } else { "No" })
PrintKV "Check File Rename" $(if ($CheckPendingFileRename) { "Yes" } else { "No" })

# ==== MAIN OPERATION ====
try {
    # --- Critical Application Check (Graceful Mode Only) ---
    if ($GracefulReboot -and $CheckCriticalApps) {
        Write-Section "CRITICAL APP CHECK"
        Write-Host " Checking for critical processes..."

        $runningCritical = @()
        $allProcesses = Get-Process -ErrorAction SilentlyContinue

        foreach ($pattern in $CriticalProcessPatterns) {
            $found = $allProcesses | Where-Object { $_.ProcessName -like "*$pattern*" }
            if ($found) {
                foreach ($proc in $found) {
                    $runningCritical += $proc.ProcessName
                }
            }
        }

        if ($runningCritical.Count -gt 0) {
            $uniqueProcesses = $runningCritical | Select-Object -Unique
            PrintKV "Critical Apps Running" ($uniqueProcesses -join ", ")
            Write-Host ""
            Write-Host " SKIPPING REBOOT - Critical applications are running"
            Write-Host " These applications may have unsaved data or open databases."
            Write-Host " Reboot will be attempted on next scheduled run."

            Write-Section "FINAL STATUS"
            Write-Host " REBOOT SKIPPED (Critical applications running)"

            Write-Section "SCRIPT COMPLETED"
            exit 0
        }

        Write-Host " No critical applications running"
    }

    # --- Reboot Flag Detection ---
    Write-Section "REBOOT FLAG CHECK"

    $cbsRebootPending = $false
    if ($CheckCBSRebootPending) {
        $cbsRebootPending = Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'
    }

    $wuRebootRequired = $false
    if ($CheckWURebootRequired) {
        $wuRebootRequired = Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
    }

    $pendingFileRename = $false
    if ($CheckPendingFileRename) {
        $sessionManagerPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'
        if (Test-Path $sessionManagerPath) {
            $pendingOps = Get-ItemProperty -Path $sessionManagerPath -Name 'PendingFileRenameOperations' -ErrorAction SilentlyContinue
            if ($pendingOps -and $pendingOps.PendingFileRenameOperations) {
                $pendingFileRename = $true
            }
        }
    }

    $rebootFlagsDetected = $cbsRebootPending -or $wuRebootRequired -or $pendingFileRename

    PrintKV "CBS RebootPending" $(if (-not $CheckCBSRebootPending) { "Skipped" } elseif ($cbsRebootPending) { "Yes" } else { "No" })
    PrintKV "WU RebootRequired" $(if (-not $CheckWURebootRequired) { "Skipped" } elseif ($wuRebootRequired) { "Yes" } else { "No" })
    PrintKV "PendingFileRename" $(if (-not $CheckPendingFileRename) { "Skipped" } elseif ($pendingFileRename) { "Yes" } else { "No" })
    PrintKV "Reboot Flags Detected" $(if ($rebootFlagsDetected) { "Yes" } else { "No" })

    # --- Uptime Check ---
    Write-Section "UPTIME CHECK"

    $os = Get-CimInstance Win32_OperatingSystem
    $bootTime = $os.LastBootUpTime
    $uptimeDays = ((Get-Date) - $bootTime).Days
    $bootTimeString = $bootTime.ToString('yyyy-MM-ddTHH:mm:ss')

    PrintKV "Last Boot Time" $bootTimeString
    PrintKV "Current Uptime (Days)" $uptimeDays
    PrintKV "Threshold (Days)" $MaxUptimeDays

    $uptimeExceeded = $uptimeDays -gt $MaxUptimeDays
    PrintKV "Uptime Exceeded" $(if ($uptimeExceeded) { "Yes" } else { "No" })

    # --- Reboot Decision ---
    if ($rebootFlagsDetected -or $uptimeExceeded) {
        Write-Section "REBOOT ACTION"

        # Determine trigger reason
        if ($rebootFlagsDetected -and $uptimeExceeded) {
            PrintKV "Trigger" "Both: Reboot flags AND uptime exceeded"
        }
        elseif ($rebootFlagsDetected) {
            PrintKV "Trigger" "Reboot flags detected"
        }
        else {
            PrintKV "Trigger" "Uptime exceeds threshold"
        }

        if ($GracefulReboot) {
            # Graceful: schedule shutdown with warning
            $warningSeconds = $WarningMinutes * 60
            $shutdownMessage = "System will restart for maintenance in $WarningMinutes minutes. Please save your work."

            PrintKV "Method" "Graceful ($WarningMinutes min warning)"
            PrintKV "Result" "SCHEDULING REBOOT"

            $shutdownArgs = "/r /t $warningSeconds /c `"$shutdownMessage`" /d p:0:0"
            Start-Process -FilePath "shutdown.exe" -ArgumentList $shutdownArgs -NoNewWindow -Wait

            Write-Section "FINAL STATUS"
            Write-Host " OPERATION COMPLETED SUCCESSFULLY (REBOOT SCHEDULED IN $WarningMinutes MINUTES)"
        }
        else {
            # Force: immediate reboot
            PrintKV "Method" "Force (immediate)"
            PrintKV "Result" "INITIATING REBOOT"

            Restart-Computer -Force -ErrorAction Stop

            Write-Section "FINAL STATUS"
            Write-Host " OPERATION COMPLETED SUCCESSFULLY (REBOOT INITIATED)"
        }
    }
    else {
        Write-Section "FINAL STATUS"
        Write-Host " NO REBOOT REQUIRED. Uptime within threshold and no pending flags."
    }

    Write-Section "SCRIPT COMPLETED"
    exit 0
}
catch {
    Write-Section "ERROR OCCURRED"
    PrintKV "Step" "Main Operation"
    PrintKV "Error Type" $_.Exception.GetType().Name
    PrintKV "Error Message" $_.Exception.Message

    Write-Section "FINAL STATUS"
    Write-Host " OPERATION FAILED"

    Write-Section "SCRIPT COMPLETED"
    exit 1
}
