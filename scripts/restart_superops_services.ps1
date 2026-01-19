$ErrorActionPreference = 'Stop'
<#
██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
================================================================================
 SCRIPT   : Restart SuperOps Services                                    v2.0.0
 AUTHOR   : Limehawk.io
 DATE     : January 2026
 USAGE    : .\restart_superops_services.ps1
================================================================================
 FILE     : restart_superops_services.ps1
 DESCRIPTION : Restarts RMM agent services with automatic RMM execution detection
--------------------------------------------------------------------------------
 README
--------------------------------------------------------------------------------
PURPOSE

Restarts RMM agent services on Windows systems. Automatically detects if the
script is being executed by the RMM agent itself and uses a safe background
restart approach to avoid terminating mid-execution.

--------------------------------------------------------------------------------
DATA SOURCES & PRIORITY

1. Windows Service Control Manager (Get-Service / Restart-Service)
2. Process tree analysis for RMM execution detection

--------------------------------------------------------------------------------
REQUIRED INPUTS

All inputs are hardcoded in the script body:
  - $serviceFilter : Service name filter for fuzzy matching (e.g., "limehawk")
    Converted to wildcard pattern "*filter*" for service discovery

--------------------------------------------------------------------------------
SETTINGS

- Fuzzy matching: Filter "limehawk" matches services like "LimehawkAgent"
- RMM detection: Checks parent process tree for Limehawk/SuperOps processes
- Background restart: 2-second delay when running from RMM agent
- Direct restart: Immediate synchronous restart when run manually

--------------------------------------------------------------------------------
BEHAVIOR

1. Validates administrator privileges (required for service management)
2. Detects if script is running from SuperOps/Limehawk RMM agent
3. Finds all services matching the wildcard pattern
4. If running from RMM:
   - Spawns a detached background process to restart services after delay
   - Exits immediately (avoids being killed mid-execution)
5. If running manually:
   - Restarts services directly and waits for completion
   - Reports status of each service after restart

--------------------------------------------------------------------------------
PREREQUISITES

- Windows PowerShell 5.1 or later
- Administrator privileges (required for service management)
- Target RMM agent installed (matching services must exist)

--------------------------------------------------------------------------------
SECURITY NOTES

- No secrets in logs
- Only affects services matching the configured filter
- Process tree inspection is read-only

--------------------------------------------------------------------------------
ENDPOINTS

N/A - local service management only

--------------------------------------------------------------------------------
EXIT CODES

0 = Success - Services restarted or restart scheduled
1 = Failure - Missing admin privileges, no services found, or restart failed

--------------------------------------------------------------------------------
EXAMPLE RUN (Manual Execution)

[ INPUT VALIDATION ]
--------------------------------------------------------------
Service Filter   : limehawk
Wildcard Pattern : *limehawk*

[ ENVIRONMENT DETECTION ]
--------------------------------------------------------------
Running as Administrator : True
Running from RMM Agent   : False
Restart Mode             : Direct (synchronous)

[ RESTART SERVICES ]
--------------------------------------------------------------
Finding services matching: *limehawk*
Found 2 service(s)
  - LimehawkAgent (Running)
  - LimehawkUpdater (Running)

Restarting services directly...
  - LimehawkAgent : Restarted (Running)
  - LimehawkUpdater : Restarted (Running)

[ RESULT ]
--------------------------------------------------------------
Status             : Success
Services Found     : 2
Services Restarted : 2

[ FINAL STATUS ]
--------------------------------------------------------------
All services restarted successfully

[ SCRIPT COMPLETED ]
--------------------------------------------------------------

--------------------------------------------------------------------------------
EXAMPLE RUN (RMM Execution)

[ INPUT VALIDATION ]
--------------------------------------------------------------
Service Filter   : limehawk
Wildcard Pattern : *limehawk*

[ ENVIRONMENT DETECTION ]
--------------------------------------------------------------
Running as Administrator : True
Running from RMM Agent   : True
Restart Mode             : Background (scheduled)

