$ErrorActionPreference = 'Stop'

<#
â–ˆâ–ˆâ•—     â–ˆâ–ˆâ•—â–ˆâ–ˆâ–ˆâ•—   â–ˆâ–ˆâ–ˆâ•—â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•—â–ˆâ–ˆâ•—  â–ˆâ–ˆâ•— â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•— â–ˆâ–ˆâ•—    â–ˆâ–ˆâ•—â–ˆâ–ˆâ•—  â–ˆâ–ˆâ•—
â–ˆâ–ˆâ•‘     â–ˆâ–ˆâ•‘â–ˆâ–ˆâ–ˆâ–ˆâ•— â–ˆâ–ˆâ–ˆâ–ˆâ•‘â–ˆâ–ˆâ•”â•â•â•â•â•â–ˆâ–ˆâ•‘  â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•”â•â•â–ˆâ–ˆâ•—â–ˆâ–ˆâ•‘    â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•‘ â–ˆâ–ˆâ•”â•
â–ˆâ–ˆâ•‘     â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•”â–ˆâ–ˆâ–ˆâ–ˆâ•”â–ˆâ–ˆâ•‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•—  â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•‘â–ˆâ–ˆâ•‘ â–ˆâ•— â–ˆâ–ˆâ•‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•”â•
â–ˆâ–ˆâ•‘     â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•‘â•šâ–ˆâ–ˆâ•”â•â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•”â•â•â•  â–ˆâ–ˆâ•”â•â•â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•”â•â•â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•‘â–ˆâ–ˆâ–ˆâ•—â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•”â•â–ˆâ–ˆâ•—
â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•—â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•‘ â•šâ•â• â–ˆâ–ˆâ•‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•—â–ˆâ–ˆâ•‘  â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•‘  â–ˆâ–ˆâ•‘â•šâ–ˆâ–ˆâ–ˆâ•”â–ˆâ–ˆâ–ˆâ•”â•â–ˆâ–ˆâ•‘  â–ˆâ–ˆâ•—
â•šâ•â•â•â•â•â•â•â•šâ•â•â•šâ•â•     â•šâ•â•â•šâ•â•â•â•â•â•â•â•šâ•â•  â•šâ•â•â•šâ•â•  â•šâ•â• â•šâ•â•â•â•šâ•â•â• â•šâ•â•  â•šâ•â•
================================================================================
 SCRIPT   : SuperOps Service Restart                                      v1.1.0
 AUTHOR   : Limehawk.io
 DATE      : December 2025
 USAGE    : .\superops_service_restart.ps1
================================================================================
 FILE     : superops_service_restart.ps1
DESCRIPTION : Restarts SuperOps RMM agent services for troubleshooting
--------------------------------------------------------------------------------
 README
--------------------------------------------------------------------------------
 PURPOSE
 Restarts SuperOps RMM agent services on a Windows system. Useful for
 troubleshooting agent connectivity issues or applying configuration changes
 that require a service restart.

 DATA SOURCES & PRIORITY
 1) Windows Service Manager (Get-Service / Restart-Service)
 2) Hardcoded service name pattern

 REQUIRED INPUTS
 - ServicePattern : "SuperOps*"
   (Wildcard pattern to match SuperOps-related service names)

 SETTINGS
 - Uses -Force to restart services without confirmation
 - Displays verbose output during restart operation
 - Automatically discovers all services matching the pattern
 - Handles multiple services if multiple SuperOps services exist

 BEHAVIOR
 - Searches for all Windows services matching the specified pattern
 - Restarts each matching service found
 - Displays detailed information about the restart operation
 - If no matching services found, reports this and exits successfully
 - Waits for services to fully restart before completing
 - All-or-nothing: any failure stops the script immediately

 PREREQUISITES
 - PowerShell 5.1 or later
 - Administrator privileges (required to restart services)
 - SuperOps RMM agent must be installed (services must exist)

 SECURITY NOTES
 - No secrets or credentials used
 - Only affects SuperOps-related services
 - Requires admin privileges to execute
 - Does not modify service configuration (restart only)

 ENDPOINTS
 - N/A (local service management only)

 EXIT CODES
 - 0 success
 - 1 failure

 EXAMPLE RUN (Style A)
 [ INPUT VALIDATION ]
 --------------------------------------------------------------
 Service Pattern : SuperOps*

 [ OPERATION ]
 --------------------------------------------------------------
 Searching for services matching: SuperOps*
 Found 1 service(s) to restart
 Restarting service: SuperOps RMM Agent (SuperOpsAgent)
 Service restart completed successfully

 [ RESULT ]
 --------------------------------------------------------------
 Status : Success
 Services Restarted : 1

 [ FINAL STATUS ]
 --------------------------------------------------------------
 SuperOps services restarted successfully

 [ SCRIPT COMPLETED ]
 --------------------------------------------------------------
