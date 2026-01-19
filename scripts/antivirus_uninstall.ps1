$ErrorActionPreference = 'Stop'
<#
██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
================================================================================
 SCRIPT   : Antivirus Uninstall (Multi-Vendor)                           v1.2.3
 AUTHOR   : Limehawk.io
 DATE     : January 2026
 USAGE    : .\antivirus_uninstall.ps1
================================================================================
 FILE     : antivirus_uninstall.ps1
 DESCRIPTION : Removes common third-party antivirus software (McAfee, Sophos, etc.)
--------------------------------------------------------------------------------
 README
--------------------------------------------------------------------------------
PURPOSE

Detects and uninstalls common third-party antivirus software from Windows
systems including McAfee, Sophos, and Microsoft Security Essentials. This
script is designed for scenarios where existing AV must be removed before
deploying a new endpoint protection solution.

--------------------------------------------------------------------------------
DATA SOURCES & PRIORITY

1. Registry keys - Most reliable detection method
2. Windows services - Detect running AV services
3. File system paths - Check known installation directories
4. System package manager (Get-Package) - Package-based detection
5. WMI Win32_Product - Fallback for stubborn installations

--------------------------------------------------------------------------------
REQUIRED INPUTS

All antivirus products to target are hardcoded in this script. No external
inputs required. The script will attempt to uninstall:

- McAfee products (all variants including consumer and enterprise)
- Sophos products (all variants)
- Microsoft Security Essentials

--------------------------------------------------------------------------------
SETTINGS

- Uses silent/quiet uninstall methods where possible
- Stops services before uninstallation
- Attempts multiple detection AND removal methods for thoroughness
- Downloads MCPR (McAfee Consumer Product Removal) tool if needed
- No reboot is forced (though some AV may require it)

--------------------------------------------------------------------------------
BEHAVIOR

1. Validates execution environment (must run as Administrator)
2. Detects McAfee using registry, services, paths, packages, and WMI
3. Attempts uninstall via multiple methods (packages, WMI, MCPR tool)
4. Detects Sophos software
5. Stops Sophos services and uninstalls components
6. Detects and removes Microsoft Security Essentials
7. Reports final status with detection and removal details

--------------------------------------------------------------------------------
PREREQUISITES

- Windows PowerShell 5.1 or PowerShell 7+
- Administrator privileges (required for software uninstallation)
- Internet access (optional, for downloading MCPR tool)

--------------------------------------------------------------------------------
SECURITY NOTES

- No secrets in logs
- Requires elevation (will fail if not admin)
- Some antivirus may require tamper protection to be disabled first
- A reboot may be required after uninstallation for complete removal

--------------------------------------------------------------------------------
ENDPOINTS

- download.mcafee.com (optional, for MCPR tool download)

--------------------------------------------------------------------------------
EXIT CODES

0 = Success - All detected antivirus software processed
1 = Failure - Error during detection or uninstallation

--------------------------------------------------------------------------------
EXAMPLE RUN

[ SETUP ]
--------------------------------------------------------------
Script started : 2026-01-18 20:30:15
Administrator  : Yes

[ MCAFEE DETECTION ]
--------------------------------------------------------------
Checking for McAfee software...
  Registry keys    : Found (HKLM:\SOFTWARE\McAfee)
  Services         : Found (2 services)
  Install paths    : Found (C:\Program Files\McAfee)
  Get-Package      : Not found
  WMI Products     : Found (3 products)
McAfee detected    : Yes

[ MCAFEE UNINSTALLATION ]
--------------------------------------------------------------
Stopping McAfee services...
  Stopped: mfemms
  Stopped: mfefire
Attempting WMI uninstall...
  Uninstalling: McAfee Agent
  Uninstalling: McAfee Endpoint Security Platform
Downloading MCPR tool...
Running MCPR tool...
McAfee removal completed

[ FINAL STATUS ]
--------------------------------------------------------------
McAfee detected                        : Yes
McAfee removal attempted               : Yes
Sophos detected                        : No
Microsoft Security Essentials detected : No

Note: A system reboot is recommended for complete removal

[ SCRIPT COMPLETED ]
--------------------------------------------------------------