[ RESTART SERVICES ]
--------------------------------------------------------------
Finding services matching: *limehawk*
Found 2 service(s)
  - LimehawkAgent (Running)
  - LimehawkUpdater (Running)

Scheduling background restart in 2 seconds...
Restart command issued successfully

[ RESULT ]
--------------------------------------------------------------
Status         : Success
Services Found : 2
Restart Mode   : Scheduled (background)

[ FINAL STATUS ]
--------------------------------------------------------------
Service restart scheduled - will execute after script exits

[ SCRIPT COMPLETED ]
--------------------------------------------------------------

--------------------------------------------------------------------------------
 CHANGELOG
--------------------------------------------------------------------------------
 2026-01-18 v2.0.0 Merged scripts, added RMM detection and runtime variable
 2026-01-14 v1.0.2 Fixed header formatting for framework compliance
 2025-12-23 v1.0.1 Updated to Limehawk Script Framework
 2024-12-23 v1.0.0 Initial release - Restart SuperOps/Limehawk services
================================================================================
#>

Set-StrictMode -Version Latest

# ==============================================================================
# STATE VARIABLES
# ==============================================================================

$errorOccurred     = $false
$errorText         = ""
$servicesFound     = 0
$servicesRestarted = 0
$runningFromRMM    = $false

# ==============================================================================
# HARDCODED INPUTS
# ==============================================================================

$serviceFilter = "$YourServiceFilterHere"

# ==============================================================================
# FUNCTIONS
# ==============================================================================

function Test-RunningFromRMM {
    <#
    .SYNOPSIS
    Detects if the script is running from SuperOps/Limehawk RMM agent
    #>
    $currentPID = $PID
    while ($currentPID -and $currentPID -ne 0) {
        $proc = Get-CimInstance Win32_Process -Filter "ProcessId = $currentPID" -ErrorAction SilentlyContinue
        if ($null -eq $proc) { break }
        if ($proc.Name -match 'Limehawk|SuperOps') { return $true }
        $currentPID = $proc.ParentProcessId
    }
    return $false
}

# ==============================================================================
# INPUT VALIDATION
# ==============================================================================

Write-Host ""
Write-Host "[ INPUT VALIDATION ]"
Write-Host "--------------------------------------------------------------"

if ([string]::IsNullOrWhiteSpace($serviceFilter) -or $serviceFilter -eq '$' + 'YourServiceFilterHere') {
    $errorOccurred = $true
    $errorText = "- SuperOps runtime variable `$YourServiceFilterHere was not replaced."
}

if ($errorOccurred) {
    Write-Host "Service Filter : (not set)"
    Write-Host ""
    Write-Host "[ ERROR OCCURRED ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host $errorText
    Write-Host ""
    Write-Host "[ FINAL STATUS ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host "Script cannot proceed. Configure the runtime variable in SuperOps."
    Write-Host ""
    Write-Host "[ SCRIPT COMPLETED ]"
    Write-Host "--------------------------------------------------------------"
    exit 1
}

$wildcardPattern = "*$serviceFilter*"
Write-Host "Service Filter   : $serviceFilter"
Write-Host "Wildcard Pattern : $wildcardPattern"

# ==============================================================================
# ENVIRONMENT DETECTION
# ==============================================================================

Write-Host ""
Write-Host "[ ENVIRONMENT DETECTION ]"
Write-Host "--------------------------------------------------------------"

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
Write-Host "Running as Administrator : $isAdmin"

if (-not $isAdmin) {
    Write-Host ""
    Write-Host "[ ERROR OCCURRED ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host "This script requires administrator privileges."
    Write-Host "Please run PowerShell as Administrator and try again."
    Write-Host ""
    Write-Host "[ FINAL STATUS ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host "Script cannot proceed without admin privileges."
    Write-Host ""
    Write-Host "[ SCRIPT COMPLETED ]"
    Write-Host "--------------------------------------------------------------"
    exit 1
}

$runningFromRMM = Test-RunningFromRMM
Write-Host "Running from RMM Agent   : $runningFromRMM"

if ($runningFromRMM) {
    Write-Host "Restart Mode             : Background (scheduled)"
} else {
    Write-Host "Restart Mode             : Direct (synchronous)"
}

