$ErrorActionPreference = 'Stop'
<#
██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
================================================================================
 SCRIPT   : Outlook Link Handling Fix                                    v1.0.0
 AUTHOR   : Limehawk.io
 DATE     : January 2026
 USAGE    : .\outlook_link_handling_fix.ps1
================================================================================
 FILE     : outlook_link_handling_fix.ps1
 DESCRIPTION : Configures Outlook to open hyperlinks in the default browser
--------------------------------------------------------------------------------
 README
--------------------------------------------------------------------------------
 PURPOSE

   Fixes an issue where clicking shared file links (OneDrive, SharePoint) in
   Outlook incorrectly launches Outlook Classic instead of opening in the
   default web browser. Sets the documented Office link handling registry
   values to use the system default browser.

 DATA SOURCES & PRIORITY

   - Registry: HKCU:\Software\Microsoft\Office\16.0\Common\Links
   - Sets BrowserChoice and DecisionComplete values

 REQUIRED INPUTS

   All inputs are hardcoded in the script body:
     - $registryPath: Office 16.0 Common Links registry path
     - $browserChoice: 1 for Default Browser, 0 for Microsoft Edge
     - $decisionComplete: 1 to indicate user preference is set

 SETTINGS

   Default configuration:
     - BrowserChoice     : 1 (Default Browser)
     - DecisionComplete  : 1 (Preference confirmed)

 BEHAVIOR

   The script performs the following actions in order:
   1. Checks if the Office Links registry path exists
   2. Creates the registry path if missing
   3. Sets BrowserChoice to 1 (Default Browser)
   4. Sets DecisionComplete to 1 (locks in the preference)
   5. Reports success and reminds user to restart Outlook

 PREREQUISITES

   - PowerShell 5.1 or later
   - No administrator privileges required (HKCU is user-writable)
   - Microsoft Office 2016 or later (Office 16.0)

 SECURITY NOTES

   - No secrets exposed in output
   - Modifies only user-specific registry (HKCU)
   - Does not affect system-wide settings

 ENDPOINTS

   - Not applicable (local registry modification only)

 EXIT CODES

   0 = Success
   1 = Failure (error occurred)

 EXAMPLE RUN

   [INFO] CONFIGURATION
   ==============================================================
     Registry Path    : HKCU:\Software\Microsoft\Office\16.0\Common\Links
     BrowserChoice    : 1 (Default Browser)
     DecisionComplete : 1

   [RUN] REGISTRY UPDATE
   ==============================================================
     Registry path exists
     Setting BrowserChoice to 1
     Setting DecisionComplete to 1

   [OK] FINAL STATUS
   ==============================================================
     Status : Success
     Result : Outlook will now open hyperlinks in your default browser
     Note   : Please restart Outlook for changes to take effect

   [OK] SCRIPT COMPLETED
   ==============================================================

--------------------------------------------------------------------------------
 CHANGELOG
--------------------------------------------------------------------------------
 2026-01-29 v1.0.0 Initial release using documented Office registry path
================================================================================
#>
Set-StrictMode -Version Latest

# ==============================================================================
# HARDCODED INPUTS
# ==============================================================================

$registryPath     = 'HKCU:\Software\Microsoft\Office\16.0\Common\Links'
$browserChoice    = 1  # 0 = Microsoft Edge, 1 = Default Browser
$decisionComplete = 1  # 1 = User preference is set

# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================

function Write-Section {
    param([string]$Type, [string]$Name)
    $indicators = @{ 'info'='INFO'; 'run'='RUN'; 'ok'='OK'; 'warn'='WARN'; 'error'='ERROR' }
    $label = $indicators[$Type]
    Write-Host ""
    Write-Host "[$label] $Name"
    Write-Host "=============================================================="
}

# ==============================================================================
# MAIN SCRIPT
# ==============================================================================

try {
    Write-Section 'info' 'CONFIGURATION'
    Write-Host "  Registry Path    : $registryPath"
    Write-Host "  BrowserChoice    : $browserChoice (Default Browser)"
    Write-Host "  DecisionComplete : $decisionComplete"

    Write-Section 'run' 'REGISTRY UPDATE'

    if (Test-Path $registryPath) {
        Write-Host "  Registry path exists"
    } else {
        Write-Host "  Creating registry path..."
        New-Item -Path $registryPath -Force | Out-Null
        Write-Host "  Registry path created"
    }

    Write-Host "  Setting BrowserChoice to $browserChoice"
    Set-ItemProperty -Path $registryPath -Name 'BrowserChoice' -Value $browserChoice -Type DWord

    Write-Host "  Setting DecisionComplete to $decisionComplete"
    Set-ItemProperty -Path $registryPath -Name 'DecisionComplete' -Value $decisionComplete -Type DWord

    Write-Section 'ok' 'FINAL STATUS'
    Write-Host "  Status : Success"
    Write-Host "  Result : Outlook will now open hyperlinks in your default browser"
    Write-Host "  Note   : Please restart Outlook for changes to take effect"

    Write-Section 'ok' 'SCRIPT COMPLETED'
    exit 0

} catch {
    Write-Section 'error' 'ERROR OCCURRED'
    Write-Host "  What Failed : Registry update"
    Write-Host "  Error       : $($_.Exception.Message)"
    Write-Host ""
    Write-Host "  Troubleshooting:"
    Write-Host "    - Ensure Office 2016 or later is installed"
    Write-Host "    - Check if registry permissions allow HKCU writes"

    Write-Section 'error' 'FINAL STATUS'
    Write-Host "  Status : Failed"

    exit 1
}