--------------------------------------------------------------------------------
 CHANGELOG
--------------------------------------------------------------------------------
 2026-01-18 v1.2.3 Run MCPR in background instead of waiting
 2026-01-18 v1.2.2 Increased MCPR timeout from 5 to 15 minutes
 2026-01-18 v1.2.1 Added timeouts and error handling for WMI/MCPR operations
 2026-01-18 v1.2.0 Rewrote McAfee detection with registry/services/paths/WMI
 2025-12-23 v1.1.0 Updated to Limehawk Script Framework
 2025-11-02 v1.0.0 Initial migration from SuperOps
================================================================================
#>

Set-StrictMode -Version Latest

# ==============================================================================
# STATE VARIABLES
# ==============================================================================

$mcAfeeDetected = $false
$mcAfeeRemovalAttempted = $false
$sophosDetected = $false
$sophosRemovalAttempted = $false
$mseDetected = $false
$mseRemovalAttempted = $false

# ==============================================================================
# HARDCODED INPUTS
# ==============================================================================

# McAfee registry paths to check
$mcAfeeRegistryPaths = @(
    "HKLM:\SOFTWARE\McAfee",
    "HKLM:\SOFTWARE\WOW6432Node\McAfee",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

# McAfee services to look for and stop
$mcAfeeServices = @(
    "mfemms",      # McAfee Management Service
    "mfefire",     # McAfee Firewall Core Service
    "mfevtp",      # McAfee Validation Trust Protection Service
    "mcshield",    # McAfee On-Access Scanner
    "McAfeeFramework", # McAfee Framework Service
    "masvc",       # McAfee Agent Service
    "macmnsvc",    # McAfee Common Services
    "mfewc"        # McAfee Endpoint Security Web Control
)

# McAfee installation paths to check
$mcAfeePaths = @(
    "C:\Program Files\McAfee",
    "C:\Program Files (x86)\McAfee",
    "C:\Program Files\Common Files\McAfee",
    "C:\Program Files (x86)\Common Files\McAfee",
    "C:\ProgramData\McAfee"
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
    "Sophos AutoUpdate Service",
    "Sophos Endpoint Defense Service",
    "Sophos MCS Agent",
    "Sophos MCS Client"
)

# Microsoft Security Essentials installation path
$mseSetupPath = "C:\Program Files\Microsoft Security Client\Setup.exe"

# MCPR download URL
$mcprUrl = "https://download.mcafee.com/molbin/iss-loc/SupportTools/MCPR/MCPR.exe"
$mcprPath = "$env:TEMP\MCPR.exe"

# ==============================================================================
# INPUT VALIDATION
# ==============================================================================

Write-Host ""
Write-Host "[ SETUP ]"
Write-Host "--------------------------------------------------------------"

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "Administrator  : No"
    Write-Host ""
    Write-Host "[ ERROR OCCURRED ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host "This script requires Administrator privileges"
    Write-Host ""
    Write-Host "Troubleshooting:"
    Write-Host "- Right-click PowerShell and select 'Run as Administrator'"
    Write-Host "- Or run from RMM platform with SYSTEM privileges"
    Write-Host ""
    Write-Host "[ SCRIPT COMPLETED ]"
    Write-Host "--------------------------------------------------------------"
    exit 1
}

Write-Host "Script started : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "Administrator  : Yes"

# ==============================================================================
# MCAFEE DETECTION (Multi-Method)
# ==============================================================================

Write-Host ""
Write-Host "[ MCAFEE DETECTION ]"
Write-Host "--------------------------------------------------------------"
Write-Host "Checking for McAfee software..."

$mcAfeeRegistryFound = $false
$mcAfeeServicesFound = @()
$mcAfeePathsFound = @()
$mcAfeePackages = @()
$mcAfeeWmiProducts = @()

