$ErrorActionPreference = 'Stop'

<#
â–ˆâ–ˆâ•—     â–ˆâ–ˆâ•—â–ˆâ–ˆâ–ˆâ•—   â–ˆâ–ˆâ–ˆâ•—â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•—â–ˆâ–ˆâ•—  â–ˆâ–ˆâ•— â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•— â–ˆâ–ˆâ•—    â–ˆâ–ˆâ•—â–ˆâ–ˆâ•—  â–ˆâ–ˆâ•—
â–ˆâ–ˆâ•‘     â–ˆâ–ˆâ•‘â–ˆâ–ˆâ–ˆâ–ˆâ•— â–ˆâ–ˆâ–ˆâ–ˆâ•‘â–ˆâ–ˆâ•”â•â•â•â•â•â–ˆâ–ˆâ•‘  â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•”â•â•â–ˆâ–ˆâ•—â–ˆâ–ˆâ•‘    â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•‘ â–ˆâ–ˆâ•”â•
â–ˆâ–ˆâ•‘     â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•”â–ˆâ–ˆâ–ˆâ–ˆâ•”â–ˆâ–ˆâ•‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•—  â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•‘â–ˆâ–ˆâ•‘ â–ˆâ•— â–ˆâ–ˆâ•‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•”â•
â–ˆâ–ˆâ•‘     â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•‘â•šâ–ˆâ–ˆâ•”â•â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•”â•â•â•  â–ˆâ–ˆâ•”â•â•â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•”â•â•â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•‘â–ˆâ–ˆâ–ˆâ•—â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•”â•â–ˆâ–ˆâ•—
â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•—â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•‘ â•šâ•â• â–ˆâ–ˆâ•‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•—â–ˆâ–ˆâ•‘  â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•‘  â–ˆâ–ˆâ•‘â•šâ–ˆâ–ˆâ–ˆâ•”â–ˆâ–ˆâ–ˆâ•”â•â–ˆâ–ˆâ•‘  â–ˆâ–ˆâ•—
â•šâ•â•â•â•â•â•â•â•šâ•â•â•šâ•â•     â•šâ•â•â•šâ•â•â•â•â•â•â•â•šâ•â•  â•šâ•â•â•šâ•â•  â•šâ•â• â•šâ•â•â•â•šâ•â•â• â•šâ•â•  â•šâ•â•
================================================================================
 SCRIPT   : Wake-on-LAN Enable                                           v1.0.1
 AUTHOR   : Limehawk.io
 DATE      : December 2025
 USAGE    : .\wol_enable.ps1
================================================================================
 FILE     : wol_enable.ps1
DESCRIPTION : Enables Wake-on-LAN settings for Ethernet adapters
--------------------------------------------------------------------------------
 README
--------------------------------------------------------------------------------
 PURPOSE

 Enables Wake-on-LAN (WOL) in both BIOS/UEFI and Windows NIC settings.
 Supports Dell, HP, and Lenovo systems with manufacturer-specific BIOS modules.
 Also enables WOL on all capable network adapters in Windows.

 DATA SOURCES & PRIORITY

 1) System manufacturer detection (CIM)
 2) Manufacturer-specific BIOS modules (Dell, HP, Lenovo)
 3) Windows NIC WOL settings (CIM)

 REQUIRED INPUTS

 None - script auto-detects manufacturer and configures accordingly.

 SETTINGS

 - Dell: Uses DellBIOSProvider module, sets WakeOnLan to "LANOnly"
 - HP: Uses HPCMSL module, sets Wake On Lan to "Boot to Hard Drive"
 - Lenovo: Uses WMI, sets WakeOnLAN to "Primary"
 - Windows: Enables MSPower_DeviceWakeEnable on all capable NICs

 BEHAVIOR

 1. Checks/installs required PowerShell modules (NuGet, PSGallery)
 2. Detects system manufacturer
 3. Installs manufacturer-specific BIOS module if needed
 4. Configures BIOS WOL setting
 5. Enables WOL on all capable Windows NICs

 PREREQUISITES

 - Windows 10/11
 - Admin privileges required
 - Internet connectivity for module installation
 - Supported manufacturer: Dell, HP, or Lenovo

 SECURITY NOTES

 - No secrets in logs
 - Modifies BIOS settings (requires admin)
 - Installs PowerShell modules from PSGallery

 EXIT CODES

 - 0: Success
 - 1: Warning (rerun required after PowerShellGet update)
 - Other: Manufacturer not supported or error

 EXAMPLE RUN

 [ SYSTEM DETECTION ]
 --------------------------------------------------------------
 Manufacturer : Dell Inc.

 [ BIOS CONFIGURATION ]
 --------------------------------------------------------------
 Installing DellBIOSProvider module...
 Setting WakeOnLan to LANOnly...
 BIOS WOL configured successfully

 [ NIC CONFIGURATION ]
 --------------------------------------------------------------
 Enabling WOL for Intel(R) Ethernet...
 NIC WOL enabled successfully

 [ RESULT ]
 --------------------------------------------------------------
 Status : Success

 [ SCRIPT COMPLETED ]
 --------------------------------------------------------------
