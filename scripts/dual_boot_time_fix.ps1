$ErrorActionPreference = 'Stop'
<#
██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
================================================================================
 SCRIPT   : Dual Boot Time Fix                                            v1.0.0
 AUTHOR   : Limehawk.io
 DATE     : January 2026
 USAGE    : .\dual_boot_time_fix.ps1
================================================================================
 FILE     : dual_boot_time_fix.ps1
 DESCRIPTION : Fixes time drift on Windows/Linux dual-boot systems
--------------------------------------------------------------------------------
 README
--------------------------------------------------------------------------------
 PURPOSE

   Configures Windows to use UTC for the hardware clock instead of local time.
   This prevents the clock from being wrong when switching between Windows and
   Linux on dual-boot systems, as Linux uses UTC by default.

 DATA SOURCES & PRIORITY

   - Registry: HKLM\System\CurrentControlSet\Control\TimeZoneInformation

 REQUIRED INPUTS

   All inputs are hardcoded in the script body:
     - No configurable inputs required

 SETTINGS

   Configuration details and default values:
     - RealTimeIsUniversal: Set to 1 (enabled)

 BEHAVIOR

   The script performs the following actions in order:
   1. Sets RealTimeIsUniversal registry value to 1
   2. Reports success or failure

 PREREQUISITES

   - PowerShell 5.1 or later
   - Administrator privileges (required for HKLM access)

 SECURITY NOTES

   - No secrets exposed in output
   - Standard Windows registry modification

 ENDPOINTS

   - Not applicable

 EXIT CODES

   0 = Success
   1 = Failure (error occurred)

 EXAMPLE RUN

   [ UTC CLOCK FIX ]
   --------------------------------------------------------------
   Setting RealTimeIsUniversal registry value...
   Enabled UTC hardware clock for dual-boot compatibility

   [ FINAL STATUS ]
   --------------------------------------------------------------
   Result : SUCCESS

   [ SCRIPT COMPLETE ]
   --------------------------------------------------------------

--------------------------------------------------------------------------------
 CHANGELOG
--------------------------------------------------------------------------------
 2026-01-08 v1.0.0 Initial release
================================================================================
#>
Set-StrictMode -Version Latest

# ==============================================================================
# UTC CLOCK FIX
# ==============================================================================

Write-Host ""
Write-Host "[ UTC CLOCK FIX ]"
Write-Host "--------------------------------------------------------------"

try {
    Write-Host "Setting RealTimeIsUniversal registry value..."

    $tzPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation'
    Set-ItemProperty -Path $tzPath -Name 'RealTimeIsUniversal' -Value 1 -Type DWord -Force

    Write-Host "Enabled UTC hardware clock for dual-boot compatibility"
}
catch {
    Write-Host ""
    Write-Host "[ ERROR OCCURRED ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host "Failed to set UTC clock registry key"
    Write-Host "This script requires administrator privileges"
    Write-Host "Error : $($_.Exception.Message)"
    exit 1
}

# ==============================================================================
# FINAL STATUS
# ==============================================================================

Write-Host ""
Write-Host "[ FINAL STATUS ]"
Write-Host "--------------------------------------------------------------"
Write-Host "Result : SUCCESS"

Write-Host ""
Write-Host "[ SCRIPT COMPLETE ]"
Write-Host "--------------------------------------------------------------"

exit 0