# ==============================================================================
# RESTART SERVICES
# ==============================================================================

Write-Host ""
Write-Host "[ RESTART SERVICES ]"
Write-Host "--------------------------------------------------------------"

Write-Host "Finding services matching: $wildcardPattern"

try {
    $services = Get-Service -Name $wildcardPattern -ErrorAction SilentlyContinue

    if ($null -eq $services) {
        Write-Host ""
        Write-Host "[ ERROR OCCURRED ]"
        Write-Host "--------------------------------------------------------------"
        Write-Host "No services found matching pattern: $wildcardPattern"
        Write-Host "Possible causes:"
        Write-Host "  - RMM agent is not installed"
        Write-Host "  - Service filter '$serviceFilter' does not match any services"
        Write-Host "  - Services have been uninstalled"
        Write-Host ""
        Write-Host "[ FINAL STATUS ]"
        Write-Host "--------------------------------------------------------------"
        Write-Host "No services to restart."
        Write-Host ""
        Write-Host "[ SCRIPT COMPLETED ]"
        Write-Host "--------------------------------------------------------------"
        exit 1
    }

    # Ensure services is an array
    $services = @($services)
    $servicesFound = $services.Count

    Write-Host "Found $servicesFound service(s)"
    foreach ($svc in $services) {
        Write-Host "  - $($svc.Name) ($($svc.Status))"
    }
    Write-Host ""

    if ($runningFromRMM) {
        # Background restart approach - spawn detached process
        Write-Host "Scheduling background restart in 2 seconds..."

        $serviceNames = ($services | ForEach-Object { $_.Name }) -join "','"
        $restartCommand = "Start-Sleep -Seconds 2; @('$serviceNames') | ForEach-Object { Restart-Service -Name `$_ -Force }"

        Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", $restartCommand -WindowStyle Hidden

        Write-Host "Restart command issued successfully"
        $servicesRestarted = $servicesFound
    } else {
        # Direct restart - synchronous
        Write-Host "Restarting services directly..."

        foreach ($svc in $services) {
            try {
                Restart-Service -Name $svc.Name -Force -ErrorAction Stop
                $restartedSvc = Get-Service -Name $svc.Name -ErrorAction Stop
                Write-Host "  - $($svc.Name) : Restarted ($($restartedSvc.Status))"
                $servicesRestarted++
            } catch {
                $errorOccurred = $true
                if ($errorText.Length -gt 0) { $errorText += "`n" }
                $errorText += "- Failed to restart $($svc.Name): $($_.Exception.Message)"
            }
        }
    }

} catch {
    $errorOccurred = $true
    $errorText = $_.Exception.Message
}

# ==============================================================================
# ERROR HANDLING
# ==============================================================================

if ($errorOccurred) {
    Write-Host ""
    Write-Host "[ ERROR OCCURRED ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host $errorText
}

# ==============================================================================
# RESULT
# ==============================================================================

Write-Host ""
Write-Host "[ RESULT ]"
Write-Host "--------------------------------------------------------------"

if ($errorOccurred) {
    Write-Host "Status             : Failure"
} else {
    Write-Host "Status             : Success"
}
Write-Host "Services Found     : $servicesFound"

if ($runningFromRMM) {
    Write-Host "Restart Mode       : Scheduled (background)"
} else {
    Write-Host "Services Restarted : $servicesRestarted"
}

# ==============================================================================
# FINAL STATUS
# ==============================================================================

Write-Host ""
Write-Host "[ FINAL STATUS ]"
Write-Host "--------------------------------------------------------------"

if ($errorOccurred) {
    Write-Host "Some services failed to restart. See error details above."
} elseif ($runningFromRMM) {
    Write-Host "Service restart scheduled - will execute after script exits"
} else {
    Write-Host "All services restarted successfully"
}

Write-Host ""
Write-Host "[ SCRIPT COMPLETED ]"
Write-Host "--------------------------------------------------------------"

if ($errorOccurred) {
    exit 1
} else {
    exit 0
}