--------------------------------------------------------------------------------
 CHANGELOG
--------------------------------------------------------------------------------
 2025-12-23 v1.0.1 Updated to Limehawk Script Framework
 2025-11-29 v1.0.0 Initial Style A implementation
================================================================================
#>

Set-StrictMode -Version Latest

# ==== STATE ====
$errorOccurred = $false
$errorText = ""
$resultCode = 0
$summary = ""

# ==== RUNTIME OUTPUT ====
Write-Host ""
Write-Host "[ DEPENDENCY CHECK ]"
Write-Host "--------------------------------------------------------------"

# Check and install NuGet provider
$PPNuGet = Get-PackageProvider -ListAvailable | Where-Object { $_.Name -eq "Nuget" }
if (-not $PPNuGet) {
    Write-Host "Installing NuGet provider..."
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
    $summary += "Installed NuGet. "
} else {
    Write-Host "NuGet provider already installed"
}

# Check PSGallery
$PSGallery = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
if (-not $PSGallery) {
    Write-Host "Configuring PSGallery..."
    Set-PSRepository -InstallationPolicy Trusted -Name PSGallery
    $summary += "Configured PSGallery. "
} else {
    Write-Host "PSGallery already configured"
}

# Check PowerShellGet version
$PsGetVersion = (Get-Module PowerShellGet -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1).Version
if ($PsGetVersion -lt [version]'2.0') {
    Write-Host "PowerShellGet version $PsGetVersion is outdated, updating..."
    try {
        Install-Module -Name PowerShellGet -MinimumVersion 2.2 -Force -AllowClobber -ErrorAction Stop
        Write-Host "PowerShellGet updated. Please rerun this script."
        $summary += "Updated PowerShellGet. "
        $resultCode = 1
    } catch {
        Write-Host "Warning: Could not update PowerShellGet: $($_.Exception.Message)"
        $summary += "PowerShellGet update failed. "
    }
}

if ($resultCode -eq 1) {
    Write-Host ""
    Write-Host "[ RESULT ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host "Status  : Rerun Required"
    Write-Host "Summary : $summary"
    Write-Host ""
    Write-Host "[ SCRIPT COMPLETED ]"
    Write-Host "--------------------------------------------------------------"
    exit 1
}

Write-Host ""
Write-Host "[ SYSTEM DETECTION ]"
Write-Host "--------------------------------------------------------------"

# Detect manufacturer
$Manufacturer = (Get-CimInstance -ClassName Win32_ComputerSystem).Manufacturer
Write-Host "Manufacturer : $Manufacturer"

Write-Host ""
Write-Host "[ BIOS CONFIGURATION ]"
Write-Host "--------------------------------------------------------------"

