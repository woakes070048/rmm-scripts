# Import the SuperOps module (provided by RMM)
Import-Module $SuperOpsModule

$ErrorActionPreference = 'Stop'

<#
██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
================================================================================
 SCRIPT    : Antivirus Status                                             v1.4.1
 AUTHOR    : Limehawk.io
 DATE      : January 2026
 USAGE     : .\antivirus_status.ps1
================================================================================
 FILE      : antivirus_status.ps1
 DESCRIPTION : Reports third-party antivirus status to SuperOps custom fields
--------------------------------------------------------------------------------
 README
--------------------------------------------------------------------------------
 PURPOSE

   Checks for the presence and active status of third-party antivirus software
   on the system, excluding Windows/Microsoft Defender. Reports the active
   product name and boolean state to SuperOps custom fields for monitoring.

 DATA SOURCES & PRIORITY

   - Hardcoded values (defined within the script body)
   - CIM instance query to root\SecurityCenter2\AntiVirusProduct for third-party AV
   - Registry fallback if SecurityCenter2 is unavailable
   - Get-MpComputerStatus for Windows Defender confirmation (informational only)

 REQUIRED INPUTS

   All inputs are hardcoded or injected by RMM:
     - $SuperOpsModule: Path to SuperOps module (injected by RMM)

 SETTINGS

   - None configurable; all logic is fixed for third-party AV detection.

 BEHAVIOR

   The script performs the following actions in order:
   1. Validates that $SuperOpsModule is available
   2. Detects OS type (client vs server)
   3. Queries installed AV products via SecurityCenter2 or registry fallback
   4. Checks enabled state via productState bitmask
   5. Ignores Windows Defender entries
   6. Outputs third-party AV name and state (TRUE/FALSE)
   7. Confirms Windows Defender status in console output
   8. Pushes results to SuperOps custom fields

 PREREQUISITES

   - PowerShell 5.1 or later
   - Access to root\SecurityCenter2 namespace (requires local admin or equivalent)
   - SuperOps module available via $SuperOpsModule variable (provided by RMM)

 SECURITY NOTES

   - No secrets (API keys, passwords) are used or logged
   - Queries only local system data; no network calls

 ENDPOINTS

   - Not applicable

 EXIT CODES

   0 = Success
   1 = Failure (error occurred)

 EXAMPLE RUN

   [INFO] INPUT VALIDATION
   ==============================================================
     SuperOpsModule : C:\Program Files\SuperOps\Modules\SuperOps.psm1

   [RUN] AV DETECTION
   ==============================================================
     Checking OS type...
     Client OS detected
     Checking SecurityCenter service...
     Querying AntiVirusProduct via SecurityCenter2...
     SecurityCenter2 query successful
     Checking Windows Defender...

   [INFO] DIAGNOSTIC: ALL AV PRODUCTS FOUND
   ==============================================================
     Product: Windows Defender
       State: 0x001001 | Enabled: True | DefBits: 0x01
       Path: %ProgramFiles%\Windows Defender\MsMpEng.exe

     Skipping Microsoft product: Windows Defender

   [INFO] RESULT
   ==============================================================
     Active Antivirus : No Active Third-Party Antivirus Detected
     Active Antivirus State : FALSE
     Windows Defender Enabled : True
     Windows Defender RealTime : True

   [OK] FINAL STATUS
   ==============================================================
     Third-party AV check completed successfully.

   [OK] SCRIPT COMPLETED
   ==============================================================

--------------------------------------------------------------------------------
 CHANGELOG
--------------------------------------------------------------------------------
 2026-01-19 v1.4.1 Updated to two-line ASCII console output style
 2026-01-19 v1.4.0 Updated to corner bracket style section headers
 2025-12-23 v1.3.0 Updated to Limehawk Script Framework
 2025-10-28 v1.2.0 Added registry fallback, WMI service checks, better error handling
 2025-10-28 v1.1.0 Improved AV detection with productState logic, OS type checking
 2025-10-27 v1.0.0 Initial version with third-party AV focus and SuperOps integration
================================================================================
#>

Set-StrictMode -Version Latest

# ==============================================================================
# STATE (NO ARRAYS/LISTS)
# ==============================================================================
$errorOccurred = $false
$errorText     = ""   # Accumulate newline-delimited messages.

# ==============================================================================
# HARDCODED INPUTS (MANDATORY)
# ==============================================================================
# Relies on $SuperOpsModule injected by RMM.

# ==============================================================================
# VALIDATION
# ==============================================================================
if ([string]::IsNullOrWhiteSpace($SuperOpsModule)) {
    $errorOccurred = $true
    $errorText += "- SuperOpsModule path is required (injected by RMM)."
}

