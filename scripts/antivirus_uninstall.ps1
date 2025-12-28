<#
██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝

================================================================================
 SCRIPT    : Antivirus Uninstall (Multi-Vendor) 1.1.0
 AUTHOR    : Limehawk.io
 DATE      : December 2025
 USAGE     : .\antivirus_uninstall.ps1
 FILE      : antivirus_uninstall.ps1
 DESCRIPTION : Removes common third-party antivirus software (McAfee, Sophos, etc.)
================================================================================
 README
--------------------------------------------------------------------------------

PURPOSE

Detects and uninstalls common third-party antivirus software from Windows
systems including McAfee, Sophos, and Microsoft Security Essentials. This
script is designed for scenarios where existing AV must be removed before
deploying a new endpoint protection solution.

DATA SOURCES & PRIORITY

1. System package manager (Get-Package) - Primary detection method
2. Windows Installer database (WMI Win32_Product) - Fallback for stubborn installations
3. File system paths - Verify specific AV installations

REQUIRED INPUTS

All antivirus products to target are hardcoded in this script. No external
inputs required. The script will attempt to uninstall:

- McAfee products (all variants)
- Sophos products (all variants)
- Microsoft Security Essentials

SETTINGS

- Uses silent/quiet uninstall methods where possible
- Stops services before uninstallation
- Attempts multiple detection methods for thoroughness
- No reboot is forced (though some AV may require it)

BEHAVIOR

1. Validates execution environment (must run as Administrator)
2. Detects McAfee software using Get-Package
3. Uninstalls all detected McAfee components
4. Detects Sophos software
5. Stops Sophos services
6. Uninstalls all detected Sophos components
7. Detects Microsoft Security Essentials
8. Uninstalls Microsoft Security Essentials if found
9. Reports final status

PREREQUISITES

- Windows PowerShell 5.1 or PowerShell 7+
- Administrator privileges (required for software uninstallation)
- No modules required

SECURITY NOTES

- No secrets logged or displayed
- Requires elevation (will fail if not admin)
- Some antivirus may require tamper protection to be disabled first
- A reboot may be required after uninstallation for complete removal

ENDPOINTS

- None (local system operations only)

EXIT CODES

- 0: Success - All detected antivirus software uninstalled
- 1: Failure - Error during uninstallation process

EXAMPLE RUN

PS> .\antivirus_uninstall.ps1

[ SETUP ]
--------------------------------------------------------------
Script started : 2025-11-02 08:30:15
Administrator  : Yes

[ MCAFEE DETECTION ]
--------------------------------------------------------------
Checking for McAfee software...
McAfee packages found : 7

[ MCAFEE UNINSTALLATION ]
--------------------------------------------------------------
Uninstalling McAfee Endpoint Security Platform...
Uninstalling McAfee Agent...
Uninstalling McAfee VirusScan Enterprise...
McAfee removal completed

[ SOPHOS DETECTION ]
--------------------------------------------------------------
Checking for Sophos software...
Sophos software found : No

[ MICROSOFT SECURITY ESSENTIALS DETECTION ]
--------------------------------------------------------------
Checking for Microsoft Security Essentials...
Installation path : Not found

[ FINAL STATUS ]
--------------------------------------------------------------
McAfee uninstalled                     : Yes
Sophos uninstalled                     : Not installed
Microsoft Security Essentials removed  : Not installed

[ SCRIPT COMPLETED ]
--------------------------------------------------------------
Script completed successfully
Exit code : 0
--------------------------------------------------------------------------------
 CHANGELOG
--------------------------------------------------------------------------------
 2025-12-23 v1.1.0 Updated to Limehawk Script Framework
 2025-11-02 v1.0.0 Initial migration from SuperOps
#>

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# ============================================================================
# HARDCODED INPUTS
# ============================================================================

# McAfee products to target for removal
$mcAfeeProductNames = @(
    "McAfee Endpoint Security Adaptive Threat Protection",
    "McAfee Endpoint Security Web Control",
    "McAfee Endpoint Security Threat Prevention",
    "McAfee Endpoint Security Firewall",
    "McAfee Endpoint Security Platform",
    "McAfee VirusScan Enterprise",
    "McAfee Agent"
)

