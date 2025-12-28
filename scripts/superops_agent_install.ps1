$ErrorActionPreference = 'Stop'

<#
██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
================================================================================
 SCRIPT   : SuperOps Agent Install                                        v1.1.0
 AUTHOR   : Limehawk.io
 DATE      : December 2025
 USAGE    : .\superops_agent_install.ps1
================================================================================
 FILE     : superops_agent_install.ps1
DESCRIPTION : Downloads and installs SuperOps RMM agent on Windows
--------------------------------------------------------------------------------
 README
--------------------------------------------------------------------------------
 PURPOSE
 Downloads and installs the SuperOps RMM agent on a Windows system using the
 MSI installer. This script is designed for automated deployment in RMM
 environments where the agent download URL is provided as an environment
 variable.

 DATA SOURCES & PRIORITY
 1) Environment variable (AGENT_URL - injected by RMM platform)
 2) Error

 REQUIRED INPUTS
 - AGENT_URL : <provided by RMM environment>
   (The download URL for the SuperOps agent MSI installer. This is typically
    injected by the RMM platform as an environment variable.)

 SETTINGS
 - Uses silent installation mode (/qn) for unattended deployment
 - Automatically accepts license agreement
 - Waits for installation to complete before exiting
 - Downloads installer to current working directory
 - Cleans up installer file after successful installation

 BEHAVIOR
 - Downloads the SuperOps agent MSI from the provided URL
 - Installs silently without user interaction
 - Reports progress and status to console
 - Exits with code 0 on success, 1 on failure
 - All-or-nothing: any failure stops the script immediately

 PREREQUISITES
 - PowerShell 5.1 or later
 - Administrator privileges (required for MSI installation)
 - Internet access to download agent installer
 - AGENT_URL environment variable must be set by RMM platform

 SECURITY NOTES
 - No secrets are hardcoded in this script
 - Agent URL is provided by RMM environment variable
 - Uses HTTPS for secure download (if URL is HTTPS)
 - MSI is executed with standard Windows Installer security context

 ENDPOINTS
 - SuperOps agent download URL (provided via AGENT_URL variable)

 EXIT CODES
 - 0 success
 - 1 failure

 EXAMPLE RUN (Style A)
 [ INPUT VALIDATION ]
 --------------------------------------------------------------
 Agent URL : https://app.superops.com/downloads/agent.msi

 [ OPERATION ]
 --------------------------------------------------------------
 Downloading agent from URL...
 Download completed: agent.msi (Size: 15.2 MB)
 Starting silent installation...
 Installation completed successfully
 Cleaning up installer file...

 [ RESULT ]
 --------------------------------------------------------------
 Status : Success

 [ FINAL STATUS ]
 --------------------------------------------------------------
 SuperOps agent installed successfully

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
$errorOccurred = $false
$errorText     = ""
$installerPath = ""
$installerSize = 0

# ==== HARDCODED INPUTS (MANDATORY) ====
# AGENT_URL is expected to be provided by the RMM environment as an environment variable
# If testing locally, set it manually: $env:AGENT_URL = "https://your-agent-url.msi"

# ==== VALIDATION ====
if ([string]::IsNullOrWhiteSpace($env:AGENT_URL)) {
    $errorOccurred = $true
    $errorText = "- AGENT_URL environment variable is required but not set.`n"
    $errorText += "  This variable should be injected by the RMM platform.`n"
    $errorText += "  For manual testing, set it with: `$env:AGENT_URL = 'https://your-url.msi'"
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
    Write-Host "Script cannot proceed. AGENT_URL environment variable is missing."

    Write-Host ""
    Write-Host "[ SCRIPT COMPLETED ]"
    Write-Host "--------------------------------------------------------------"
    exit 1
}

# ==== RUNTIME OUTPUT (Style A) ====
Write-Host ""
Write-Host "[ INPUT VALIDATION ]"
Write-Host "--------------------------------------------------------------"
Write-Host "Agent URL : $env:AGENT_URL"

Write-Host ""
Write-Host "[ OPERATION ]"
Write-Host "--------------------------------------------------------------"

try {
    # Extract filename from URL
    $installerPath = Split-Path -Path $env:AGENT_URL -Leaf
    Write-Host "Target installer file: $installerPath"

    # Download the agent installer
    Write-Host "Downloading agent from URL..."
    try {
        Invoke-WebRequest -Uri $env:AGENT_URL -OutFile $installerPath -ErrorAction Stop

        # Check file size
        if (Test-Path $installerPath) {
            $installerSize = (Get-Item $installerPath).Length
            $installerSizeMB = [math]::Round($installerSize / 1MB, 2)
            Write-Host "Download completed: $installerPath (Size: $installerSizeMB MB)"
        } else {
            throw "Downloaded file not found after download operation"
        }
    } catch {
        throw "Failed to download agent from URL: $($_.Exception.Message)"
    }

    # Install the agent silently
    Write-Host "Starting silent installation..."
    try {
        $msiArgs = @(
            "/i"
            $installerPath
            "/qn"
            "LicenseAccepted=YES"
        )

        $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $msiArgs -Wait -PassThru -ErrorAction Stop

        if ($process.ExitCode -eq 0) {
            Write-Host "Installation completed successfully (Exit Code: 0)"
        } else {
            throw "MSI installation failed with exit code: $($process.ExitCode)"
        }
    } catch {
        throw "Failed to execute installer: $($_.Exception.Message)"
    }

    # Clean up installer file
    Write-Host "Cleaning up installer file..."
    try {
        if (Test-Path $installerPath) {
            Remove-Item -Path $installerPath -Force -ErrorAction Stop
            Write-Host "Installer file removed"
        }
    } catch {
        Write-Host "Warning: Failed to remove installer file: $($_.Exception.Message)"
        Write-Host "You may need to manually delete: $installerPath"
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
    Write-Host "Status : Success"
}

Write-Host ""
Write-Host "[ FINAL STATUS ]"
Write-Host "--------------------------------------------------------------"
if ($errorOccurred) {
    Write-Host "SuperOps agent installation failed. See error details above."
} else {
    Write-Host "SuperOps agent installed successfully"
}

Write-Host ""
Write-Host "[ SCRIPT COMPLETED ]"
Write-Host "--------------------------------------------------------------"

if ($errorOccurred) {
    exit 1
} else {
    exit 0
}
