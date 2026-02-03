$ErrorActionPreference = 'Stop'
<#
██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
================================================================================
 SCRIPT   : Antivirus Uninstall (Multi-Vendor)                           v1.4.0
 AUTHOR   : Limehawk.io
 DATE     : February 2026
 USAGE    : .\antivirus_uninstall.ps1
================================================================================
 FILE     : antivirus_uninstall.ps1
 DESCRIPTION : Removes common third-party antivirus software (McAfee, Sophos, AVG, etc.)
--------------------------------------------------------------------------------
 README
--------------------------------------------------------------------------------
PURPOSE

Detects and uninstalls common third-party antivirus software from Windows
systems including McAfee, Sophos, AVG, and Microsoft Security Essentials. This
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
- AVG products (all variants including consumer and business)
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
6. Detects AVG software using registry, services, paths, packages, and WMI
7. Attempts AVG uninstall via multiple methods (packages, WMI, AVG Clear tool)
8. Detects and removes Microsoft Security Essentials
9. Reports final status with detection and removal details

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
- honzik.avcdn.net (optional, for AVG Clear tool download)

--------------------------------------------------------------------------------
EXIT CODES

0 = Success - All detected antivirus software processed
1 = Failure - Error during detection or uninstallation

--------------------------------------------------------------------------------
EXAMPLE RUN

[INFO] SETUP
==============================================================
  Script started : 2026-01-18 20:30:15
  Administrator  : Yes

[INFO] MCAFEE DETECTION
==============================================================
  Checking for McAfee software...
    Registry keys    : Found (HKLM:\SOFTWARE\McAfee)
    Services         : Found (2 services)
    Install paths    : Found (C:\Program Files\McAfee)
    Get-Package      : Not found
    WMI Products     : Found (3 products)
  McAfee detected    : Yes

[RUN] MCAFEE UNINSTALLATION
==============================================================
  Stopping McAfee services...
    Stopped: mfemms
    Stopped: mfefire
  Attempting WMI uninstall...
    Uninstalling: McAfee Agent
    Uninstalling: McAfee Endpoint Security Platform
  Downloading MCPR tool...
  Running MCPR tool...
  McAfee removal completed

[OK] FINAL STATUS
==============================================================
  McAfee detected                        : Yes
  McAfee removal attempted               : Yes
  Sophos detected                        : No
  AVG detected                           : No
  Microsoft Security Essentials detected : No

  Note: A system reboot is recommended for complete removal

[OK] SCRIPT COMPLETED
==============================================================

--------------------------------------------------------------------------------
 CHANGELOG
--------------------------------------------------------------------------------
 2026-02-02 v1.4.0 Added AVG antivirus detection and removal support
 2026-01-19 v1.3.1 Updated to two-line ASCII console output style
 2026-01-19 v1.3.0 Updated to corner bracket style section headers
 2026-01-18 v1.2.5 Improved MCPR log display and added verbose McAfee detection
 2026-01-18 v1.2.4 Check and display recent MCPR logs after starting
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
$avgDetected = $false
$avgRemovalAttempted = $false
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

