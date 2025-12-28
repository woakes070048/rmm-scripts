$ErrorActionPreference = 'Stop'

<#
██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
================================================================================
 SCRIPT   : SuperOps Tray Icon Always Show                                v1.2.0
 AUTHOR   : Limehawk.io
 DATE     : December 2024
 USAGE    : .\superops_tray_icon_always_show.ps1
================================================================================
 FILE     : superops_tray_icon_always_show.ps1
--------------------------------------------------------------------------------
 README
--------------------------------------------------------------------------------
 PURPOSE

   *** MUST RUN AS LOGGED-IN USER - NOT SYSTEM ***

   Configures Windows system tray settings to always show the SuperOps RMM
   agent tray icon. This ensures the SuperOps icon remains visible in the
   system tray notification area rather than being hidden in the overflow.

   Modifies HKCU registry which is per-user. Running as SYSTEM will modify
   SYSTEM's registry, not the user's - and will have no effect.

 DATA SOURCES & PRIORITY
 1) Windows Registry (HKCU:\Control Panel\NotifyIconSettings)
 2) Hardcoded search pattern ("superops")

 REQUIRED INPUTS
 None - Script automatically detects and configures SuperOps tray icon settings

 SETTINGS
 - Searches all notification icon registry entries for SuperOps-related entries
 - Sets IsPromoted=1 for matching entries (makes icon always visible)
 - Processes all users' notification area settings under HKCU context
 - Uses case-insensitive pattern matching for "superops"

 BEHAVIOR
 - Enumerates all subkeys in HKCU:\Control Panel\NotifyIconSettings
 - Searches each key's properties for strings containing "superops"
 - When a match is found, sets the IsPromoted DWORD value to 1
 - Reports each modification made to the console
 - Continues processing even if individual keys fail to read
 - No restart required - changes take effect on next tray icon update

 PREREQUISITES

   - PowerShell 5.1 or later
   - *** MUST RUN AS LOGGED-IN USER (NOT SYSTEM) ***
   - SuperOps agent must be installed (creates notification icon entries)
   - No elevation required (modifies current user's registry only)

 SECURITY NOTES
 - No secrets or credentials used
 - Only modifies current user's notification settings
 - Does not affect system-wide or other users' settings
 - Read-only access to detect SuperOps entries
 - Write access only to IsPromoted value (standard Windows setting)

 ENDPOINTS
 - N/A (local registry modification only)

 EXIT CODES
 - 0 success
 - 1 failure

 EXAMPLE RUN (Style A)
 [ INPUT VALIDATION ]
 --------------------------------------------------------------
 Registry Path : HKCU:\Control Panel\NotifyIconSettings
 Search Pattern : *superops*

 [ OPERATION ]
 --------------------------------------------------------------
 Scanning notification icon settings...
 Found 15 registered notification icons
 Checking for SuperOps entries...
 Set IsPromoted=1 for key: 1234567890
 Processing complete

 [ RESULT ]
 --------------------------------------------------------------
 Status : Success
 Icons Modified : 1

 [ FINAL STATUS ]
 --------------------------------------------------------------
 SuperOps tray icon configured to always show

 [ SCRIPT COMPLETED ]
 --------------------------------------------------------------
--------------------------------------------------------------------------------
 CHANGELOG
--------------------------------------------------------------------------------
 2025-12-28 v1.2.0 Added user context check, made warning more obvious
 2024-12-23 v1.1.0 Updated to Limehawk Script Framework
 2024-11-02 v1.0.0 Initial release
================================================================================
#>

Set-StrictMode -Version Latest

# ==== STATE (NO ARRAYS/LISTS) ====
$errorOccurred = $false
$errorText     = ""
$iconsFound    = 0
$iconsModified = 0

# ==== HARDCODED INPUTS (MANDATORY) ====
$notifyIconPath = "HKCU:\Control Panel\NotifyIconSettings"
$searchPattern  = "*superops*"

# ==== USER CONTEXT CHECK ====
Write-Host ""
Write-Host "[ USER CHECK ]"
Write-Host "--------------------------------------------------------------"

$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
Write-Host "Running as : $currentUser"

if ($currentUser -match "SYSTEM$") {
    Write-Host ""
    Write-Host "[ ERROR OCCURRED ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host "This script must run as the logged-in user, not SYSTEM"
    Write-Host ""
    Write-Host "Tray icon settings are per-user (stored in HKCU)."
    Write-Host "Running as SYSTEM modifies SYSTEM's registry, not the user's."
    Write-Host ""
    Write-Host "Solutions:"
    Write-Host "  - RMM: Run as 'logged-in user' instead of 'SYSTEM'"
    Write-Host "  - GPO: Use a logon script"
    Write-Host "  - Manual: Run from user's PowerShell session"
    Write-Host ""
    Write-Host "[ SCRIPT COMPLETED ]"
    Write-Host "--------------------------------------------------------------"
    exit 1
}
Write-Host "Context is valid (not SYSTEM)"

# ==== VALIDATION ====
if (-not (Test-Path $notifyIconPath)) {
    $errorOccurred = $true
    $errorText = "- Registry path not found: $notifyIconPath`n"
    $errorText += "  This path should exist on all Windows systems with notification icons.`n"
    $errorText += "  The system may not have any notification area icons configured."
}

if ($errorOccurred) {
    Write-Host ""
    Write-Host "[ ERROR OCCURRED ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host $errorText

    Write-Host ""
    Write-Host "[ RESULT ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host "Status : Failure"

    Write-Host ""
    Write-Host "[ FINAL STATUS ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host "Cannot access notification icon registry settings."

    Write-Host ""
    Write-Host "[ SCRIPT COMPLETED ]"
    Write-Host "--------------------------------------------------------------"
    exit 1
}

# ==== RUNTIME OUTPUT (Style A) ====
Write-Host ""
Write-Host "[ INPUT VALIDATION ]"
Write-Host "--------------------------------------------------------------"
Write-Host "Registry Path  : $notifyIconPath"
Write-Host "Search Pattern : $searchPattern"

Write-Host ""
Write-Host "[ OPERATION ]"
Write-Host "--------------------------------------------------------------"

try {
    Write-Host "Scanning notification icon settings..."

    # Get all subkeys
    $subKeys = Get-ChildItem -Path $notifyIconPath -ErrorAction Stop

    $iconsFound = $subKeys.Count
    Write-Host "Found $iconsFound registered notification icons"
    Write-Host "Checking for SuperOps entries..."

    foreach ($key in $subKeys) {
        try {
            $values = Get-ItemProperty -Path $key.PSPath -ErrorAction Stop

            # Check for any property that contains "superops" (case-insensitive)
            $matchFound = $false
            foreach ($property in $values.PSObject.Properties) {
                if ($property.Value -is [string] -and $property.Value -like $searchPattern) {
                    $matchFound = $true
                    break
                }
            }

            # Set IsPromoted to 1 if we find a match
            if ($matchFound) {
                try {
                    Set-ItemProperty -Path $key.PSPath -Name "IsPromoted" -Value 1 -Type DWord -ErrorAction Stop
                    Write-Host "Set IsPromoted=1 for key: $($key.PSChildName)"
                    $iconsModified++
                } catch {
                    Write-Host "Warning: Failed to set IsPromoted for key $($key.PSChildName): $($_.Exception.Message)"
                }
            }
        } catch {
            Write-Host "Warning: Could not read key $($key.PSChildName): $($_.Exception.Message)"
            # Continue processing other keys
        }
    }

    Write-Host "Processing complete"

    if ($iconsModified -eq 0) {
        Write-Host "Note: No SuperOps entries found. This could mean:"
        Write-Host "  - SuperOps agent is not installed"
        Write-Host "  - SuperOps tray icon has not been displayed yet"
        Write-Host "  - SuperOps tray icon is already configured to always show"
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
    Write-Host "Status         : Failure"
} else {
    Write-Host "Status         : Success"
}
Write-Host "Icons Found    : $iconsFound"
Write-Host "Icons Modified : $iconsModified"

Write-Host ""
Write-Host "[ FINAL STATUS ]"
Write-Host "--------------------------------------------------------------"
if ($errorOccurred) {
    Write-Host "Failed to configure SuperOps tray icon settings. See error details above."
} else {
    if ($iconsModified -gt 0) {
        Write-Host "SuperOps tray icon configured to always show"
    } else {
        Write-Host "No SuperOps tray icon entries found to configure"
    }
}

Write-Host ""
Write-Host "[ SCRIPT COMPLETED ]"
Write-Host "--------------------------------------------------------------"

if ($errorOccurred) {
    exit 1
} else {
    exit 0
}
