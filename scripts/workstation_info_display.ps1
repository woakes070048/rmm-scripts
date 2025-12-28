$ErrorActionPreference = 'Stop'

<#
██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝ 
██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗ 
███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
================================================================================
 SCRIPT   : Workstation Information Display                               v1.2.0
 AUTHOR   : Limehawk.io
 DATE      : December 2025
 USAGE    : .\workstation_info_display.ps1
================================================================================
 FILE     : workstation_info_display.ps1
DESCRIPTION : Displays system info popup for user self-service from tray icon
--------------------------------------------------------------------------------
 README
--------------------------------------------------------------------------------
 PURPOSE
 Collects and displays comprehensive workstation information including operating
 system details, computer name, current user, CPU specifications, memory capacity,
 network adapter configuration, and hardware serial number. Designed for quick
 troubleshooting access via tray icon menu or RMM execution with dual output
 modes supporting both interactive popup display and console text output.

 DATA SOURCES & PRIORITY
 1) Hardcoded values (defined within the script body)
 2) WMI/CIM queries (Win32_OperatingSystem, Win32_Processor, etc.)
 3) Error

 REQUIRED INPUTS
 - DisplayMode      : 'popup'
   (Output display mode: 'popup' shows Windows Forms message box, 'console'
    outputs to console for RMM capture.)
 - IncludeNetwork   : $true
   (Whether to include detailed network adapter information.)
 - PopupTitle       : 'Workstation Information'
   (Title text for the popup message box when DisplayMode is 'popup'.)

 SETTINGS
 - Uses CIM/WMI for hardware and OS data collection.
 - Popup mode uses Windows Forms MessageBox for GUI display.
 - Console mode outputs formatted text suitable for RMM agent capture.
 - Network adapter information limited to enabled adapters only.
 - Memory sizes reported in GB with 2 decimal precision.

 BEHAVIOR
 - Script collects system information via CIM queries.
 - In popup mode, displays information in a Windows Forms message box.
 - In console mode, outputs formatted text to stdout.
 - All data collection occurs before display to ensure complete information.
 - Missing or unavailable information is reported as "N/A".

 PREREQUISITES
 - PowerShell 5.1 or later.
 - Windows operating system with CIM/WMI support.
 - For popup mode: .NET Framework (included in Windows).
 - No special permissions required (runs in user context).

 SECURITY NOTES
 - No secrets are printed to the console or popup.
 - All data collected is read-only from system WMI providers.
 - No sensitive information exposed beyond standard hardware inventory.

 ENDPOINTS
 - N/A (local system queries only)

 EXIT CODES
 - 0 success
 - 1 failure

 EXAMPLE RUN

 [ INPUT VALIDATION ]
 --------------------------------------------------------------
 DisplayMode    : popup
 IncludeNetwork : True
 PopupTitle     : Workstation Information

 [ COLLECTING SYSTEM INFORMATION ]
 --------------------------------------------------------------
 Gathering operating system details...
 Gathering computer information...
 Gathering CPU information...
 Gathering memory information...
 Gathering network adapter information...
 Gathering BIOS information...

 [ DISPLAY ]
 --------------------------------------------------------------
 Display Mode : Popup
 Showing Windows Forms message box...

 [ FINAL STATUS ]
 --------------------------------------------------------------
 Workstation information displayed successfully.

 [ SCRIPT COMPLETED ]
 --------------------------------------------------------------
--------------------------------------------------------------------------------
 CHANGELOG
--------------------------------------------------------------------------------
 2025-12-23 v1.2.0 Updated to Limehawk Script Framework
 2025-10-31 v1.1.0 Improved popup formatting with KV format
 2025-10-31 v1.0.0 Initial release
================================================================================
#>

Set-StrictMode -Version Latest

# ==== STATE (NO ARRAYS/LISTS) ====
$errorOccurred = $false
$errorText     = ""
$infoText      = ""