# AVG registry paths to check
$avgRegistryPaths = @(
    "HKLM:\SOFTWARE\AVG",
    "HKLM:\SOFTWARE\WOW6432Node\AVG",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

# AVG services to look for and stop
$avgServices = @(
    "AVGSvc",         # AVG Antivirus service
    "avgwdsvc",       # AVG Watchdog service
    "AVG Antivirus"   # AVG Antivirus (display name)
)

# AVG installation paths to check
$avgPaths = @(
    "C:\Program Files\AVG",
    "C:\Program Files (x86)\AVG",
    "C:\ProgramData\AVG"
)

# AVG Clear download URL
$avgClearUrl = "https://honzik.avcdn.net/setup/avg-av/release/avg_av_clear.exe"
$avgClearPath = "$env:TEMP\avg_av_clear.exe"

# Microsoft Security Essentials installation path
$mseSetupPath = "C:\Program Files\Microsoft Security Client\Setup.exe"

# MCPR download URL
$mcprUrl = "https://download.mcafee.com/molbin/iss-loc/SupportTools/MCPR/MCPR.exe"
$mcprPath = "$env:TEMP\MCPR.exe"

# ==============================================================================
# INPUT VALIDATION
# ==============================================================================

Write-Host ""
Write-Host "[INFO] SETUP"
Write-Host "=============================================================="

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "Administrator  : No"
    Write-Host ""
    Write-Host "[ERROR] ERROR OCCURRED"
    Write-Host "=============================================================="
    Write-Host "This script requires Administrator privileges"
    Write-Host ""
    Write-Host "Troubleshooting:"
    Write-Host "- Right-click PowerShell and select 'Run as Administrator'"
    Write-Host "- Or run from RMM platform with SYSTEM privileges"
    Write-Host ""
    Write-Host "[ERROR] SCRIPT COMPLETED"
    Write-Host "=============================================================="
    exit 1
}

Write-Host "Script started : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "Administrator  : Yes"

# ==============================================================================
# MCAFEE DETECTION (Multi-Method)
# ==============================================================================

Write-Host ""
Write-Host "[INFO] MCAFEE DETECTION"
Write-Host "=============================================================="
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
    $allRegKeys = @($regKeys) + @($regKeys32) | Where-Object { $_ }
    $keyCount = $allRegKeys.Count
    Write-Host "  Registry keys    : Found ($keyCount keys)"
    foreach ($key in $allRegKeys) {
        $keyPath = $key.Name -replace 'HKEY_LOCAL_MACHINE', 'HKLM:'
        Write-Host "    - $keyPath"
    }
} else {
    # Also check uninstall keys
    $uninstallKeys = Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" -ErrorAction SilentlyContinue
    $mcAfeeUninstall = $uninstallKeys | Get-ItemProperty -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match "McAfee" }
    if ($mcAfeeUninstall) {
        $mcAfeeRegistryFound = $true
        Write-Host "  Registry keys    : Found (uninstall entries)"
        foreach ($entry in @($mcAfeeUninstall)) {
            Write-Host "    - $($entry.DisplayName)"
        }
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
    $svcCount = $mcAfeeServicesFound.Count
    Write-Host "  Services         : Found ($svcCount services)"
    foreach ($svc in $mcAfeeServicesFound) {
        $svcName = $svc.Name
        $svcStatus = $svc.Status
        Write-Host "    - $svcName ($svcStatus)"
    }
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
    $pathCount = $mcAfeePathsFound.Count
    Write-Host "  Install paths    : Found ($pathCount locations)"
    foreach ($p in $mcAfeePathsFound) {
        Write-Host "    - $p"
    }
} else {
    Write-Host "  Install paths    : Not found"
}

