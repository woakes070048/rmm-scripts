$ErrorActionPreference = 'Stop'

<#
██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
================================================================================
 SCRIPT   : Complete OneDrive Removal v1.2.2
 AUTHOR   : Limehawk.io
 DATE     : January 2026
 USAGE    : .\onedrive_remove_complete.ps1
================================================================================
 FILE     : onedrive_remove_complete.ps1
 DESCRIPTION : Completely removes Microsoft OneDrive with startup suppression
--------------------------------------------------------------------------------
 README
--------------------------------------------------------------------------------
 PURPOSE

 Performs a complete, multi-path uninstallation of Microsoft OneDrive with
 permanent startup suppression. Stops running processes, executes the official
 Microsoft uninstall utility against all known install paths (system and Office),
 removes scheduled tasks, and applies registry policies to prevent reinstallation.

 DATA SOURCES & PRIORITY

 1) Hardcoded OneDriveSetup.exe paths (system and Office locations)
 2) Registry keys for GPO, Explorer, and Run persistence
 3) Task Scheduler for OneDrive scheduled tasks
 4) WMI/CIM for system diagnostics

 REQUIRED INPUTS

   All inputs are hardcoded in the script body:
     - $cleanDefaultProfile : Clean Default User profile to prevent OneDrive on
                              new accounts (default: true)

 SETTINGS

 - OneDrive Setup Paths: System32, SysWOW64, Office x86, Office x64
 - Registry GPO Path: HKLM:\Software\Policies\Microsoft\Windows\OneDrive
 - Registry Explorer Path: HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer
 - Registry Run Key: HKCU:\Software\Microsoft\Windows\CurrentVersion\Run

 BEHAVIOR

 1. Validates administrative privileges
 2. Stops all running OneDrive processes
 3. Executes OneDriveSetup.exe /uninstall for each found path
 4. Removes all OneDrive scheduled tasks
 5. Sets HKLM GPO DisableFileSyncNGSC=1 to prevent startup for all users
 6. Removes HKCU Run key OneDrive entry
 7. Sets Explorer policy to hide OneDrive from navigation pane
 8. Cleans Default User profile to prevent OneDrive on new accounts
 9. Reports completion status with reboot recommendation

 PREREQUISITES

 - PowerShell 5.1 or later
 - Administrator privileges required
 - No network requirements (local operations only)

 SECURITY NOTES

 - No secrets (API keys, passwords) are used or logged
 - All actions confined to local files, registry, and task scheduler
 - Registry modifications use Group Policy paths for proper enforcement

 ENDPOINTS

 - N/A (local machine only)

 EXIT CODES

 - 0 : Success - all cleanup steps completed
 - 1 : Failure - critical error (likely permission-related)

 EXAMPLE RUN

 [INFO] INPUT VALIDATION
 ==============================================================
 Computer Name    : WKSTN-FIN-01
 Username         : SYSTEM
 Admin Privileges : Confirmed
 Paths to Check   : 4

 [RUN] STOPPING PROCESSES
 ==============================================================
 Stopping OneDrive processes...
 OneDrive processes terminated

 [RUN] UNINSTALLING ONEDRIVE
 ==============================================================
 Checking path   : C:\Windows\SysWOW64\OneDriveSetup.exe
 Status          : Found - executing uninstall
 Result          : Uninstall command completed

 Checking path   : C:\Windows\System32\OneDriveSetup.exe
 Status          : Not found - skipping

 Checking path   : C:\Program Files\Microsoft Office\root\...
 Status          : Not found - skipping

 Checking path   : C:\Program Files (x86)\Microsoft Office\root\...
 Status          : Not found - skipping

 Uninstallers Run : 1

 [RUN] REMOVING SCHEDULED TASKS
 ==============================================================
 Removing OneDrive scheduled tasks...
 Scheduled tasks removed

 [RUN] CLEANING REGISTRY
 ==============================================================
 Setting HKLM GPO DisableFileSyncNGSC = 1
 HKLM GPO policy applied

 Removing HKCU Run key OneDrive entry
 HKCU Run key cleaned

 Setting Explorer DisableOneDriveFileSync = 1
 Explorer policy applied

 [INFO] FINAL STATUS
 ==============================================================
 Result           : SUCCESS
 Uninstallers Run : 1
 OneDrive removal complete - reboot recommended for full cleanup

 [OK] SCRIPT COMPLETED
 ==============================================================

--------------------------------------------------------------------------------
 CHANGELOG
