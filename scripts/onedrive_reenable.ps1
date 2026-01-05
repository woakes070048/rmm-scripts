$ErrorActionPreference = 'Stop'
<#
██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
================================================================================
 SCRIPT   : Re-enable OneDrive v1.0.0
 AUTHOR   : Limehawk.io
 DATE     : January 2026
 USAGE    : .\onedrive_reenable.ps1
================================================================================
 FILE     : onedrive_reenable.ps1
 DESCRIPTION : Removes OneDrive blocking policies to allow reinstallation
--------------------------------------------------------------------------------
 README
--------------------------------------------------------------------------------
 PURPOSE

   Reverses the registry policies set by onedrive_remove_complete.ps1 to allow
   OneDrive to be reinstalled and function normally. Use this when a machine
   needs to switch back to Microsoft services. Does NOT install OneDrive - only
   removes the blocking policies so it can be installed via Microsoft 365 or
   Windows Update.

 DATA SOURCES & PRIORITY

   1) Registry keys for GPO and Explorer policies
   2) Default User profile registry hive

 REQUIRED INPUTS

   All inputs are hardcoded in the script body:
     - $cleanDefaultProfile : Also clean Default User profile (default: true)

 SETTINGS

   - Registry GPO Path: HKLM:\Software\Policies\Microsoft\Windows\OneDrive
   - Registry Explorer Path: HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer

 BEHAVIOR

   1. Validates administrative privileges
   2. Removes HKLM GPO DisableFileSyncNGSC policy
   3. Removes Explorer DisableOneDriveFileSync policy
   4. Optionally cleans Default User profile policies
   5. Reports completion with next steps for installation

 PREREQUISITES

   - PowerShell 5.1 or later
   - Administrator privileges required
   - No network requirements (local operations only)

 SECURITY NOTES

   - No secrets (API keys, passwords) are used or logged
   - All actions confined to local registry

 ENDPOINTS

   - N/A (local machine only)

 EXIT CODES

   - 0 : Success - all policies removed
   - 1 : Failure - critical error (likely permission-related)

 EXAMPLE RUN

   [ INPUT VALIDATION ]
   --------------------------------------------------------------
   Computer Name      : WKSTN-FIN-01
   Username           : SYSTEM
   Admin Privileges   : Confirmed
   Clean Default User : True

   [ REMOVE BLOCKING POLICIES ]
   --------------------------------------------------------------
   Removing HKLM GPO DisableFileSyncNGSC...
   GPO policy removed

   Removing Explorer DisableOneDriveFileSync...
   Explorer policy removed

   [ DEFAULT USER PROFILE ]
   --------------------------------------------------------------
   Loading Default User registry hive...
   Hive loaded successfully
   Default User profile cleaned
   Hive unloaded successfully

   [ FINAL STATUS ]
   --------------------------------------------------------------
   Result : SUCCESS
   OneDrive blocking policies removed

   Next steps to install OneDrive:
   - Install Microsoft 365 (includes OneDrive)
   - Or download from: https://www.microsoft.com/microsoft-365/onedrive/download
   - Or run: winget install Microsoft.OneDrive

   [ SCRIPT COMPLETED ]
   --------------------------------------------------------------

--------------------------------------------------------------------------------
 CHANGELOG
--------------------------------------------------------------------------------
 2026-01-05 v1.0.0 Initial release - reverses onedrive_remove_complete.ps1
================================================================================
#>

Set-StrictMode -Version Latest

# ============================================================================
# STATE VARIABLES
# ============================================================================

$errorOccurred = $false
$errorText     = ""

# ============================================================================
# HARDCODED INPUTS
# ============================================================================

# Also clean Default User profile
$cleanDefaultProfile = $true

# Registry paths for policy cleanup
$gpoPath      = "HKLM:\Software\Policies\Microsoft\Windows\OneDrive"
$explorerPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer"

# ============================================================================
# INPUT VALIDATION
# ============================================================================

Write-Host ""
Write-Host "[ INPUT VALIDATION ]"
Write-Host "--------------------------------------------------------------"

# Validate admin privileges
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- Script must be run with Administrator privileges"
}