# Method 4: Get-Package check
try {
    $pkgs = Get-Package -Name "*McAfee*" -ErrorAction SilentlyContinue
    if ($pkgs) {
        $mcAfeePackages = @($pkgs)
        $pkgCount = $mcAfeePackages.Count
        Write-Host "  Get-Package      : Found ($pkgCount packages)"
        foreach ($pkg in $mcAfeePackages) {
            $pkgName = $pkg.Name
            $pkgVer = $pkg.Version
            Write-Host "    - $pkgName v$pkgVer"
        }
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
        $wmiCount = $mcAfeeWmiProducts.Count
        Write-Host "  WMI Products     : Found ($wmiCount products)"
        foreach ($prod in $mcAfeeWmiProducts) {
            $prodName = $prod.Name
            Write-Host "    - $prodName"
        }
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
    Write-Host "[RUN] MCAFEE UNINSTALLATION"
    Write-Host "=============================================================="
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

    # Check for recent MCPR logs
    Write-Host ""
    Write-Host "Checking for MCPR logs..."
    $mcprLogPaths = @(
        "$env:ProgramData\McAfee\MCPR",
        "$env:TEMP\McAfeeLogs",
        "$env:TEMP",
        "C:\ProgramData\McAfee\MCPR"
    )
    $mcprLogFound = $false
    foreach ($logPath in $mcprLogPaths) {
        if (Test-Path $logPath) {
            $logs = Get-ChildItem -Path $logPath -Filter "*.log" -ErrorAction SilentlyContinue |
                    Sort-Object LastWriteTime -Descending |
                    Select-Object -First 3
            if ($logs) {
                $mcprLogFound = $true
                Write-Host "  Recent logs in: $logPath"
                foreach ($log in $logs) {
                    $sizeKB = [Math]::Round($log.Length / 1KB, 1)
                    Write-Host "    - $($log.Name)"
                    Write-Host "      Modified: $($log.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')) | Size: $sizeKB KB"
                    # Try to get last few lines of log
                    try {
                        $lastLines = Get-Content -Path $log.FullName -Tail 5 -ErrorAction SilentlyContinue
                        if ($lastLines) {
                            foreach ($line in $lastLines) {
                                if ($line.Trim()) {
                                    Write-Host "      $($line.Trim().Substring(0, [Math]::Min(80, $line.Trim().Length)))"
                                }
                            }
                        }
                    } catch { }
                }
            }
        }
    }
    if (-not $mcprLogFound) {
        Write-Host "  No recent MCPR logs found (may appear after MCPR completes)"
    }

    Write-Host ""
    Write-Host "McAfee removal attempted"
}

# ==============================================================================
# SOPHOS DETECTION
# ==============================================================================

Write-Host ""
Write-Host "[INFO] SOPHOS DETECTION"
Write-Host "=============================================================="
Write-Host "Checking for Sophos software..."

$sophosPackages = @()

try {
    $allSophos = Get-Package -Name "*Sophos*" -ErrorAction SilentlyContinue
    if ($allSophos) {
        $sophosPackages = @($allSophos)
        $sophosDetected = $true
        $sophosCount = $sophosPackages.Count
        Write-Host "Sophos packages    : Found ($sophosCount packages)"
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
    $sophosSvcCount = $sophosServicesFound.Count
    Write-Host "Sophos services    : Found ($sophosSvcCount services)"
} else {
    Write-Host "Sophos services    : Not found"
}

Write-Host "Sophos detected    : $(if ($sophosDetected) { 'Yes' } else { 'No' })"

# ==============================================================================
# SOPHOS UNINSTALLATION
# ==============================================================================

if ($sophosDetected) {
    Write-Host ""
    Write-Host "[RUN] SOPHOS UNINSTALLATION"
    Write-Host "=============================================================="
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
# AVG DETECTION (Multi-Method)
# ==============================================================================

Write-Host ""
Write-Host "[INFO] AVG DETECTION"
Write-Host "=============================================================="
Write-Host "Checking for AVG software..."

$avgRegistryFound = $false
$avgServicesFound = @()
$avgPathsFound = @()
$avgPackages = @()
$avgWmiProducts = @()

# Method 1: Registry check
$regKeys = Get-ChildItem -Path "HKLM:\SOFTWARE" -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "AVG" }
$regKeys32 = Get-ChildItem -Path "HKLM:\SOFTWARE\WOW6432Node" -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "AVG" }
if ($regKeys -or $regKeys32) {
    $avgRegistryFound = $true
    $allRegKeys = @($regKeys) + @($regKeys32) | Where-Object { $_ }
    $keyCount = $allRegKeys.Count
    Write-Host "  Registry keys    : Found ($keyCount keys)"
    foreach ($key in $allRegKeys) {
        $keyPath = $key.Name -replace 'HKEY_LOCAL_MACHINE', 'HKLM:'
        Write-Host "    - $keyPath"
    }
} else {
    # Also check uninstall keys
    $uninstallKeys = Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" -ErrorAction SilentlyContinue
    $avgUninstall = $uninstallKeys | Get-ItemProperty -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match "AVG" }
    if ($avgUninstall) {
        $avgRegistryFound = $true
        Write-Host "  Registry keys    : Found (uninstall entries)"
        foreach ($entry in @($avgUninstall)) {
            Write-Host "    - $($entry.DisplayName)"
        }
    } else {
        Write-Host "  Registry keys    : Not found"
    }
}

