$ErrorActionPreference = 'Stop'

<#
██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
================================================================================
 SCRIPT   : WinREAgent Cleanup                                           v1.0.3
 AUTHOR   : Limehawk.io
 DATE     : January 2026
 USAGE    : .\winreagent_cleanup.ps1
================================================================================
 FILE     : winreagent_cleanup.ps1
DESCRIPTION : Cleans up WinREAgent folder to free disk space
--------------------------------------------------------------------------------
 README
--------------------------------------------------------------------------------
 PURPOSE

 Deletes the C:\$WinREAgent folder which contains temporary Windows Recovery
 Environment update files. This folder can consume significant disk space and
 is safe to delete after WinRE updates are complete.

 DATA SOURCES & PRIORITY

 1) Hardcoded values (folder path defined within the script body)

 REQUIRED INPUTS

 - FolderPath : Path to WinREAgent folder (default: C:\$WinREAgent)

 SETTINGS

 - Deletes folder recursively if it exists
 - Hidden/system folder deletion handled

 BEHAVIOR

 1. Checks if C:\$WinREAgent folder exists
 2. If exists, deletes folder and all contents
 3. Reports result

 PREREQUISITES

 - Windows 10/11
 - Admin privileges recommended

 SECURITY NOTES

 - No secrets in logs
 - Only deletes specified system folder

 EXIT CODES

 - 0: Success (folder deleted or not found)
 - 1: Failure

 EXAMPLE RUN

 [INFO] INPUT VALIDATION
 ==============================================================
 Folder Path : C:\$WinREAgent

 [RUN] OPERATION
 ==============================================================
 Checking for WinREAgent folder...
 Folder found, deleting...

 [INFO] RESULT
 ==============================================================
 Status : Success
 Action : Folder deleted

 [INFO] SCRIPT COMPLETE
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
$actionTaken = ""

# ==== HARDCODED INPUTS ====
$FolderPath = "C:\`$WinREAgent"

# ==== RUNTIME OUTPUT ====
Write-Host ""
Write-Host "[INFO] INPUT VALIDATION"
Write-Host "=============================================================="
Write-Host "Folder Path : $FolderPath"

Write-Host ""
Write-Host "[INFO] OPERATION"
Write-Host "=============================================================="

try {
    Write-Host "[RUN] Checking for WinREAgent folder..."

    if (Test-Path $FolderPath) {
        Write-Host "[RUN] Folder found, deleting..."
        Remove-Item -Path $FolderPath -Recurse -Force -ErrorAction Stop
        $actionTaken = "Folder deleted"
        Write-Host "[OK] Deleted successfully"
    } else {
        $actionTaken = "Folder not found (nothing to delete)"
        Write-Host "[OK] Folder does not exist"
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

Write-Host ""
Write-Host "[INFO] RESULT"
Write-Host "=============================================================="
if ($errorOccurred) {
    Write-Host "Status : Failure"
} else {
    Write-Host "Status : Success"
    Write-Host "Action : $actionTaken"
}

Write-Host ""
Write-Host "[INFO] FINAL STATUS"
Write-Host "=============================================================="
if ($errorOccurred) {
    Write-Host "[ERROR] WinREAgent cleanup failed. See error above."
} else {
    Write-Host "[OK] WinREAgent cleanup completed."
}

Write-Host ""
Write-Host "[INFO] SCRIPT COMPLETE"
Write-Host "=============================================================="

if ($errorOccurred) {
    exit 1
} else {
    exit 0
}