# Method 1: Registry check
$regKeys = Get-ChildItem -Path "HKLM:\SOFTWARE" -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "McAfee" }
$regKeys32 = Get-ChildItem -Path "HKLM:\SOFTWARE\WOW6432Node" -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "McAfee" }
if ($regKeys -or $regKeys32) {
    $mcAfeeRegistryFound = $true
    Write-Host "  Registry keys    : Found"
} else {
    # Also check uninstall keys
    $uninstallKeys = Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" -ErrorAction SilentlyContinue
    $mcAfeeUninstall = $uninstallKeys | Get-ItemProperty -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match "McAfee" }
    if ($mcAfeeUninstall) {
        $mcAfeeRegistryFound = $true
        Write-Host "  Registry keys    : Found (uninstall entries)"
    } else {
        Write-Host "  Registry keys    : Not found"
    }
}

# Method 2: Services check
foreach ($svcName in $mcAfeeServices) {
    $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
    if ($svc) {
        $mcAfeeServicesFound += $svc
    }
}
if ($mcAfeeServicesFound.Count -gt 0) {
    Write-Host "  Services         : Found ($($mcAfeeServicesFound.Count) services)"
} else {
    Write-Host "  Services         : Not found"
}

# Method 3: Path check
foreach ($path in $mcAfeePaths) {
    if (Test-Path -Path $path) {
        $mcAfeePathsFound += $path
    }
}
if ($mcAfeePathsFound.Count -gt 0) {
    Write-Host "  Install paths    : Found ($($mcAfeePathsFound.Count) locations)"
} else {
    Write-Host "  Install paths    : Not found"
}

# Method 4: Get-Package check
try {
    $pkgs = Get-Package -Name "*McAfee*" -ErrorAction SilentlyContinue
    if ($pkgs) {
        $mcAfeePackages = @($pkgs)
        Write-Host "  Get-Package      : Found ($($mcAfeePackages.Count) packages)"
    } else {
        Write-Host "  Get-Package      : Not found"
    }
} catch {
    Write-Host "  Get-Package      : Not found"
}

# Method 5: WMI check (slower but catches more)
try {
    $wmiProducts = Get-CimInstance -ClassName Win32_Product -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "McAfee" }
    if ($wmiProducts) {
        $mcAfeeWmiProducts = @($wmiProducts)
        Write-Host "  WMI Products     : Found ($($mcAfeeWmiProducts.Count) products)"
    } else {
        Write-Host "  WMI Products     : Not found"
    }
} catch {
    Write-Host "  WMI Products     : Check failed"
}

# Determine if McAfee is detected
if ($mcAfeeRegistryFound -or $mcAfeeServicesFound.Count -gt 0 -or $mcAfeePathsFound.Count -gt 0 -or $mcAfeePackages.Count -gt 0 -or $mcAfeeWmiProducts.Count -gt 0) {
    $mcAfeeDetected = $true
    Write-Host "McAfee detected    : Yes"
} else {
    Write-Host "McAfee detected    : No"
}

# ==============================================================================
# MCAFEE UNINSTALLATION (Multi-Method)
# ==============================================================================