# ==== HARDCODED INPUTS (MANDATORY) ====
$DisplayMode    = 'popup'  # 'popup' or 'console'
$IncludeNetwork = $true
$PopupTitle     = 'Workstation Information'

# ==== VALIDATION ====
if ([string]::IsNullOrWhiteSpace($DisplayMode)) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- DisplayMode is required."
}
if ($DisplayMode -notin @('popup', 'console')) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- DisplayMode must be 'popup' or 'console'."
}
if ($IncludeNetwork -isnot [bool]) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- IncludeNetwork must be a boolean value."
}
if ([string]::IsNullOrWhiteSpace($PopupTitle)) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- PopupTitle is required."
}

if ($errorOccurred) {
    Write-Host ""
    Write-Host "[ ERROR OCCURRED ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host "Input validation failed:"
    Write-Host $errorText

    Write-Host ""
    Write-Host "[ RESULT ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host "Status : Failure"

    Write-Host ""
    Write-Host "[ FINAL STATUS ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host "Script cannot proceed due to invalid hardcoded inputs."

    Write-Host ""
    Write-Host "[ SCRIPT COMPLETED ]"
    Write-Host "--------------------------------------------------------------"
    exit 1
}

# ==== RUNTIME OUTPUT (Style A) ====
Write-Host ""
Write-Host "[ INPUT VALIDATION ]"
Write-Host "--------------------------------------------------------------"
Write-Host "DisplayMode    : $DisplayMode"
Write-Host "IncludeNetwork : $IncludeNetwork"
Write-Host "PopupTitle     : $PopupTitle"

# Helper function to safely get property
function Get-SafeProperty {
    param($Object, $PropertyName, $DefaultValue = "N/A")
    if ($Object.PSObject.Properties.Name -contains $PropertyName) {
        $value = $Object.$PropertyName
        if ($null -eq $value -or [string]::IsNullOrWhiteSpace($value)) {
            return $DefaultValue
        }
        return $value
    }
    return $DefaultValue
}

# Helper function to format bytes to GB
function Format-BytesToGB {
    param([long]$Bytes)
    if ($Bytes -eq 0) { return "0.00" }
    return [math]::Round($Bytes / 1GB, 2)
}