if ($errorOccurred) {
    Write-Host ""
    Write-Host "[ ERROR OCCURRED ]"
    Write-Host "--------------------------------------------------------------"
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
Write-Host "Clean Default User : $cleanDefaultProfile"

# ============================================================================
# REMOVE BLOCKING POLICIES
# ============================================================================

Write-Host ""
Write-Host "[ REMOVE BLOCKING POLICIES ]"
Write-Host "--------------------------------------------------------------"

# Remove HKLM GPO - DisableFileSyncNGSC
Write-Host "Removing HKLM GPO DisableFileSyncNGSC..."
try {
    if (Test-Path $gpoPath) {
        $prop = Get-ItemProperty -Path $gpoPath -Name "DisableFileSyncNGSC" -ErrorAction SilentlyContinue
        if ($prop) {
            Remove-ItemProperty -Path $gpoPath -Name "DisableFileSyncNGSC" -Force -ErrorAction Stop
            Write-Host "GPO policy removed"
        } else {
            Write-Host "GPO policy not present - skipping"
        }

        # Remove the key entirely if empty
        $remaining = Get-ItemProperty -Path $gpoPath -ErrorAction SilentlyContinue
        $propCount = ($remaining.PSObject.Properties | Where-Object { $_.Name -notlike 'PS*' }).Count
        if ($propCount -eq 0) {
            Remove-Item -Path $gpoPath -Force -ErrorAction SilentlyContinue
            Write-Host "Empty GPO key removed"
        }
    } else {
        Write-Host "GPO key not present - skipping"
    }
} catch {
    Write-Host "GPO removal failed : $($_.Exception.Message)"
}

Write-Host ""

# Remove Explorer Policy - DisableOneDriveFileSync
Write-Host "Removing Explorer DisableOneDriveFileSync..."
try {
    if (Test-Path $explorerPath) {
        $prop = Get-ItemProperty -Path $explorerPath -Name "DisableOneDriveFileSync" -ErrorAction SilentlyContinue
        if ($prop) {
            Remove-ItemProperty -Path $explorerPath -Name "DisableOneDriveFileSync" -Force -ErrorAction Stop
            Write-Host "Explorer policy removed"
        } else {
            Write-Host "Explorer policy not present - skipping"
        }
    } else {
        Write-Host "Explorer key not present - skipping"
    }
} catch {
    Write-Host "Explorer policy removal failed : $($_.Exception.Message)"
}

# ============================================================================
# DEFAULT USER PROFILE CLEANUP
# ============================================================================

if ($cleanDefaultProfile) {
    Write-Host ""
    Write-Host "[ DEFAULT USER PROFILE ]"
    Write-Host "--------------------------------------------------------------"

    $defaultUserHive = "$env:SystemDrive\Users\Default\NTUSER.DAT"
    $tempHiveKey = "HKU\DefaultUserTemp"

    if (Test-Path $defaultUserHive) {
        Write-Host "Loading Default User registry hive..."

        try {
            # Load the Default User hive
            $loadResult = & reg.exe load $tempHiveKey $defaultUserHive 2>&1
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to load hive: $loadResult"
            }
            Write-Host "Hive loaded successfully"

            # Remove any OneDrive blocking policies from Default User
            # (There typically aren't any, but clean up just in case)
            Write-Host "Checking for OneDrive policies in Default User..."
            $defaultOneDrivePath = "$tempHiveKey\Software\Policies\Microsoft\OneDrive"
            & reg.exe delete $defaultOneDrivePath /f 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "OneDrive policies removed from Default User"
            } else {
                Write-Host "No OneDrive policies in Default User"
            }

            Write-Host "Default User profile cleaned"

            # Unload the hive
            Write-Host "Unloading Default User registry hive..."
            [gc]::Collect()
            Start-Sleep -Milliseconds 500
            $unloadResult = & reg.exe unload $tempHiveKey 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Host "Warning: Hive unload delayed (will complete on reboot)"
            } else {
                Write-Host "Hive unloaded successfully"
            }
        }
        catch {
            Write-Host "Default User cleanup failed : $($_.Exception.Message)"
            # Attempt to unload hive if it was loaded
            & reg.exe unload $tempHiveKey 2>&1 | Out-Null
        }
    } else {
        Write-Host "Default User hive not found : $defaultUserHive"
    }
} else {
    Write-Host ""
    Write-Host "[ DEFAULT USER PROFILE ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host "Skipped (cleanDefaultProfile = false)"
}

# ============================================================================
# FINAL STATUS
# ============================================================================

Write-Host ""
Write-Host "[ FINAL STATUS ]"
Write-Host "--------------------------------------------------------------"

Write-Host "Result : SUCCESS"
Write-Host "OneDrive blocking policies removed"
Write-Host ""
Write-Host "Next steps to install OneDrive:"
Write-Host "- Install Microsoft 365 (includes OneDrive)"
Write-Host "- Or download from: https://www.microsoft.com/microsoft-365/onedrive/download"
Write-Host "- Or run: winget install Microsoft.OneDrive"

Write-Host ""
Write-Host "[ SCRIPT COMPLETED ]"
Write-Host "--------------------------------------------------------------"

exit 0
