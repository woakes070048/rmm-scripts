$ErrorActionPreference = 'Stop'

<#
██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
================================================================================
 SCRIPT   : WinREAgent Cleanup                                           v1.0.1
 AUTHOR   : Limehawk.io
 DATE     : December 2024
 USAGE    : .\winreagent_cleanup.ps1
================================================================================
 FILE     : winreagent_cleanup.ps1
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

 [ INPUT VALIDATION ]
 --------------------------------------------------------------
 Folder Path : C:\$WinREAgent

 [ OPERATION ]
 --------------------------------------------------------------
 Checking for WinREAgent folder...
 Folder found, deleting...

 [ RESULT ]
 --------------------------------------------------------------
 Status : Success
 Action : Folder deleted

 [ SCRIPT COMPLETED ]
 --------------------------------------------------------------
--------------------------------------------------------------------------------
 CHANGELOG
--------------------------------------------------------------------------------
 2024-12-23 v1.0.1 Updated to Limehawk Script Framework
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
Write-Host "[ INPUT VALIDATION ]"
Write-Host "--------------------------------------------------------------"
Write-Host "Folder Path : $FolderPath"

Write-Host ""
Write-Host "[ OPERATION ]"
Write-Host "--------------------------------------------------------------"

try {
    Write-Host "Checking for WinREAgent folder..."

    if (Test-Path $FolderPath) {
        Write-Host "Folder found, deleting..."
        Remove-Item -Path $FolderPath -Recurse -Force -ErrorAction Stop
        $actionTaken = "Folder deleted"
        Write-Host "  Deleted successfully"
    } else {
        $actionTaken = "Folder not found (nothing to delete)"
        Write-Host "  Folder does not exist"
    }

} catch {
    $errorOccurred = $true
    $errorText = $_.Exception.Message
}

if ($errorOccurred) {
    Write-Host ""
    Write-Host "[ ERROR OCCURRED ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host $errorText
}

Write-Host ""
Write-Host "[ RESULT ]"
Write-Host "--------------------------------------------------------------"
if ($errorOccurred) {
    Write-Host "Status : Failure"
} else {
    Write-Host "Status : Success"
    Write-Host "Action : $actionTaken"
}

Write-Host ""
Write-Host "[ FINAL STATUS ]"
Write-Host "--------------------------------------------------------------"
if ($errorOccurred) {
    Write-Host "WinREAgent cleanup failed. See error above."
} else {
    Write-Host "WinREAgent cleanup completed."
}

Write-Host ""
Write-Host "[ SCRIPT COMPLETED ]"
Write-Host "--------------------------------------------------------------"

if ($errorOccurred) {
    exit 1
} else {
    exit 0
}