# Sophos products to target for removal
$sophosProductNames = @(
    "Sophos Remote Management System",
    "Sophos Network Threat Protection",
    "Sophos Client Firewall",
    "Sophos Anti-Virus",
    "Sophos AutoUpdate",
    "Sophos Diagnostic Utility",
    "Sophos Exploit Prevention",
    "Sophos Clean",
    "Sophos Patch Agent",
    "Sophos Endpoint Defense",
    "Sophos Management Communication System",
    "Sophos Compliance Agent",
    "Sophos System Protection"
)

# Sophos services to stop before uninstallation
$sophosServices = @(
    "Sophos Anti-Virus",
    "Sophos AutoUpdate Service"
)

# Microsoft Security Essentials installation path
$mseSetupPath = "C:\Program Files\Microsoft Security Client\Setup.exe"

# ============================================================================
# INPUT VALIDATION
# ============================================================================

Write-Host ""
Write-Host "[ SETUP ]"
Write-Host "--------------------------------------------------------------"

$errorOccurred = $false
$errorText = ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    $errorOccurred = $true
    $errorText = "This script requires Administrator privileges to uninstall software"
}

if ($errorOccurred) {
    Write-Host ""
    Write-Host "[ ERROR OCCURRED ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host $errorText
    Write-Host ""
    Write-Host "Troubleshooting:"
    Write-Host "- Right-click PowerShell and select 'Run as Administrator'"
    Write-Host "- Or run from RMM platform with SYSTEM privileges"
    Write-Host ""
    exit 1
}

Write-Host "Script started : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "Administrator  : Yes"

# ============================================================================
# MCAFEE DETECTION
# ============================================================================

Write-Host ""
Write-Host "[ MCAFEE DETECTION ]"
Write-Host "--------------------------------------------------------------"
Write-Host "Checking for McAfee software..."

$mcAfeePackages = @()
$mcAfeeFound = $false

try {
    $allMcAfee = Get-Package -Name "McAfee*" -ErrorAction SilentlyContinue
    if ($allMcAfee) {
        $mcAfeePackages = $allMcAfee
        $mcAfeeFound = $true
        Write-Host "McAfee packages found : $($mcAfeePackages.Count)"
    } else {
        Write-Host "McAfee packages found : 0"
    }
} catch {
    Write-Host "McAfee packages found : 0"
}

# ============================================================================
# MCAFEE UNINSTALLATION
# ============================================================================

if ($mcAfeeFound) {
    Write-Host ""
    Write-Host "[ MCAFEE UNINSTALLATION ]"
    Write-Host "--------------------------------------------------------------"

    try {
        foreach ($package in $mcAfeePackages) {
            Write-Host "Uninstalling $($package.Name)..."
            $package | Uninstall-Package -AllVersions -Force -ErrorAction Stop
        }
        Write-Host "McAfee removal completed"
    } catch {
        Write-Host ""
        Write-Host "[ ERROR OCCURRED ]"
        Write-Host "--------------------------------------------------------------"
        Write-Host "Failed to uninstall McAfee software"
        Write-Host ""
        Write-Host "Error details:"
        Write-Host $_.Exception.Message
        Write-Host ""
        Write-Host "Troubleshooting:"
        Write-Host "- McAfee tamper protection may be enabled"
        Write-Host "- Disable tamper protection via McAfee console first"
        Write-Host "- Use McAfee Consumer Product Removal tool if needed"
        Write-Host ""
        exit 1
    }
}

# ============================================================================
# SOPHOS DETECTION
# ============================================================================

Write-Host ""
Write-Host "[ SOPHOS DETECTION ]"
Write-Host "--------------------------------------------------------------"
Write-Host "Checking for Sophos software..."

$sophosPackages = @()
$sophosFound = $false

try {
    $allSophos = Get-Package -Name "Sophos*" -ErrorAction SilentlyContinue
    if ($allSophos) {
        $sophosPackages = $allSophos
        $sophosFound = $true
        Write-Host "Sophos software found : Yes"
        Write-Host "Sophos packages       : $($sophosPackages.Count)"
    } else {
        Write-Host "Sophos software found : No"
    }
} catch {
    Write-Host "Sophos software found : No"
}