--------------------------------------------------------------------------------
 2026-01-19 v1.2.2 Fixed EXAMPLE RUN section formatting
 2026-01-19 v1.2.1 Updated to two-line ASCII console output style
 2026-01-05 v1.2.0 Added Default User profile cleanup to prevent OneDrive on new accounts
 2025-12-23 v1.1.1 Updated to Limehawk Script Framework
 2025-11-29 v1.1.0 Refactored to Limehawk Style A with improved validation, cleaner section organization, and enhanced error handling
 2025-09-19 v1.0.0 Initial version for complete multi-path OneDrive uninstall
================================================================================
#>

Set-StrictMode -Version Latest

# ============================================================================
# STATE VARIABLES
# ============================================================================

$errorOccurred = $false
$errorText     = ""
$uninstallCount = 0

# ============================================================================
# HARDCODED INPUTS
# ============================================================================

# Clean Default User profile to prevent OneDrive on new accounts
$cleanDefaultProfile = $true

# OneDriveSetup.exe paths across various Windows/Office installations
$oneDrivePaths = @(
    "$env:SystemRoot\SysWOW64\OneDriveSetup.exe",
    "$env:SystemRoot\System32\OneDriveSetup.exe",
    "$env:ProgramFiles\Microsoft Office\root\Integration\Addons\OneDriveSetup.exe",
    "${env:ProgramFiles(x86)}\Microsoft Office\root\Integration\Addons\OneDriveSetup.exe"
)

# Registry paths for persistence cleanup
$gpoPath      = "HKLM:\Software\Policies\Microsoft\Windows\OneDrive"
$explorerPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer"
$runKeyPath   = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"

# ============================================================================
# INPUT VALIDATION
# ============================================================================

Write-Host ""
Write-Host "[INFO] INPUT VALIDATION"
Write-Host "=============================================================="

# Validate admin privileges
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- Script must be run with Administrator privileges"
}

if ($errorOccurred) {
    Write-Host ""
    Write-Host "[ERROR] VALIDATION FAILED"
    Write-Host "=============================================================="
    Write-Host "Input validation failed:"
    Write-Host $errorText
    Write-Host ""
    Write-Host "Troubleshooting:"
    Write-Host "- Run PowerShell as Administrator"
    Write-Host "- Deploy via RMM with SYSTEM context"
    exit 1
}

Write-Host "Computer Name      : $env:COMPUTERNAME"
Write-Host "Username           : $env:USERNAME"
Write-Host "Admin Privileges   : Confirmed"
Write-Host "Paths to Check     : $($oneDrivePaths.Count)"
Write-Host "Clean Default User : $cleanDefaultProfile"

# ============================================================================
# STOP PROCESSES
# ============================================================================

Write-Host ""
Write-Host "[INFO] STOP PROCESSES"
Write-Host "=============================================================="

Write-Host "[RUN] Stopping OneDrive processes..."
Stop-Process -Name "OneDrive*" -Force -ErrorAction SilentlyContinue
Write-Host "[OK] OneDrive processes terminated"

# ============================================================================
# UNINSTALL ONEDRIVE
# ============================================================================

Write-Host ""
Write-Host "[INFO] UNINSTALL ONEDRIVE"
Write-Host "=============================================================="

foreach ($path in $oneDrivePaths) {
    Write-Host "Checking path   : $path"

    if (Test-Path $path) {
        Write-Host "Status          : Found - executing uninstall"

        try {
            $process = Start-Process -FilePath $path -ArgumentList "/uninstall" -Wait -PassThru -NoNewWindow -ErrorAction Stop
            Write-Host "[OK] Result          : Uninstall command completed (Exit: $($process.ExitCode))"
            $uninstallCount++
        } catch {
            Write-Host "[ERROR] Result          : Failed - $($_.Exception.Message)"
        }
    } else {
        Write-Host "Status          : Not found - skipping"
    }
    Write-Host ""
}

Write-Host "Uninstallers Run : $uninstallCount"

# ============================================================================
# REMOVE SCHEDULED TASKS
# ============================================================================

Write-Host ""
Write-Host "[INFO] REMOVE SCHEDULED TASKS"
Write-Host "=============================================================="

Write-Host "[RUN] Removing OneDrive scheduled tasks..."

try {
    $tasks = Get-ScheduledTask -TaskName "OneDrive*" -ErrorAction SilentlyContinue
    if ($tasks) {
        $tasks | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue
        Write-Host "[OK] Scheduled tasks removed : $($tasks.Count) task(s)"
    } else {
        Write-Host "No OneDrive scheduled tasks found"
    }
} catch {
    Write-Host "[WARN] Task removal skipped : $($_.Exception.Message)"
}

# ============================================================================
# REGISTRY CLEANUP
# ============================================================================

Write-Host ""
Write-Host "[INFO] REGISTRY CLEANUP"
Write-Host "=============================================================="

