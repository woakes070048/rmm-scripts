<#
██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
================================================================================
 SCRIPT    : superops_uninstall_windows_legacy.ps1
 VERSION   : 1.0.0
================================================================================
 README
--------------------------------------------------------------------------------
 PURPOSE
   Uninstalls the legacy SuperOps agent on Windows systems using the product's
   IdentifyingNumber. This script is intended for environments where the agent
   cannot be uninstalled via standard methods or newer uninstallers.

 DATA SOURCES & PRIORITY
   1) Hardcoded IdentifyingNumber for the legacy SuperOps agent.
   2) WMI (Win32_Product class) to locate and uninstall the product.

 REQUIRED INPUTS
   - None. The IdentifyingNumber is hardcoded within the script.

 SETTINGS
   - None.

 BEHAVIOR
   - Queries WMI for products matching the hardcoded IdentifyingNumber.
   - Invokes the Uninstall method on any found product.
   - Designed for silent, unattended execution.

 PREREQUISITES
   - PowerShell 2.0 or later.
   - Administrative privileges are required to uninstall software.
   - WMI service must be running.

 SECURITY NOTES
   - This script does not handle sensitive data or credentials.
   - The IdentifyingNumber is publicly known for the SuperOps agent.

 ENDPOINTS
   - Local WMI service.

 EXIT CODES
   - 0: Success (product uninstalled or not found).
   - 1: Failure (e.g., insufficient permissions, WMI error).

 EXAMPLE OUTPUT
   [ OPERATION ]
   Attempting to uninstall SuperOps agent with IdentifyingNumber '{3BB93941-0FBF-4E6E-CFC2-01C0FA4F9301}'...
   [ FINAL STATUS ]
   SuperOps agent uninstallation completed.
--------------------------------------------------------------------------------
 CHANGELOG
--------------------------------------------------------------------------------
 v1.0.0 (2025-11-02) - Initial version, extracted from SuperOps.
#>

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# --- Helper Functions ---
function Write-Section([string]$title) {
    $bar = "=" * 62
    $padTitle = " [ $title ] "
    $left = [math]::Floor(($bar.Length - $padTitle.Length) / 2)
    $right = $bar.Length - $padTitle.Length - $left
    Write-Host ("{0}{1}{2}" -f ("=" * $left), $padTitle, ("=" * $right))
}

function Write-Log([string]$message, [string]$level = "INFO") {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "$timestamp [$level] $message"
}

# --- Main Script Body ---

Write-Section "INPUT VALIDATION"
# No inputs to validate for this script
Write-Log "No specific inputs to validate."

Write-Section "OPERATION"
Write-Log "Attempting to uninstall SuperOps agent with IdentifyingNumber '{3BB93941-0FBF-4E6E-CFC2-01C0FA4F9301}'..."
try {
    Get-WmiObject -Class Win32_Product -Filter "IdentifyingNumber='{3BB93941-0FBF-4E6E-CFC2-01C0FA4F9301}'" | ForEach-Object { $_.Uninstall() }
    Write-Log "SuperOps agent uninstallation command executed."
    $script:exitCode = 0
} catch {
    Write-Log "Error during uninstallation: $($_.Exception.Message)" "ERROR"
    $script:exitCode = 1
}

Write-Section "RESULT"
if ($script:exitCode -eq 0) {
    Write-Log "Uninstallation process completed without critical errors."
} else {
    Write-Log "Uninstallation process encountered errors." "ERROR"
}

Write-Section "FINAL STATUS"
if ($script:exitCode -eq 0) {
    Write-Log "SuperOps agent uninstallation completed."
} else {
    Write-Log "SuperOps agent uninstallation failed." "ERROR"
}

Write-Section "SCRIPT COMPLETED"
exit $script:exitCode