--------------------------------------------------------------------------------
 CHANGELOG
--------------------------------------------------------------------------------
 2025-12-23 v1.1.0 Updated to Limehawk Script Framework
 2025-11-02 v1.0.0 Initial release
================================================================================
#>

Set-StrictMode -Version Latest

# ==== STATE (NO ARRAYS/LISTS) ====
$errorOccurred    = $false
$errorText        = ""
$servicesFound    = 0
$servicesRestarted = 0

# ==== HARDCODED INPUTS (MANDATORY) ====
$ServicePattern = "SuperOps*"

# ==== VALIDATION ====
if ([string]::IsNullOrWhiteSpace($ServicePattern)) {
    $errorOccurred = $true
    $errorText = "- ServicePattern is required but not set."
}

if ($errorOccurred) {
    Write-Host ""
    Write-Host "[ ERROR OCCURRED ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host $errorText

    Write-Host ""
    Write-Host "[ RESULT ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host "Status : Failure"

    Write-Host ""
    Write-Host "[ FINAL STATUS ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host "Script cannot proceed. Invalid configuration."

    Write-Host ""
    Write-Host "[ SCRIPT COMPLETED ]"
    Write-Host "--------------------------------------------------------------"
    exit 1
}

# ==== RUNTIME OUTPUT (Style A) ====
Write-Host ""
Write-Host "[ INPUT VALIDATION ]"
Write-Host "--------------------------------------------------------------"
Write-Host "Service Pattern : $ServicePattern"

Write-Host ""
Write-Host "[ OPERATION ]"
Write-Host "--------------------------------------------------------------"

try {
    Write-Host "Searching for services matching: $ServicePattern"

    # Find all matching services
    $services = Get-Service -Name $ServicePattern -ErrorAction SilentlyContinue

    if ($null -eq $services) {
        Write-Host "No services found matching pattern: $ServicePattern"
        Write-Host "This could mean:"
        Write-Host "  - SuperOps agent is not installed"
        Write-Host "  - Service has a different name"
        Write-Host "  - Service was uninstalled"
    } else {
        # Handle both single service and array of services
        if ($services -is [array]) {
            $servicesFound = $services.Count
        } else {
            $servicesFound = 1
            $services = @($services)
        }

        Write-Host "Found $servicesFound service(s) to restart"

        foreach ($service in $services) {
            try {
                Write-Host "Restarting service: $($service.DisplayName) ($($service.Name))"
                Write-Host "  Current Status: $($service.Status)"

                Restart-Service -Name $service.Name -Force -Verbose -ErrorAction Stop

                # Verify service is running
                $restartedService = Get-Service -Name $service.Name -ErrorAction Stop
                Write-Host "  New Status: $($restartedService.Status)"

                $servicesRestarted++
            } catch {
                throw "Failed to restart service $($service.Name): $($_.Exception.Message)"
            }
        }

        Write-Host "Service restart completed successfully"
    }

} catch {
    $errorOccurred = $true
    $errorText = $_.Exception.Message
}

if ($errorOccurred) {
    Write-Host ""
    Write-Host "[ ERROR OCCURRED ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host $errorText
}

Write-Host ""
Write-Host "[ RESULT ]"
Write-Host "--------------------------------------------------------------"
if ($errorOccurred) {
    Write-Host "Status             : Failure"
} else {
    Write-Host "Status             : Success"
}
Write-Host "Services Found     : $servicesFound"
Write-Host "Services Restarted : $servicesRestarted"

Write-Host ""
Write-Host "[ FINAL STATUS ]"
Write-Host "--------------------------------------------------------------"
if ($errorOccurred) {
    Write-Host "Failed to restart SuperOps services. See error details above."
} else {
    if ($servicesRestarted -gt 0) {
        Write-Host "SuperOps services restarted successfully"
    } else {
        Write-Host "No SuperOps services found to restart"
    }
}

Write-Host ""
Write-Host "[ SCRIPT COMPLETED ]"
Write-Host "--------------------------------------------------------------"

if ($errorOccurred) {
    exit 1
} else {
    exit 0
}
