$ErrorActionPreference = 'Stop'

<#
██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
================================================================================
 SCRIPT   : WinRE Restore                                                v1.0.1
 AUTHOR   : Limehawk.io
 DATE      : December 2025
 USAGE    : .\winre_restore.ps1
================================================================================
 FILE     : winre_restore.ps1
DESCRIPTION : Restores Windows Recovery Environment from system image
--------------------------------------------------------------------------------
 README
--------------------------------------------------------------------------------
 PURPOSE

 Restores Windows Recovery Environment (WinRE) by downloading Winre.wim and
 ReAgent.xml files from a specified URL and placing them in the Recovery folder.
 Fixes systems where WinRE has been corrupted or deleted.

 DATA SOURCES & PRIORITY

 1) Hardcoded values (download URLs defined within the script body)
 2) Windows Recovery Environment (reagentc)

 REQUIRED INPUTS

 - WinreWimUrl    : URL to download Winre.wim file
 - ReAgentXmlUrl  : URL to download ReAgent.xml file
 - RecoveryPath   : Path to Windows Recovery folder

 SETTINGS

 - Downloads files to TEMP then moves to Recovery folder
 - Disables WinRE before restore, re-enables after
 - Uses curl with retry and timeout

 BEHAVIOR

 1. Disables WinRE (reagentc /disable)
 2. Downloads Winre.wim from specified URL
 3. Downloads ReAgent.xml from specified URL
 4. Moves files to C:\Windows\System32\Recovery
 5. Re-enables WinRE (reagentc /enable)

 PREREQUISITES

 - Windows 10/11
 - Admin privileges required
 - Network connectivity to download URLs
 - Valid WinRE files hosted at specified URLs

 SECURITY NOTES

 - No secrets in logs
 - Downloads from specified URLs - ensure URLs are trusted
 - Modifies system recovery configuration

 EXIT CODES

 - 0: Success
 - 1: Failure

 EXAMPLE RUN

 [ INPUT VALIDATION ]
 --------------------------------------------------------------
 WinRE WIM URL   : https://your-server.com/Winre.wim
 ReAgent XML URL : https://your-server.com/ReAgent.xml
 Recovery Path   : C:\Windows\System32\Recovery

 [ OPERATION ]
 --------------------------------------------------------------
 Disabling WinRE...
 Downloading Winre.wim...
 Downloading ReAgent.xml...
 Moving files to Recovery folder...
 Enabling WinRE...

 [ RESULT ]
 --------------------------------------------------------------
 Status : Success

 [ SCRIPT COMPLETED ]
 --------------------------------------------------------------
--------------------------------------------------------------------------------
 CHANGELOG
--------------------------------------------------------------------------------
 2025-12-23 v1.0.1 Updated to Limehawk Script Framework
 2025-11-29 v1.0.0 Initial Style A implementation
================================================================================
#>

Set-StrictMode -Version Latest

# ==== STATE ====
$errorOccurred = $false
$errorText = ""

# ==== HARDCODED INPUTS ====
# UPDATE THESE URLS TO YOUR WinRE BACKUP LOCATION
$WinreWimUrl = "https://your-file-server.com/winRE-backup-files/Winre.wim"
$ReAgentXmlUrl = "https://your-file-server.com/winRE-backup-files/ReAgent.xml"
$RecoveryPath = "C:\Windows\System32\Recovery"

# ==== VALIDATION ====
if ([string]::IsNullOrWhiteSpace($WinreWimUrl)) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- WinreWimUrl is required."
}
if ([string]::IsNullOrWhiteSpace($ReAgentXmlUrl)) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- ReAgentXmlUrl is required."
}

if ($errorOccurred) {
    Write-Host ""
    Write-Host "[ ERROR OCCURRED ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host $errorText
    exit 1
}

# ==== ADMIN CHECK ====
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host ""
    Write-Host "[ ERROR OCCURRED ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host "Script requires admin privileges."
    Write-Host "Please relaunch as Administrator."
    exit 1
}

# ==== RUNTIME OUTPUT ====
Write-Host ""
Write-Host "[ INPUT VALIDATION ]"
Write-Host "--------------------------------------------------------------"
Write-Host "WinRE WIM URL   : $WinreWimUrl"
Write-Host "ReAgent XML URL : $ReAgentXmlUrl"
Write-Host "Recovery Path   : $RecoveryPath"

Write-Host ""
Write-Host "[ OPERATION ]"
Write-Host "--------------------------------------------------------------"

try {
    # Disable WinRE
    Write-Host "Disabling WinRE..."
    $result = reagentc /disable 2>&1
    Write-Host "  $result"

    # Ensure recovery directory exists
    if (-not (Test-Path $RecoveryPath)) {
        Write-Host "Creating Recovery directory..."
        New-Item -Path $RecoveryPath -ItemType Directory -Force | Out-Null
    }

    # Download Winre.wim
    $wimTempPath = Join-Path $env:TEMP "Winre.wim"
    $wimFinalPath = Join-Path $RecoveryPath "Winre.wim"

    Write-Host "Downloading Winre.wim..."
    if (Test-Path $wimTempPath) { Remove-Item $wimTempPath -Force }

    $webClient = New-Object System.Net.WebClient
    try {
        $webClient.DownloadFile($WinreWimUrl, $wimTempPath)
    } finally {
        $webClient.Dispose()
    }

    if (-not (Test-Path $wimTempPath)) {
        throw "Failed to download Winre.wim"
    }
    Write-Host "  Downloaded successfully"

    # Download ReAgent.xml
    $xmlTempPath = Join-Path $env:TEMP "ReAgent.xml"
    $xmlFinalPath = Join-Path $RecoveryPath "ReAgent.xml"

    Write-Host "Downloading ReAgent.xml..."
    if (Test-Path $xmlTempPath) { Remove-Item $xmlTempPath -Force }

    $webClient = New-Object System.Net.WebClient
    try {
        $webClient.DownloadFile($ReAgentXmlUrl, $xmlTempPath)
    } finally {
        $webClient.Dispose()
    }

    if (-not (Test-Path $xmlTempPath)) {
        throw "Failed to download ReAgent.xml"
    }
    Write-Host "  Downloaded successfully"

    # Move files to Recovery folder
    Write-Host "Moving files to Recovery folder..."
    Move-Item -Path $wimTempPath -Destination $wimFinalPath -Force
    Move-Item -Path $xmlTempPath -Destination $xmlFinalPath -Force
    Write-Host "  Files moved successfully"

    # Enable WinRE
    Write-Host "Enabling WinRE..."
    $result = reagentc /enable 2>&1
    Write-Host "  $result"

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
}

Write-Host ""
Write-Host "[ FINAL STATUS ]"
Write-Host "--------------------------------------------------------------"
if ($errorOccurred) {
    Write-Host "WinRE restore failed. See error above."
} else {
    Write-Host "Windows Recovery Environment has been restored."
    # Check WinRE status
    $status = reagentc /info 2>&1
    Write-Host $status
}

Write-Host ""
Write-Host "[ SCRIPT COMPLETED ]"
Write-Host "--------------------------------------------------------------"

if ($errorOccurred) {
    exit 1
} else {
    exit 0
}