# Method 2: Services check
foreach ($svcName in $avgServices) {
    $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
    if ($svc) {
        $avgServicesFound += $svc
    }
}
if ($avgServicesFound.Count -gt 0) {
    $svcCount = $avgServicesFound.Count
    Write-Host "  Services         : Found ($svcCount services)"
    foreach ($svc in $avgServicesFound) {
        $svcName = $svc.Name
        $svcStatus = $svc.Status
        Write-Host "    - $svcName ($svcStatus)"
    }
} else {
    Write-Host "  Services         : Not found"
}

# Method 3: Path check
foreach ($path in $avgPaths) {
    if (Test-Path -Path $path) {
        $avgPathsFound += $path
    }
}
if ($avgPathsFound.Count -gt 0) {
    $pathCount = $avgPathsFound.Count
    Write-Host "  Install paths    : Found ($pathCount locations)"
    foreach ($p in $avgPathsFound) {
        Write-Host "    - $p"
    }
} else {
    Write-Host "  Install paths    : Not found"
}

# Method 4: Get-Package check
try {
    $pkgs = Get-Package -Name "*AVG*" -ErrorAction SilentlyContinue
    if ($pkgs) {
        $avgPackages = @($pkgs)
        $pkgCount = $avgPackages.Count
        Write-Host "  Get-Package      : Found ($pkgCount packages)"
        foreach ($pkg in $avgPackages) {
            $pkgName = $pkg.Name
            $pkgVer = $pkg.Version
            Write-Host "    - $pkgName v$pkgVer"
        }
    } else {
        Write-Host "  Get-Package      : Not found"
    }
} catch {
    Write-Host "  Get-Package      : Not found"
}

# Method 5: WMI check (slower but catches more)
try {
    $wmiProducts = Get-CimInstance -ClassName Win32_Product -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "AVG" }
    if ($wmiProducts) {
        $avgWmiProducts = @($wmiProducts)
        $wmiCount = $avgWmiProducts.Count
        Write-Host "  WMI Products     : Found ($wmiCount products)"
        foreach ($prod in $avgWmiProducts) {
            $prodName = $prod.Name
            Write-Host "    - $prodName"
        }
    } else {
        Write-Host "  WMI Products     : Not found"
    }
} catch {
    Write-Host "  WMI Products     : Check failed"
}

# Determine if AVG is detected
if ($avgRegistryFound -or $avgServicesFound.Count -gt 0 -or $avgPathsFound.Count -gt 0 -or $avgPackages.Count -gt 0 -or $avgWmiProducts.Count -gt 0) {
    $avgDetected = $true
    Write-Host "AVG detected       : Yes"
} else {
    Write-Host "AVG detected       : No"
}

# ==============================================================================
# AVG UNINSTALLATION (Multi-Method)
# ==============================================================================