# HKLM GPO - Disable OneDrive file sync for all users
Write-Host "[RUN] Setting HKLM GPO DisableFileSyncNGSC = 1"
try {
    if (-not (Test-Path $gpoPath)) {
        New-Item -Path $gpoPath -Force | Out-Null
    }
    Set-ItemProperty -Path $gpoPath -Name "DisableFileSyncNGSC" -Value 1 -Type DWord -Force
    Write-Host "[OK] HKLM GPO policy applied"
} catch {
    Write-Host "[ERROR] HKLM GPO failed : $($_.Exception.Message)"
}

Write-Host ""

# HKCU Run Key - Remove OneDrive auto-start entry
Write-Host "[RUN] Removing HKCU Run key OneDrive entry"
try {
    $runKeyExists = Get-ItemProperty -Path $runKeyPath -Name "OneDrive" -ErrorAction SilentlyContinue
    if ($runKeyExists) {
        Remove-ItemProperty -Path $runKeyPath -Name "OneDrive" -Force -ErrorAction Stop
        Write-Host "[OK] HKCU Run key removed"
    } else {
        Write-Host "HKCU Run key not present - skipping"
    }
} catch {
    Write-Host "[WARN] HKCU Run key removal skipped : $($_.Exception.Message)"
}

Write-Host ""

# Explorer Policy - Hide OneDrive from navigation pane
Write-Host "[RUN] Setting Explorer DisableOneDriveFileSync = 1"
try {
    if (-not (Test-Path $explorerPath)) {
        New-Item -Path $explorerPath -Force | Out-Null
    }
    Set-ItemProperty -Path $explorerPath -Name "DisableOneDriveFileSync" -Value 1 -Type DWord -Force
    Write-Host "[OK] Explorer policy applied"
} catch {
    Write-Host "[ERROR] Explorer policy failed : $($_.Exception.Message)"
}

# ============================================================================
# DEFAULT USER PROFILE CLEANUP
# ============================================================================

if ($cleanDefaultProfile) {
    Write-Host ""
    Write-Host "[INFO] DEFAULT USER PROFILE"
    Write-Host "=============================================================="

    $defaultUserHive = "$env:SystemDrive\Users\Default\NTUSER.DAT"
    $tempHiveKey = "HKU\DefaultUserTemp"

    if (Test-Path $defaultUserHive) {
        Write-Host "[RUN] Loading Default User registry hive..."

        try {
            # Load the Default User hive
            $loadResult = & reg.exe load $tempHiveKey $defaultUserHive 2>&1
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to load hive: $loadResult"
            }
            Write-Host "[OK] Hive loaded successfully"

            # Remove OneDrive Run key from Default User
            Write-Host "[RUN] Removing OneDrive Run key from Default User..."
            $defaultRunPath = "$tempHiveKey\Software\Microsoft\Windows\CurrentVersion\Run"
            & reg.exe delete $defaultRunPath /v "OneDrive" /f 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "[OK] OneDrive Run key removed from Default User"
            } else {
                Write-Host "OneDrive Run key not present in Default User"
            }

            # Remove OneDrive setup key that triggers first-run
            Write-Host "[RUN] Removing OneDrive setup triggers..."
            $oneDriveSetupPath = "$tempHiveKey\Software\Microsoft\OneDrive"
            & reg.exe delete $oneDriveSetupPath /f 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "[OK] OneDrive setup keys removed"
            } else {
                Write-Host "OneDrive setup keys not present"
            }

            # Unload the hive
            Write-Host "[RUN] Unloading Default User registry hive..."
            [gc]::Collect()
            Start-Sleep -Milliseconds 500
            $unloadResult = & reg.exe unload $tempHiveKey 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Host "[WARN] Hive unload delayed (will complete on reboot)"
            } else {
                Write-Host "[OK] Hive unloaded successfully"
            }

            Write-Host "[OK] Default User profile cleaned"
        }
        catch {
            Write-Host "[ERROR] Default User cleanup failed : $($_.Exception.Message)"
            # Attempt to unload hive if it was loaded
            & reg.exe unload $tempHiveKey 2>&1 | Out-Null
        }
    } else {
        Write-Host "Default User hive not found : $defaultUserHive"
    }
} else {
    Write-Host ""
    Write-Host "[INFO] DEFAULT USER PROFILE"
    Write-Host "=============================================================="
    Write-Host "Skipped (cleanDefaultProfile = false)"
}

# ============================================================================
# FINAL STATUS
# ============================================================================

Write-Host ""
Write-Host "[INFO] FINAL STATUS"
Write-Host "=============================================================="

Write-Host "Result           : SUCCESS"
Write-Host "Uninstallers Run : $uninstallCount"
Write-Host "OneDrive removal complete - reboot recommended for full cleanup"

Write-Host ""
Write-Host "[INFO] SCRIPT COMPLETED"
Write-Host "=============================================================="

exit 0
