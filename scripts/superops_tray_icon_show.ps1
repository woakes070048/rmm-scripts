$ErrorActionPreference = 'Stop'
<#
██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
================================================================================
 SCRIPT   : SuperOps Tray Icon Show                                       v1.0.0
 AUTHOR   : Limehawk.io
 DATE     : December 2024
 USAGE    : .\superops_tray_icon_show.ps1
================================================================================
 FILE     : superops_tray_icon_show.ps1
--------------------------------------------------------------------------------
 README
--------------------------------------------------------------------------------
 PURPOSE

   Promotes the SuperOps agent tray icon to be visible in the system tray
   instead of hidden in the overflow area. Searches the NotifyIconSettings
   registry for any entry containing "superops" and sets IsPromoted=1.

 DATA SOURCES & PRIORITY

   - Windows Registry: HKCU:\Control Panel\NotifyIconSettings

 REQUIRED INPUTS

   All inputs are hardcoded in the script body:
     - $searchPattern: Text to match in registry values (default: *superops*)

 SETTINGS

   Change $searchPattern if you need to match a different application name.

 BEHAVIOR

   The script performs the following actions in order:
   1. Enumerates all subkeys under NotifyIconSettings
   2. Searches each key's values for the search pattern
   3. Sets IsPromoted=1 for matching keys (makes icon visible)

 PREREQUISITES

   - PowerShell 5.1 or later
   - Must run as logged-in user (HKCU registry)
   - SuperOps agent must have run at least once (to create tray icon entry)

 SECURITY NOTES

   - No secrets exposed in output
   - Only modifies current user's notification settings
   - No admin rights required

 ENDPOINTS

   - Not applicable (local operations only)

 EXIT CODES

   0 = Success
   1 = Failure (error occurred)

 EXAMPLE RUN

   [ SEARCH TRAY ICONS ]
   --------------------------------------------------------------
   Searching for: *superops*
   Found 12 notification icon entries
   Set IsPromoted=1 for key: 7369737...

   [ FINAL STATUS ]
   --------------------------------------------------------------
   Result : SUCCESS
   Icons promoted : 1

   [ SCRIPT COMPLETE ]
   --------------------------------------------------------------

--------------------------------------------------------------------------------
 CHANGELOG
--------------------------------------------------------------------------------
 2024-12-28 v1.0.0 Initial release
================================================================================
#>
Set-StrictMode -Version Latest

# ============================================================================
# SETTINGS
# ============================================================================

# Search pattern - change to match different application
$searchPattern = '*superops*'

# ============================================================================
# STATE VARIABLES
# ============================================================================
$iconsPromoted = 0
$errorOccurred = $false

# ============================================================================
# SEARCH TRAY ICONS
# ============================================================================
Write-Host ""
Write-Host "[ SEARCH TRAY ICONS ]"
Write-Host "--------------------------------------------------------------"
Write-Host "Searching for: $searchPattern"

$notifyIconPath = "HKCU:\Control Panel\NotifyIconSettings"

if (-not (Test-Path $notifyIconPath)) {
    Write-Host "NotifyIconSettings key not found"
    Write-Host ""
    Write-Host "[ FINAL STATUS ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host "Result : NO ACTION"
    Write-Host "The notification icon settings registry key does not exist"
    Write-Host ""
    Write-Host "[ SCRIPT COMPLETE ]"
    Write-Host "--------------------------------------------------------------"
    exit 0
}

$subKeys = Get-ChildItem -Path $notifyIconPath -ErrorAction SilentlyContinue
Write-Host "Found $($subKeys.Count) notification icon entries"

foreach ($key in $subKeys) {
    try {
        $values = Get-ItemProperty -Path $key.PSPath
        $matchFound = $false

        foreach ($property in $values.PSObject.Properties) {
            if ($property.Value -is [string] -and $property.Value -like $searchPattern) {
                $matchFound = $true
                break
            }
        }

        if ($matchFound) {
            Set-ItemProperty -Path $key.PSPath -Name "IsPromoted" -Value 1 -Type DWord
            Write-Host "Set IsPromoted=1 for key: $($key.PSChildName)"
            $iconsPromoted++
        }
    } catch {
        Write-Host "Error reading key: $($key.PSChildName)"
        $errorOccurred = $true
    }
}

# ============================================================================
# FINAL STATUS
# ============================================================================
Write-Host ""
Write-Host "[ FINAL STATUS ]"
Write-Host "--------------------------------------------------------------"

if ($iconsPromoted -eq 0) {
    Write-Host "Result : NO MATCH"
    Write-Host "No tray icons matching '$searchPattern' were found"
    Write-Host ""
    Write-Host "The SuperOps agent may not have run yet, or the icon"
    Write-Host "entry uses a different name in the registry."
} elseif ($errorOccurred) {
    Write-Host "Result : PARTIAL SUCCESS"
    Write-Host "Icons promoted : $iconsPromoted"
} else {
    Write-Host "Result : SUCCESS"
    Write-Host "Icons promoted : $iconsPromoted"
}

Write-Host ""
Write-Host "[ SCRIPT COMPLETE ]"
Write-Host "--------------------------------------------------------------"
exit 0