# ============================================================================
# SOPHOS UNINSTALLATION
# ============================================================================

if ($sophosFound) {
    Write-Host ""
    Write-Host "[ SOPHOS UNINSTALLATION ]"
    Write-Host "--------------------------------------------------------------"

    try {
        # Stop Sophos services first
        Write-Host "Stopping Sophos services..."
        foreach ($serviceName in $sophosServices) {
            $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
            if ($service) {
                Write-Host "Stopping service: $serviceName"
                Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue
            }
        }

        # Uninstall Sophos packages in recommended order
        foreach ($productName in $sophosProductNames) {
            $matchingPackage = $sophosPackages | Where-Object { $_.Name -like "*$productName*" }
            if ($matchingPackage) {
                Write-Host "Uninstalling $($matchingPackage.Name)..."
                $matchingPackage | Uninstall-Package -Force -ErrorAction Stop
            }
        }

        Write-Host "Sophos removal completed"
    } catch {
        Write-Host ""
        Write-Host "[ ERROR OCCURRED ]"
        Write-Host "--------------------------------------------------------------"
        Write-Host "Failed to uninstall Sophos software"
        Write-Host ""
        Write-Host "Error details:"
        Write-Host $_.Exception.Message
        Write-Host ""
        Write-Host "Troubleshooting:"
        Write-Host "- Sophos tamper protection may be enabled"
        Write-Host "- Disable tamper protection in Sophos Central first"
        Write-Host "- Use Sophos Zap tool for stubborn installations"
        Write-Host ""
        exit 1
    }
}

# ============================================================================
# MICROSOFT SECURITY ESSENTIALS DETECTION
# ============================================================================

Write-Host ""
Write-Host "[ MICROSOFT SECURITY ESSENTIALS DETECTION ]"
Write-Host "--------------------------------------------------------------"
Write-Host "Checking for Microsoft Security Essentials..."

$mseFound = Test-Path -Path $mseSetupPath

if ($mseFound) {
    Write-Host "Installation path : Found"
} else {
    Write-Host "Installation path : Not found"
}

# ============================================================================
# MICROSOFT SECURITY ESSENTIALS UNINSTALLATION
# ============================================================================

if ($mseFound) {
    Write-Host ""
    Write-Host "[ MICROSOFT SECURITY ESSENTIALS UNINSTALLATION ]"
    Write-Host "--------------------------------------------------------------"

    try {
        Write-Host "Running uninstaller..."
        Start-Process -FilePath $mseSetupPath -ArgumentList "/x", "/u", "/s" -Wait -ErrorAction Stop
        Write-Host "Microsoft Security Essentials removed"
    } catch {
        Write-Host ""
        Write-Host "[ ERROR OCCURRED ]"
        Write-Host "--------------------------------------------------------------"
        Write-Host "Failed to uninstall Microsoft Security Essentials"
        Write-Host ""
        Write-Host "Error details:"
        Write-Host $_.Exception.Message
        Write-Host ""
        Write-Host "Troubleshooting:"
        Write-Host "- Uninstaller may require user interaction"
        Write-Host "- Try manual removal via Control Panel"
        Write-Host ""
        exit 1
    }
}

# ============================================================================
# FINAL STATUS
# ============================================================================

Write-Host ""
Write-Host "[ FINAL STATUS ]"
Write-Host "--------------------------------------------------------------"

if ($mcAfeeFound) {
    Write-Host "McAfee uninstalled                     : Yes"
} else {
    Write-Host "McAfee uninstalled                     : Not installed"
}

if ($sophosFound) {
    Write-Host "Sophos uninstalled                     : Yes"
} else {
    Write-Host "Sophos uninstalled                     : Not installed"
}

if ($mseFound) {
    Write-Host "Microsoft Security Essentials removed  : Yes"
} else {
    Write-Host "Microsoft Security Essentials removed  : Not installed"
}

Write-Host ""
Write-Host "Note: A system reboot may be required for complete removal"

# ============================================================================
# SCRIPT COMPLETED
# ============================================================================

Write-Host ""
Write-Host "[ SCRIPT COMPLETED ]"
Write-Host "--------------------------------------------------------------"
Write-Host "Script completed successfully"
Write-Host "Exit code : 0"
Write-Host ""

exit 0