if ($errorOccurred) {
    Write-Host ""
    Write-Host "[ERROR] ERROR OCCURRED"
    Write-Host "=============================================================="
    Write-Host "  $errorText"
    exit 1
}

# ==============================================================================
# RUNTIME OUTPUT
# ==============================================================================
Write-Host ""
Write-Host "[INFO] INPUT VALIDATION"
Write-Host "=============================================================="
Write-Host "  SuperOpsModule : $SuperOpsModule"

Write-Host ""
Write-Host "[RUN] AV DETECTION"
Write-Host "=============================================================="

# ==============================================================================
# HELPER FUNCTION: Registry-based AV Detection
# ==============================================================================
function Get-AVFromRegistry {
    Write-Host "  Attempting registry-based AV detection..."
    $avFound = ""
    $avActive = $false

    # Common AV registry locations
    $avPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    # Known AV product patterns (excluding Microsoft)
    $avPatterns = @(
        "Norton", "Symantec", "McAfee", "Kaspersky", "Bitdefender",
        "Avast", "AVG", "Trend Micro", "ESET", "Sophos",
        "Malwarebytes", "Webroot", "F-Secure", "Panda",
        "Avira", "Comodo", "ZoneAlarm", "BullGuard", "G Data",
        "Emsisoft", "Vipre", "Sentinel", "CrowdStrike", "Carbon Black"
    )

    foreach ($path in $avPaths) {
        try {
            $installed = Get-ItemProperty $path -ErrorAction SilentlyContinue | Where-Object {
                $_.DisplayName -and $_.DisplayName -notmatch "^(Windows|Microsoft)\s+(Defender|Security)"
            }

            foreach ($app in $installed) {
                foreach ($pattern in $avPatterns) {
                    if ($app.DisplayName -match $pattern) {
                        Write-Host "    Found in registry: $($app.DisplayName)"
                        if ($avFound.Length -gt 0) { $avFound += ", " }
                        $avFound += $app.DisplayName
                        $avActive = $true
                    }
                }
            }
        } catch {
            Write-Host "    Registry path failed: $path"
        }
    }

    return @{
        Name = $avFound
        Active = $avActive
    }
}

