$ErrorActionPreference = 'Stop'

<#
██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
================================================================================
 SCRIPT   : IP Config Release Renew                                      v1.0.1
 AUTHOR   : Limehawk.io
 DATE     : December 2024
 USAGE    : .\ipconfig_release_renew.ps1
================================================================================
 FILE     : ipconfig_release_renew.ps1
--------------------------------------------------------------------------------
 README
--------------------------------------------------------------------------------
 PURPOSE

 Releases and renews IP addresses on all DHCP-enabled network adapters, and
 flushes the DNS cache. Useful for resolving network connectivity issues caused
 by stale DHCP leases or DNS cache problems.

 DATA SOURCES & PRIORITY

 1) Hardcoded values (defined within the script body)
 2) Windows network adapter configuration

 REQUIRED INPUTS

 - FlushDns : Whether to flush DNS cache after renewal (default: $true)

 SETTINGS

 - Targets only DHCP-enabled adapters
 - Releases IP before renewing
 - Optionally flushes DNS cache

 BEHAVIOR

 1. Queries all network adapters for DHCP-enabled interfaces
 2. For each DHCP adapter: releases IP, then renews IP
 3. Flushes DNS cache if enabled
 4. Reports results for each adapter

 PREREQUISITES

 - Windows OS with network adapters
 - DHCP-enabled network adapters (static IP adapters are skipped)
 - Admin privileges recommended for DNS flush

 SECURITY NOTES

 - No secrets in logs
 - Temporarily disconnects network during release/renew

 EXIT CODES

 - 0: Success
 - 1: Failure

 EXAMPLE RUN

 [ INPUT VALIDATION ]
 --------------------------------------------------------------
 Flush DNS : True

 [ OPERATION ]
 --------------------------------------------------------------
 Found 2 DHCP-enabled adapter(s)
 Processing adapter: Ethernet
   Releasing IP address...
   Renewing IP address...
 Processing adapter: Wi-Fi
   Releasing IP address...
   Renewing IP address...
 Flushing DNS cache...

 [ RESULT ]
 --------------------------------------------------------------
 Status           : Success
 Adapters Updated : 2

 [ SCRIPT COMPLETED ]
 --------------------------------------------------------------
--------------------------------------------------------------------------------
 CHANGELOG
--------------------------------------------------------------------------------
 2024-12-23 v1.0.1 Updated to Limehawk Script Framework
 2025-11-29 v1.0.0 Initial Style A implementation
================================================================================
#>

Set-StrictMode -Version Latest

# ==== STATE ====
$errorOccurred = $false
$errorText = ""
$adaptersProcessed = 0

# ==== HARDCODED INPUTS ====
$FlushDns = $true

# ==== RUNTIME OUTPUT ====
Write-Host ""
Write-Host "[ INPUT VALIDATION ]"
Write-Host "--------------------------------------------------------------"
Write-Host "Flush DNS : $FlushDns"

Write-Host ""
Write-Host "[ OPERATION ]"
Write-Host "--------------------------------------------------------------"

try {
    # Get all network adapters with IP configuration
    $adapters = Get-NetIPConfiguration | Where-Object {
        $_.NetAdapter.Status -eq 'Up' -and
        $_.IPv4Address -ne $null
    }

    # Filter to DHCP-enabled adapters
    $dhcpAdapters = $adapters | Where-Object {
        $dhcpInfo = Get-NetIPInterface -InterfaceIndex $_.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
        $dhcpInfo.Dhcp -eq 'Enabled'
    }

    if ($null -eq $dhcpAdapters -or @($dhcpAdapters).Count -eq 0) {
        Write-Host "No DHCP-enabled adapters found"
        Write-Host "Only adapters using DHCP can have their IP released/renewed"
    } else {
        $adapterCount = @($dhcpAdapters).Count
        Write-Host "Found $adapterCount DHCP-enabled adapter(s)"

        foreach ($adapter in $dhcpAdapters) {
            $adapterName = $adapter.InterfaceAlias
            Write-Host "Processing adapter: $adapterName"

            # Release IP address
            Write-Host "  Releasing IP address..."
            $releaseResult = ipconfig /release "$adapterName" 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Host "  Warning: Release may have encountered an issue"
            }

            # Small delay between release and renew
            Start-Sleep -Seconds 2

            # Renew IP address
            Write-Host "  Renewing IP address..."
            $renewResult = ipconfig /renew "$adapterName" 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Host "  Warning: Renew may have encountered an issue"
            }

            $adaptersProcessed++
        }
    }

    # Flush DNS cache
    if ($FlushDns) {
        Write-Host "Flushing DNS cache..."
        $flushResult = ipconfig /flushdns 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "DNS cache flushed successfully"
        } else {
            Write-Host "Warning: DNS flush may have encountered an issue"
        }
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
    Write-Host "Status : Failure"
} else {
    Write-Host "Status           : Success"
    Write-Host "Adapters Updated : $adaptersProcessed"
}

Write-Host ""
Write-Host "[ FINAL STATUS ]"
Write-Host "--------------------------------------------------------------"
if ($errorOccurred) {
    Write-Host "IP configuration update failed. See error above."
} else {
    if ($adaptersProcessed -gt 0) {
        Write-Host "IP release/renew completed for $adaptersProcessed adapter(s)."
    } else {
        Write-Host "No DHCP adapters to update. Network configuration unchanged."
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