if ($avgDetected) {
    Write-Host ""
    Write-Host "[RUN] AVG UNINSTALLATION"
    Write-Host "=============================================================="
    $avgRemovalAttempted = $true

    # Step 1: Stop services
    if ($avgServicesFound.Count -gt 0) {
        Write-Host "Stopping AVG services..."
        foreach ($svc in $avgServicesFound) {
            try {
                Stop-Service -Name $svc.Name -Force -ErrorAction SilentlyContinue
                Write-Host "  Stopped: $($svc.Name)"
            } catch {
                Write-Host "  Failed to stop: $($svc.Name)"
            }
        }
    }

    # Step 2: Uninstall via Get-Package
    if ($avgPackages.Count -gt 0) {
        Write-Host "Uninstalling via Get-Package..."
        foreach ($pkg in $avgPackages) {
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
    if ($avgWmiProducts.Count -gt 0) {
        Write-Host "Uninstalling via WMI..."
        foreach ($product in $avgWmiProducts) {
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

    # Step 4: Download and run AVG Clear tool (with timeout)
    Write-Host "Downloading AVG Clear tool..."
    $avgClearSuccess = $false
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        # Download with timeout
        $downloadJob = Start-Job -ScriptBlock {
            param($url, $path)
            Invoke-WebRequest -Uri $url -OutFile $path -UseBasicParsing
        } -ArgumentList $avgClearUrl, $avgClearPath

        $downloadCompleted = Wait-Job -Job $downloadJob -Timeout 60
        if (-not $downloadCompleted) {
            Stop-Job -Job $downloadJob
            Remove-Job -Job $downloadJob -Force
            throw "Download timeout (60s)"
        }

        $downloadResult = Receive-Job -Job $downloadJob -ErrorAction Stop
        Remove-Job -Job $downloadJob -Force

        if (-not (Test-Path $avgClearPath)) {
            throw "Download failed - file not found"
        }

        Write-Host "  Downloaded to: $avgClearPath"
        Write-Host "Starting AVG Clear tool in background (silent mode)..."

        # Run AVG Clear in background with /silent flag
        Start-Process -FilePath $avgClearPath -ArgumentList "/silent" -ErrorAction Stop
        Write-Host "  AVG Clear started (PID will run in background)"
        Write-Host "  Note: AVG Clear may take 10+ minutes to complete"
        $avgClearSuccess = $true
    } catch {
        Write-Host "  AVG Clear failed: $($_.Exception.Message)"
    }

    if (-not $avgClearSuccess) {
        Write-Host ""
        Write-Host "  Note: AVG Clear could not be started."
        Write-Host "  Manual steps may be required:"
        Write-Host "  1. Download AVG Clear from avg.com/avg-remover"
        Write-Host "  2. Run it manually as administrator"
        Write-Host "  3. Reboot and verify removal"
        Write-Host ""
        Write-Host "  If AVG persists, self-defense module may be enabled."
        Write-Host "  Disable it in AVG settings before running uninstaller."
    }

    Write-Host ""
    Write-Host "AVG removal attempted"
}

# ==============================================================================
# MICROSOFT SECURITY ESSENTIALS DETECTION
# ==============================================================================

Write-Host ""
Write-Host "[INFO] MICROSOFT SECURITY ESSENTIALS DETECTION"
Write-Host "=============================================================="
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
    Write-Host "[RUN] MICROSOFT SECURITY ESSENTIALS UNINSTALLATION"
    Write-Host "=============================================================="
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
Write-Host "[OK] FINAL STATUS"
Write-Host "=============================================================="

Write-Host "McAfee detected                        : $(if ($mcAfeeDetected) { 'Yes' } else { 'No' })"
if ($mcAfeeDetected) {
    Write-Host "McAfee removal attempted               : $(if ($mcAfeeRemovalAttempted) { 'Yes' } else { 'No' })"
}

Write-Host "Sophos detected                        : $(if ($sophosDetected) { 'Yes' } else { 'No' })"
if ($sophosDetected) {
    Write-Host "Sophos removal attempted               : $(if ($sophosRemovalAttempted) { 'Yes' } else { 'No' })"
}

Write-Host "AVG detected                           : $(if ($avgDetected) { 'Yes' } else { 'No' })"
if ($avgDetected) {
    Write-Host "AVG removal attempted                  : $(if ($avgRemovalAttempted) { 'Yes' } else { 'No' })"
}

Write-Host "Microsoft Security Essentials detected : $(if ($mseDetected) { 'Yes' } else { 'No' })"
if ($mseDetected) {
    Write-Host "MSE removal attempted                  : $(if ($mseRemovalAttempted) { 'Yes' } else { 'No' })"
}

if ($mcAfeeDetected -or $sophosDetected -or $avgDetected -or $mseDetected) {
    Write-Host ""
    Write-Host "Note: A system reboot is recommended for complete removal"
}

# ==============================================================================
# SCRIPT COMPLETED
# ==============================================================================

Write-Host ""
Write-Host "[OK] SCRIPT COMPLETED"
Write-Host "=============================================================="

exit 0