try {
    Write-Host ""
    Write-Host "[ COLLECTING SYSTEM INFORMATION ]"
    Write-Host "--------------------------------------------------------------"

    # Initialize info text with header
    $infoText = "WORKSTATION INFORMATION" + [Environment]::NewLine
    $infoText += "--------------------------------------------------------------" + [Environment]::NewLine
    $infoText += [Environment]::NewLine

    # Operating System Information
    Write-Host "Gathering operating system details..."
    $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
    $osName = Get-SafeProperty $osInfo 'Caption'
    $osVersion = Get-SafeProperty $osInfo 'Version'

    $infoText += "OPERATING SYSTEM" + [Environment]::NewLine
    $infoText += "Name                 : $osName" + [Environment]::NewLine
    $infoText += "Version              : $osVersion" + [Environment]::NewLine
    $infoText += [Environment]::NewLine

    # Computer Information
    Write-Host "Gathering computer information..."
    $computerInfo = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
    $computerName = Get-SafeProperty $computerInfo 'Name'
    $currentUser = $env:USERNAME

    # Get serial number from BIOS
    Write-Host "Gathering BIOS information..."
    $biosInfo = Get-CimInstance -ClassName Win32_BIOS -ErrorAction Stop
    $serialNumber = Get-SafeProperty $biosInfo 'SerialNumber'

    $infoText += "COMPUTER" + [Environment]::NewLine
    $infoText += "Name                 : $computerName" + [Environment]::NewLine
    $infoText += "User                 : $currentUser" + [Environment]::NewLine
    $infoText += "Serial Number        : $serialNumber" + [Environment]::NewLine
    $infoText += [Environment]::NewLine

    # CPU Information
    Write-Host "Gathering CPU information..."
    $cpuInfo = Get-CimInstance -ClassName Win32_Processor -ErrorAction Stop | Select-Object -First 1
    $cpuName = Get-SafeProperty $cpuInfo 'Name'
    $cpuCores = Get-SafeProperty $cpuInfo 'NumberOfCores' 0

    $infoText += "CPU" + [Environment]::NewLine
    $infoText += "Name                 : $cpuName" + [Environment]::NewLine
    $infoText += "Cores                : $cpuCores" + [Environment]::NewLine
    $infoText += [Environment]::NewLine

    # Memory Information
    Write-Host "Gathering memory information..."
    $ramModules = Get-CimInstance -ClassName Win32_PhysicalMemory -ErrorAction Stop
    $totalRam = 0
    foreach ($ram in $ramModules) {
        $capacity = Get-SafeProperty $ram 'Capacity' 0
        $totalRam += $capacity
    }
    $totalRamGB = Format-BytesToGB $totalRam

    $infoText += "MEMORY" + [Environment]::NewLine
    $infoText += "Total                : $totalRamGB GB" + [Environment]::NewLine
    $infoText += [Environment]::NewLine

    # Network Adapter Information
    if ($IncludeNetwork) {
        Write-Host "Gathering network adapter information..."
        $netAdapters = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration -ErrorAction Stop | Where-Object { $_.IPEnabled -eq $true }

        $infoText += "NETWORK" + [Environment]::NewLine

        if ($netAdapters) {
            $adapterNum = 0
            foreach ($adapter in $netAdapters) {
                $adapterNum++
                $description = Get-SafeProperty $adapter 'Description'
                $ipAddresses = Get-SafeProperty $adapter 'IPAddress' @()
                $macAddress = Get-SafeProperty $adapter 'MACAddress'

                $ipAddress = if ($ipAddresses -is [Array] -and $ipAddresses.Count -gt 0) {
                    $ipAddresses[0]
                } else {
                    "N/A"
                }

                $infoText += "Adapter $adapterNum            : $description" + [Environment]::NewLine
                $infoText += "IP Address           : $ipAddress" + [Environment]::NewLine
                $infoText += "MAC Address          : $macAddress" + [Environment]::NewLine
                $infoText += [Environment]::NewLine
            }
        } else {
            $infoText += "No active network adapters found." + [Environment]::NewLine
            $infoText += [Environment]::NewLine
        }
    }

    # Display the information
    Write-Host ""
    Write-Host "[ DISPLAY ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host "Display Mode : $DisplayMode"

    if ($DisplayMode -eq 'popup') {
        Write-Host "Showing Windows Forms message box..."

        try {
            Add-Type -AssemblyName System.Windows.Forms
            [System.Windows.Forms.MessageBox]::Show(
                $infoText,
                $PopupTitle,
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            ) | Out-Null

            Write-Host "Popup displayed successfully"
        } catch {
            throw "Failed to display popup: $($_.Exception.Message)"
        }

    } elseif ($DisplayMode -eq 'console') {
        Write-Host "Outputting to console..."
        Write-Host ""
        Write-Host $infoText
    }

} catch {
    $errorOccurred = $true
    if ($_.Exception.Message.Length -gt 0) { $errorText = $_.Exception.Message }
    else { $errorText = $_.ToString() }
}

if ($errorOccurred) {
    Write-Host ""
    Write-Host "[ ERROR OCCURRED ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host "Failed to collect or display workstation information:"
    Write-Host $errorText

    Write-Host ""
    Write-Host "[ RESULT ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host "Status : Failure"
}

Write-Host ""
Write-Host "[ FINAL STATUS ]"
Write-Host "--------------------------------------------------------------"
if ($errorOccurred) {
    Write-Host "Workstation information display failed. See error details above."
} else {
    Write-Host "Workstation information displayed successfully."
}

Write-Host ""
Write-Host "[ SCRIPT COMPLETED ]"
Write-Host "--------------------------------------------------------------"

if ($errorOccurred) {
    exit 1
} else {
    exit 0
}