try {
    # Check OS type first (SecurityCenter2 only exists on client OS)
    Write-Host "  Checking OS type..."
    $OSInfo = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
    $isServerOS = $OSInfo.ProductType -ne 1  # 1 = Workstation, 2 = Domain Controller, 3 = Server

    if ($isServerOS) {
        Write-Host "  Server OS detected - SecurityCenter2 namespace not available"
        Write-Host "  Attempting alternative detection methods..."

        $regResult = Get-AVFromRegistry

        if ($regResult.Active) {
            $ActiveAV = $regResult.Name
            $AVStatus = $true
        } else {
            $ActiveAV = "Server OS - No Third-Party AV Detected"
            $AVStatus = $false
        }

        # Still check Windows Defender on servers
        try {
            $DefenderStatus = Get-MpComputerStatus -ErrorAction Stop
            Write-Host "  Windows Defender Status: Enabled=$($DefenderStatus.AntivirusEnabled), RealTime=$($DefenderStatus.RealTimeProtectionEnabled)"
        } catch {
            Write-Host "  Windows Defender check failed: $($_.Exception.Message)"
            $DefenderStatus = $null
        }
    } else {
        Write-Host "  Client OS detected"

        # Check if WMI/SecurityCenter service is running
        Write-Host "  Checking SecurityCenter service..."
        $secCenter = Get-Service -Name "wscsvc" -ErrorAction SilentlyContinue
        if ($secCenter -and $secCenter.Status -ne "Running") {
            Write-Host "  WARNING: SecurityCenter service (wscsvc) is not running. Status: $($secCenter.Status)"
            Write-Host "  Attempting to start service..."
            try {
                Start-Service -Name "wscsvc" -ErrorAction Stop
                Start-Sleep -Seconds 2
                Write-Host "  Service started successfully"
            } catch {
                Write-Host "  Failed to start SecurityCenter service: $($_.Exception.Message)"
            }
        }

        # Try SecurityCenter2 query with better error handling
        $AntivirusProducts = $null
        $secCenter2Failed = $false

        Write-Host "  Querying AntiVirusProduct via SecurityCenter2..."
        try {
            # Test namespace existence first
            $null = Get-CimInstance -Namespace "root\SecurityCenter2" -ClassName "__Namespace" -ErrorAction Stop

            # Now query AV products
            $AntivirusProducts = Get-CimInstance -Namespace "root\SecurityCenter2" -ClassName "AntiVirusProduct" -ErrorAction Stop
            Write-Host "  SecurityCenter2 query successful"
        } catch {
            $secCenter2Failed = $true
            Write-Host "  SecurityCenter2 query failed: $($_.Exception.Message)"
            Write-Host "  Falling back to registry detection..."
        }

        Write-Host "  Checking Windows Defender..."
        try {
            $DefenderStatus = Get-MpComputerStatus -ErrorAction Stop
        } catch {
            Write-Host "  Windows Defender check failed: $($_.Exception.Message)"
            $DefenderStatus = $null
        }

        $ActiveAV = "No Active Third-Party Antivirus Detected"
        $AVStatus = $false  # Boolean: false for inactive third-party AV
        $activeAVNames = ""  # Accumulate comma-separated names

        # Process SecurityCenter2 results if available
        if (-not $secCenter2Failed -and $AntivirusProducts) {
            Write-Host ""
            Write-Host "[INFO] DIAGNOSTIC: ALL AV PRODUCTS FOUND"
            Write-Host "=============================================================="

            foreach ($av in $AntivirusProducts) {
                $hexState = "0x{0:X6}" -f $av.productState
                $isEnabled = ($av.productState -band 0x1000) -ne 0
                $defStatus = $av.productState -band 0x00FF

                Write-Host "  Product: $($av.displayName)"
                Write-Host "    State: $hexState | Enabled: $isEnabled | DefBits: 0x$("{0:X2}" -f $defStatus)"
                Write-Host "    Path: $($av.pathToSignedProductExe)"
                Write-Host ""
            }

            # Check for active third-party AV
            foreach ($av in $AntivirusProducts) {
                # More specific Defender exclusion using regex
                if ($av.displayName -match "^(Windows|Microsoft)\s+(Defender|Security)") {
                    Write-Host "  Skipping Microsoft product: $($av.displayName)"
                    continue
                }

                # Enhanced productState check
                $isEnabled = ($av.productState -band 0x1000) -ne 0

                if ($isEnabled) {
                    Write-Host "  ACTIVE third-party AV found: $($av.displayName)"

                    if ($activeAVNames.Length -gt 0) {
                        $activeAVNames += ", "
                    }
                    $activeAVNames += $av.displayName
                    $AVStatus = $true
                }
            }

            # Set final value
            if ($AVStatus) {
                $ActiveAV = $activeAVNames
            }
        } elseif ($secCenter2Failed) {
            # Fallback to registry if SecurityCenter2 failed
            $regResult = Get-AVFromRegistry

            if ($regResult.Active) {
                $ActiveAV = $regResult.Name
                $AVStatus = $true
                Write-Host "  Registry detection found: $ActiveAV"
            } else {
                $ActiveAV = "SecurityCenter2 Unavailable - No AV Found in Registry"
                $AVStatus = $false
            }
        } else {
            Write-Host "  No AV products found in SecurityCenter2"
        }
    }

    # Push to SuperOps custom fields (third-party focused)
    Send-CustomField -CustomFieldName "Active Antivirus" -Value $ActiveAV  # String: third-party product name or detection message
    Send-CustomField -CustomFieldName "Active Antivirus State" -Value $AVStatus.ToString().ToUpper()  # "TRUE" or "FALSE" for radio buttons
} catch {
    $errorOccurred = $true
    $ErrorMsg = "Error checking AV status: $($_.Exception.Message)"
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += $ErrorMsg

    # Push error defaults to SuperOps
    Send-CustomField -CustomFieldName "Active Antivirus" -Value "Error: Unable to detect" -ErrorAction SilentlyContinue
    Send-CustomField -CustomFieldName "Active Antivirus State" -Value "FALSE" -ErrorAction SilentlyContinue
}

if ($errorOccurred) {
    Write-Host ""
    Write-Host "[ERROR] ERROR OCCURRED"
    Write-Host "=============================================================="
    Write-Host "  $errorText"
    exit 1
}

Write-Host ""
Write-Host "[INFO] RESULT"
Write-Host "=============================================================="
Write-Host "  Active Antivirus : $ActiveAV"
Write-Host "  Active Antivirus State : $($AVStatus.ToString().ToUpper())"
if ($DefenderStatus) {
    Write-Host "  Windows Defender Enabled : $($DefenderStatus.AntivirusEnabled)"
    Write-Host "  Windows Defender RealTime : $($DefenderStatus.RealTimeProtectionEnabled)"
}

Write-Host ""
Write-Host "[OK] FINAL STATUS"
Write-Host "=============================================================="
Write-Host "  Third-party AV check completed successfully."

Write-Host ""
Write-Host "[OK] SCRIPT COMPLETED"
Write-Host "=============================================================="
exit 0