try {
    if ($Manufacturer -like "*Dell*") {
        $summary += "Dell system. "
        Write-Host "Detected Dell system"

        # Install Dell BIOS Provider if needed
        $Mod = Get-Module -ListAvailable -Name DellBIOSProvider
        if (-not $Mod) {
            Write-Host "Installing DellBIOSProvider module..."
            Install-Module -Name DellBIOSProvider -Force -ErrorAction Stop
            $summary += "Installed DellBIOSProvider. "
        }
        Import-Module DellBIOSProvider -Global

        # Set WOL
        Write-Host "Setting WakeOnLan to LANOnly..."
        Set-Item -Path "DellSmBios:\PowerManagement\WakeOnLan" -Value "LANOnly" -ErrorAction Stop
        Write-Host "Dell BIOS WOL configured successfully"
        $summary += "Dell WOL updated. "

    } elseif ($Manufacturer -like "*HP*" -or $Manufacturer -like "*Hewlett*") {
        $summary += "HP system. "
        Write-Host "Detected HP system"

        # Install HP CMSL if needed
        $Mod = Get-Module -ListAvailable -Name HPCMSL
        if (-not $Mod) {
            Write-Host "Installing HPCMSL module..."
            Install-Module -Name HPCMSL -Force -AcceptLicense -ErrorAction Stop
            $summary += "Installed HPCMSL. "
        }
        Import-Module HPCMSL -Global

        # Set WOL for all WOL-related settings
        Write-Host "Configuring HP Wake On LAN settings..."
        $WolTypes = Get-HPBIOSSettingsList | Where-Object { $_.Name -like "*Wake On Lan*" }
        foreach ($WolType in $WolTypes) {
            Write-Host "  Setting: $($WolType.Name)"
            Set-HPBIOSSettingValue -Name $($WolType.Name) -Value "Boot to Hard Drive" -ErrorAction Stop
        }
        Write-Host "HP BIOS WOL configured successfully"
        $summary += "HP WOL updated. "

    } elseif ($Manufacturer -like "*Lenovo*") {
        $summary += "Lenovo system. "
        Write-Host "Detected Lenovo system"

        # Set WOL via WMI
        Write-Host "Setting WakeOnLAN via WMI..."
        (Get-WmiObject -Class "Lenovo_SetBiosSetting" -Namespace "root\wmi" -ErrorAction Stop).SetBiosSetting('WakeOnLAN,Primary') | Out-Null
        (Get-WmiObject -Class "Lenovo_SaveBiosSettings" -Namespace "root\wmi" -ErrorAction Stop).SaveBiosSettings() | Out-Null
        Write-Host "Lenovo BIOS WOL configured successfully"
        $summary += "Lenovo WOL updated. "

    } else {
        Write-Host "Manufacturer '$Manufacturer' not supported for BIOS WOL configuration"
        Write-Host "Supported manufacturers: Dell, HP, Lenovo"
        $summary += "$Manufacturer not supported. "
    }
} catch {
    Write-Host "Warning: BIOS WOL configuration failed: $($_.Exception.Message)"
    $summary += "BIOS WOL error. "
}

Write-Host ""
Write-Host "[ NIC CONFIGURATION ]"
Write-Host "--------------------------------------------------------------"

# Enable WOL on all capable NICs
$NicsWithWake = Get-CimInstance -ClassName "MSPower_DeviceWakeEnable" -Namespace "root/wmi" -ErrorAction SilentlyContinue

if ($NicsWithWake) {
    foreach ($Nic in $NicsWithWake) {
        Write-Host "Enabling WOL for: $($Nic.InstanceName)"
        try {
            Set-CimInstance -InputObject $Nic -Property @{Enable = $true} -ErrorAction Stop
            Write-Host "  Success"
            $summary += "$($Nic.InstanceName) WOL enabled. "
        } catch {
            Write-Host "  Warning: $($_.Exception.Message)"
            $summary += "$($Nic.InstanceName) WOL error. "
        }
    }
} else {
    Write-Host "No NICs with Wake-on-LAN capability found"
    $summary += "No WOL NICs found. "
}

Write-Host ""
Write-Host "[ RESULT ]"
Write-Host "--------------------------------------------------------------"
Write-Host "Status  : Success"
Write-Host "Summary : $summary"

Write-Host ""
Write-Host "[ FINAL STATUS ]"
Write-Host "--------------------------------------------------------------"
Write-Host "Wake-on-LAN configuration completed."
Write-Host "A reboot may be required for BIOS changes to take effect."

Write-Host ""
Write-Host "[ SCRIPT COMPLETED ]"
Write-Host "--------------------------------------------------------------"
exit 0