if ($mcAfeeDetected) {
    Write-Host ""
    Write-Host "[ MCAFEE UNINSTALLATION ]"
    Write-Host "--------------------------------------------------------------"
    $mcAfeeRemovalAttempted = $true

    # Step 1: Stop services
    if ($mcAfeeServicesFound.Count -gt 0) {
        Write-Host "Stopping McAfee services..."
        foreach ($svc in $mcAfeeServicesFound) {
            try {
                Stop-Service -Name $svc.Name -Force -ErrorAction SilentlyContinue
                Write-Host "  Stopped: $($svc.Name)"
            } catch {
                Write-Host "  Failed to stop: $($svc.Name)"
            }
        }
    }

    # Step 2: Uninstall via Get-Package
    if ($mcAfeePackages.Count -gt 0) {
        Write-Host "Uninstalling via Get-Package..."
        foreach ($pkg in $mcAfeePackages) {
            try {
                Write-Host "  Uninstalling: $($pkg.Name)..."
                $pkg | Uninstall-Package -AllVersions -Force -ErrorAction Stop
                Write-Host "    Success"
            } catch {
                Write-Host "    Failed: $($_.Exception.Message)"
            }
        }
    }

    # Step 3: Uninstall via WMI (with timeout)
    if ($mcAfeeWmiProducts.Count -gt 0) {
        Write-Host "Uninstalling via WMI..."
        foreach ($product in $mcAfeeWmiProducts) {
            try {
                Write-Host "  Uninstalling: $($product.Name)..."
                $job = Start-Job -ScriptBlock {
                    param($prodId)
                    $p = Get-CimInstance -ClassName Win32_Product | Where-Object { $_.IdentifyingNumber -eq $prodId }
                    if ($p) { $p | Invoke-CimMethod -MethodName Uninstall }
                } -ArgumentList $product.IdentifyingNumber

                $completed = Wait-Job -Job $job -Timeout 120
                if ($completed) {
                    Remove-Job -Job $job -Force
                    Write-Host "    Success"
                } else {
                    Stop-Job -Job $job
                    Remove-Job -Job $job -Force
                    Write-Host "    Timeout (120s) - skipping"
                }
            } catch {
                Write-Host "    Failed: $($_.Exception.Message)"
            }
        }
    }

    # Step 4: Download and run MCPR tool (with timeout)
    Write-Host "Downloading MCPR (McAfee Consumer Product Removal) tool..."
    $mcprSuccess = $false
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        # Download with timeout
        $downloadJob = Start-Job -ScriptBlock {
            param($url, $path)
            Invoke-WebRequest -Uri $url -OutFile $path -UseBasicParsing
        } -ArgumentList $mcprUrl, $mcprPath

        $downloadCompleted = Wait-Job -Job $downloadJob -Timeout 60
        if (-not $downloadCompleted) {
            Stop-Job -Job $downloadJob
            Remove-Job -Job $downloadJob -Force
            throw "Download timeout (60s)"
        }

        $downloadResult = Receive-Job -Job $downloadJob -ErrorAction Stop
        Remove-Job -Job $downloadJob -Force

        if (-not (Test-Path $mcprPath)) {
            throw "Download failed - file not found"
        }

        Write-Host "  Downloaded to: $mcprPath"
        Write-Host "Starting MCPR tool in background (silent mode)..."

        # Run MCPR in background - don't wait, it can take 15+ minutes
        Start-Process -FilePath $mcprPath -ArgumentList "/silent" -ErrorAction Stop
        Write-Host "  MCPR started (PID will run in background)"
        Write-Host "  Note: MCPR may take 15+ minutes to complete"
        $mcprSuccess = $true
    } catch {
        Write-Host "  MCPR failed: $($_.Exception.Message)"
    }

    if (-not $mcprSuccess) {
        Write-Host ""
        Write-Host "  Note: MCPR could not be started."
        Write-Host "  Manual steps may be required:"
        Write-Host "  1. Download MCPR from mcafee.com"
        Write-Host "  2. Run it manually"
        Write-Host "  3. Reboot and verify removal"
    }

    Write-Host ""
    Write-Host "McAfee removal attempted"
}

# ==============================================================================
# SOPHOS DETECTION
# ==============================================================================

Write-Host ""
Write-Host "[ SOPHOS DETECTION ]"
Write-Host "--------------------------------------------------------------"
Write-Host "Checking for Sophos software..."

$sophosPackages = @()

try {
    $allSophos = Get-Package -Name "*Sophos*" -ErrorAction SilentlyContinue
    if ($allSophos) {
        $sophosPackages = @($allSophos)
        $sophosDetected = $true
        Write-Host "Sophos packages    : Found ($($sophosPackages.Count) packages)"
    } else {
        Write-Host "Sophos packages    : Not found"
    }
} catch {
    Write-Host "Sophos packages    : Not found"
}

# Also check for Sophos services
$sophosServicesFound = @()
foreach ($svcName in $sophosServices) {
    $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
    if ($svc) {
        $sophosServicesFound += $svc
        $sophosDetected = $true
    }
}
if ($sophosServicesFound.Count -gt 0) {
    Write-Host "Sophos services    : Found ($($sophosServicesFound.Count) services)"
} else {
    Write-Host "Sophos services    : Not found"
}

Write-Host "Sophos detected    : $(if ($sophosDetected) { 'Yes' } else { 'No' })"

# ==============================================================================
# SOPHOS UNINSTALLATION
# ==============================================================================

