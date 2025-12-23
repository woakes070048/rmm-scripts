$ErrorActionPreference = 'Stop'
<#
██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝

================================================================================
SCRIPT : Restart SuperOps Services                                    v1.0.0
FILE   : restart_superops_services.ps1
================================================================================
README
--------------------------------------------------------------------------------
PURPOSE

Restarts all SuperOps (Limehawk) services on the local machine to resolve
agent connectivity or performance issues.

--------------------------------------------------------------------------------
DATA SOURCES & PRIORITY

1. Local Windows Service Control Manager

--------------------------------------------------------------------------------
REQUIRED INPUTS

None - this script has no configurable inputs.

--------------------------------------------------------------------------------
SETTINGS

No configurable settings. Script restarts all matching services.

--------------------------------------------------------------------------------
BEHAVIOR

1. Verifies script is running with administrator privileges
2. Finds all services matching "Limehawk*" pattern
3. Spawns a background job to restart services after a short delay
4. Exits immediately (script will not wait for restart completion)

Note: Since this script is run by SuperOps, restarting the services would
terminate the script mid-execution. The background job approach ensures the
restart command is issued before the script process is killed.

--------------------------------------------------------------------------------
PREREQUISITES

- Windows PowerShell 5.1 or later
- Administrator privileges (required for service management)
- SuperOps agent installed (Limehawk services present)

--------------------------------------------------------------------------------
SECURITY NOTES

- No secrets in logs
- Only affects Limehawk-prefixed services

--------------------------------------------------------------------------------
EXIT CODES

0 = Success - Restart command issued
1 = Failure - Missing admin privileges or no services found

--------------------------------------------------------------------------------
EXAMPLE RUN

[ ADMIN CHECK ]
--------------------------------------------------------------
Running as Administrator : True

[ RESTART SERVICES ]
--------------------------------------------------------------
Finding Limehawk services...
Found 2 service(s)
  - LimehawkAgent
  - LimehawkUpdater

Scheduling restart in background...
Restart command issued

[ SCRIPT COMPLETED ]
--------------------------------------------------------------

================================================================================
CHANGELOG
--------------------------------------------------------------------------------
2024-12-23 v1.0.0  Initial release - Restart SuperOps/Limehawk services
================================================================================
#>

Set-StrictMode -Version Latest

# ==============================================================================
# ADMIN CHECK
# ==============================================================================

Write-Host ""
Write-Host "[ ADMIN CHECK ]"
Write-Host "--------------------------------------------------------------"

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
Write-Host "Running as Administrator : $isAdmin"

if (-not $isAdmin) {
    Write-Host ""
    Write-Host "[ ERROR OCCURRED ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host "This script requires administrator privileges."
    Write-Host "Please run PowerShell as Administrator and try again."
    exit 1
}

# ==============================================================================
# RESTART SERVICES
# ==============================================================================

Write-Host ""
Write-Host "[ RESTART SERVICES ]"
Write-Host "--------------------------------------------------------------"

Write-Host "Finding Limehawk services..."
$services = Get-Service -Name "Limehawk*" -ErrorAction SilentlyContinue

if (-not $services) {
    Write-Host ""
    Write-Host "[ ERROR OCCURRED ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host "No Limehawk services found on this machine."
    Write-Host "Verify that SuperOps agent is installed."
    exit 1
}

$serviceCount = @($services).Count
Write-Host "Found $serviceCount service(s)"
foreach ($service in $services) {
    Write-Host "  - $($service.Name)"
}
Write-Host ""

# Use Start-Process to spawn a detached process that restarts services
# This ensures the restart happens even if this script is terminated
Write-Host "Scheduling restart in background..."

$restartCommand = "Start-Sleep -Seconds 2; Get-Service -Name 'Limehawk*' | Restart-Service -Force"
Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", $restartCommand -WindowStyle Hidden

Write-Host "Restart command issued"

Write-Host ""
Write-Host "[ SCRIPT COMPLETED ]"
Write-Host "--------------------------------------------------------------"

exit 0