if ($sophosDetected) {
    Write-Host ""
    Write-Host "[ SOPHOS UNINSTALLATION ]"
    Write-Host "--------------------------------------------------------------"
    $sophosRemovalAttempted = $true

    # Stop Sophos services first
    if ($sophosServicesFound.Count -gt 0) {
        Write-Host "Stopping Sophos services..."
        foreach ($svc in $sophosServicesFound) {
            try {
                Stop-Service -Name $svc.Name -Force -ErrorAction SilentlyContinue
                Write-Host "  Stopped: $($svc.Name)"
            } catch {
                Write-Host "  Failed to stop: $($svc.Name)"
            }
        }
    }

    # Uninstall Sophos packages
    if ($sophosPackages.Count -gt 0) {
        Write-Host "Uninstalling Sophos packages..."
        foreach ($pkg in $sophosPackages) {
            try {
                Write-Host "  Uninstalling: $($pkg.Name)"
                $pkg | Uninstall-Package -Force -ErrorAction SilentlyContinue
            } catch {
                Write-Host "  Failed: $($pkg.Name)"
            }
        }
    }

    Write-Host "Sophos removal completed"
    Write-Host ""
    Write-Host "Note: If Sophos persists, tamper protection may be enabled"
    Write-Host "      Disable it in Sophos Central or use Sophos Zap tool"
}

# ==============================================================================
# MICROSOFT SECURITY ESSENTIALS DETECTION
# ==============================================================================

Write-Host ""
Write-Host "[ MICROSOFT SECURITY ESSENTIALS DETECTION ]"
Write-Host "--------------------------------------------------------------"
Write-Host "Checking for Microsoft Security Essentials..."

$mseDetected = Test-Path -Path $mseSetupPath

if ($mseDetected) {
    Write-Host "Installation path  : Found"
} else {
    Write-Host "Installation path  : Not found"
}
Write-Host "MSE detected       : $(if ($mseDetected) { 'Yes' } else { 'No' })"

# ==============================================================================
# MICROSOFT SECURITY ESSENTIALS UNINSTALLATION
# ==============================================================================

if ($mseDetected) {
    Write-Host ""
    Write-Host "[ MICROSOFT SECURITY ESSENTIALS UNINSTALLATION ]"
    Write-Host "--------------------------------------------------------------"
    $mseRemovalAttempted = $true

    try {
        Write-Host "Running uninstaller..."
        $mseProcess = Start-Process -FilePath $mseSetupPath -ArgumentList "/x", "/u", "/s" -Wait -PassThru -ErrorAction Stop
        Write-Host "  Exit code: $($mseProcess.ExitCode)"
        Write-Host "Microsoft Security Essentials removal completed"
    } catch {
        Write-Host "  Failed: $($_.Exception.Message)"
        Write-Host "  Note: Manual removal via Control Panel may be required"
    }
}

# ==============================================================================
# FINAL STATUS
# ==============================================================================

Write-Host ""
Write-Host "[ FINAL STATUS ]"
Write-Host "--------------------------------------------------------------"

Write-Host "McAfee detected                        : $(if ($mcAfeeDetected) { 'Yes' } else { 'No' })"
if ($mcAfeeDetected) {
    Write-Host "McAfee removal attempted               : $(if ($mcAfeeRemovalAttempted) { 'Yes' } else { 'No' })"
}

Write-Host "Sophos detected                        : $(if ($sophosDetected) { 'Yes' } else { 'No' })"
if ($sophosDetected) {
    Write-Host "Sophos removal attempted               : $(if ($sophosRemovalAttempted) { 'Yes' } else { 'No' })"
}

Write-Host "Microsoft Security Essentials detected : $(if ($mseDetected) { 'Yes' } else { 'No' })"
if ($mseDetected) {
    Write-Host "MSE removal attempted                  : $(if ($mseRemovalAttempted) { 'Yes' } else { 'No' })"
}

if ($mcAfeeDetected -or $sophosDetected -or $mseDetected) {
    Write-Host ""
    Write-Host "Note: A system reboot is recommended for complete removal"
}

# ==============================================================================
# SCRIPT COMPLETED
# ==============================================================================

Write-Host ""
Write-Host "[ SCRIPT COMPLETED ]"
Write-Host "--------------------------------------------------------------"

exit 0
