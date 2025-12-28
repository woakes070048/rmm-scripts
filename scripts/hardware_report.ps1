$ErrorActionPreference = 'Stop'

<#
██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝ 
██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗ 
███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
================================================================================
 SCRIPT   : Hardware Report                                               v1.1.0
 AUTHOR   : Limehawk.io
 DATE      : December 2025
 USAGE    : .\hardware_report.ps1
================================================================================
 FILE     : hardware_report.ps1
 DESCRIPTION : Generates comprehensive hardware inventory report via CIM queries
--------------------------------------------------------------------------------
 README
--------------------------------------------------------------------------------
 PURPOSE
 Generates a comprehensive hardware inventory report for the local machine.
 Collects system information, CPU, memory, storage, GPU, network adapters,
 and BIOS details. Designed for unattended execution in RMM environments
 to gather standardized hardware data for asset management and documentation.

 DATA SOURCES & PRIORITY
 1) Hardcoded values (defined within the script body)
 2) WMI/CIM queries (Win32_ComputerSystem, Win32_Processor, etc.)
 3) Error

 REQUIRED INPUTS
 - IncludeStorage      : $true
   (Whether to include storage device information in the report.)
 - IncludeGpu          : $true
   (Whether to include GPU information in the report.)
 - IncludeNetwork      : $true
   (Whether to include network adapter information in the report.)
 - IncludeBios         : $true
   (Whether to include BIOS information in the report.)
 - IncludeMemoryModules: $true
   (Whether to include individual RAM module details.)

 SETTINGS
 - Uses CIM/WMI for hardware data collection (Windows native).
 - All output formatted as Key : Value pairs for RMM parsing.
 - No external dependencies or modules required.
 - Sizes reported in GB with 2 decimal precision.

 BEHAVIOR
 - Script collects hardware information from local system via CIM queries.
 - All sections are optional and can be disabled via hardcoded inputs.
 - Missing or unavailable hardware components are reported as "N/A".
 - Output is structured for easy capture by RMM agent stdout collection.

 PREREQUISITES
 - PowerShell 5.1 or later.
 - Windows operating system with CIM/WMI support.
 - No special permissions required (runs in user context).

 SECURITY NOTES
 - No secrets are printed to the console.
 - No sensitive system information exposed beyond standard hardware inventory.
 - All data collected is read-only from system WMI providers.

 ENDPOINTS
 - N/A (local system queries only)

 EXIT CODES
 - 0 success
 - 1 failure

 EXAMPLE RUN

 [ INPUT VALIDATION ]
 --------------------------------------------------------------
 IncludeStorage       : True
 IncludeGpu           : True
 IncludeNetwork       : True
 IncludeBios          : True
 IncludeMemoryModules : True

 [ SYSTEM INFORMATION ]
 --------------------------------------------------------------
 Computer Name        : DESKTOP-ABC123
 Manufacturer         : Dell Inc.
 Model                : OptiPlex 7090
 Serial Number        : 1A2B3C4D
 Total Memory         : 32.00 GB
 Number of Processors : 1

 [ CPU INFORMATION ]
 --------------------------------------------------------------
 Name                 : Intel(R) Core(TM) i7-10700 CPU @ 2.90GHz
 Cores                : 8
 Logical Processors   : 16
 Max Clock Speed      : 2904 MHz

 [ STORAGE DEVICES ]
 --------------------------------------------------------------
 Drive C (Windows)    : 476.46 GB Total | 123.45 GB Free | 353.01 GB Used
 Drive D (Data)       : 931.51 GB Total | 456.78 GB Free | 474.73 GB Used

 [ FINAL STATUS ]
 --------------------------------------------------------------
 Hardware report generated successfully.

 [ SCRIPT COMPLETED ]
 --------------------------------------------------------------
--------------------------------------------------------------------------------
 CHANGELOG
--------------------------------------------------------------------------------
 2025-12-23 v1.1.0 Updated to Limehawk Script Framework
 2025-10-31 v1.0.0 Initial release
================================================================================
#>

Set-StrictMode -Version Latest

# ==== STATE (NO ARRAYS/LISTS) ====
$errorOccurred = $false
$errorText     = ""

# ==== HARDCODED INPUTS (MANDATORY) ====
$IncludeStorage       = $true
$IncludeGpu           = $true
$IncludeNetwork       = $true
$IncludeBios          = $true
$IncludeMemoryModules = $true

# ==== VALIDATION ====
# Boolean inputs don't require validation, but we verify they're boolean type
if ($IncludeStorage -isnot [bool]) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- IncludeStorage must be a boolean value."
}
if ($IncludeGpu -isnot [bool]) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- IncludeGpu must be a boolean value."
}
if ($IncludeNetwork -isnot [bool]) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- IncludeNetwork must be a boolean value."
}
if ($IncludeBios -isnot [bool]) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- IncludeBios must be a boolean value."
}
if ($IncludeMemoryModules -isnot [bool]) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- IncludeMemoryModules must be a boolean value."
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
Write-Host "IncludeStorage       : $IncludeStorage"
Write-Host "IncludeGpu           : $IncludeGpu"
Write-Host "IncludeNetwork       : $IncludeNetwork"
Write-Host "IncludeBios          : $IncludeBios"
Write-Host "IncludeMemoryModules : $IncludeMemoryModules"

# Helper function to format bytes to GB
function Format-BytesToGB {
    param([long]$Bytes)
    if ($Bytes -eq 0) { return "0.00" }
    return [math]::Round($Bytes / 1GB, 2)
}

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

try {
    # ==== SYSTEM INFORMATION ====
    Write-Host ""
    Write-Host "[ SYSTEM INFORMATION ]"
    Write-Host "--------------------------------------------------------------"

    $sysInfo = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop

    Write-Host "Computer Name        : $env:COMPUTERNAME"
    Write-Host "Manufacturer         : $(Get-SafeProperty $sysInfo 'Manufacturer')"
    Write-Host "Model                : $(Get-SafeProperty $sysInfo 'Model')"

    # Get serial number from BIOS
    $biosSerial = Get-CimInstance -ClassName Win32_BIOS -ErrorAction Stop
    Write-Host "Serial Number        : $(Get-SafeProperty $biosSerial 'SerialNumber')"

    $totalMemGB = Format-BytesToGB (Get-SafeProperty $sysInfo 'TotalPhysicalMemory' 0)
    Write-Host "Total Memory         : $totalMemGB GB"
    Write-Host "Number of Processors : $(Get-SafeProperty $sysInfo 'NumberOfProcessors' 0)"

    # ==== CPU INFORMATION ====
    Write-Host ""
    Write-Host "[ CPU INFORMATION ]"
    Write-Host "--------------------------------------------------------------"

    $cpuInfo = Get-CimInstance -ClassName Win32_Processor -ErrorAction Stop | Select-Object -First 1

    Write-Host "Name                 : $(Get-SafeProperty $cpuInfo 'Name')"
    Write-Host "Cores                : $(Get-SafeProperty $cpuInfo 'NumberOfCores' 0)"
    Write-Host "Logical Processors   : $(Get-SafeProperty $cpuInfo 'NumberOfLogicalProcessors' 0)"
    Write-Host "Max Clock Speed      : $(Get-SafeProperty $cpuInfo 'MaxClockSpeed' 0) MHz"

    # ==== MEMORY MODULES ====
    if ($IncludeMemoryModules) {
        Write-Host ""
        Write-Host "[ MEMORY MODULES ]"
        Write-Host "--------------------------------------------------------------"

        $ramModules = Get-CimInstance -ClassName Win32_PhysicalMemory -ErrorAction Stop

        if ($ramModules) {
            $moduleCount = 0
            $totalRam = 0

            foreach ($ram in $ramModules) {
                $moduleCount++
                $capacity = Get-SafeProperty $ram 'Capacity' 0
                $totalRam += $capacity
                $capacityGB = Format-BytesToGB $capacity
                $speed = Get-SafeProperty $ram 'Speed' 0
                $manufacturer = Get-SafeProperty $ram 'Manufacturer' 'Unknown'

                Write-Host "Module $moduleCount          : $manufacturer - $capacityGB GB @ $speed MHz"
            }

            $totalRamGB = Format-BytesToGB $totalRam
            Write-Host "Total Installed      : $totalRamGB GB"
        } else {
            Write-Host "No RAM module details available."
        }
    }

    # ==== STORAGE DEVICES ====
    if ($IncludeStorage) {
        Write-Host ""
        Write-Host "[ STORAGE DEVICES ]"
        Write-Host "--------------------------------------------------------------"

        $disks = Get-CimInstance -ClassName Win32_LogicalDisk -ErrorAction Stop | Where-Object { $_.DriveType -eq 3 }

        if ($disks) {
            foreach ($disk in $disks) {
                $deviceId = Get-SafeProperty $disk 'DeviceID' 'Unknown'
                $volumeName = Get-SafeProperty $disk 'VolumeName' 'No Label'
                $size = Get-SafeProperty $disk 'Size' 0
                $freeSpace = Get-SafeProperty $disk 'FreeSpace' 0

                $totalGB = Format-BytesToGB $size
                $freeGB = Format-BytesToGB $freeSpace
                $usedGB = [math]::Round($totalGB - $freeGB, 2)

                Write-Host "Drive $deviceId ($volumeName) : $totalGB GB Total | $freeGB GB Free | $usedGB GB Used"
            }
        } else {
            Write-Host "No storage devices found."
        }
    }

    # ==== GPU INFORMATION ====
    if ($IncludeGpu) {
        Write-Host ""
        Write-Host "[ GPU INFORMATION ]"
        Write-Host "--------------------------------------------------------------"

        $gpus = Get-CimInstance -ClassName Win32_VideoController -ErrorAction Stop

        if ($gpus) {
            $gpuCount = 0
            foreach ($gpu in $gpus) {
                $gpuCount++
                $name = Get-SafeProperty $gpu 'Name'
                $adapterRam = Get-SafeProperty $gpu 'AdapterRAM' 0
                $driverVersion = Get-SafeProperty $gpu 'DriverVersion'

                $gpuRamGB = if ($adapterRam -gt 0) { Format-BytesToGB $adapterRam } else { "N/A" }

                Write-Host "GPU $gpuCount Name          : $name"
                Write-Host "GPU $gpuCount RAM           : $gpuRamGB GB"
                Write-Host "GPU $gpuCount Driver        : $driverVersion"

                if ($gpuCount -lt @($gpus).Count) {
                    Write-Host ""
                }
            }
        } else {
            Write-Host "No GPU devices detected."
        }
    }

    # ==== NETWORK ADAPTERS ====
    if ($IncludeNetwork) {
        Write-Host ""
        Write-Host "[ NETWORK ADAPTERS ]"
        Write-Host "--------------------------------------------------------------"

        $netAdapters = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration -ErrorAction Stop | Where-Object { $_.IPEnabled -eq $true }

        if ($netAdapters) {
            $adapterCount = 0
            foreach ($adapter in $netAdapters) {
                $adapterCount++
                $description = Get-SafeProperty $adapter 'Description'
                $ipAddresses = Get-SafeProperty $adapter 'IPAddress' @()

                $ips = if ($ipAddresses -is [Array]) { $ipAddresses -join ", " } else { $ipAddresses }
                if ([string]::IsNullOrWhiteSpace($ips)) { $ips = "N/A" }

                Write-Host "Adapter $adapterCount         : $description"
                Write-Host "IP Addresses         : $ips"

                if ($adapterCount -lt @($netAdapters).Count) {
                    Write-Host ""
                }
            }
        } else {
            Write-Host "No active network adapters found."
        }
    }

    # ==== BIOS INFORMATION ====
    if ($IncludeBios) {
        Write-Host ""
        Write-Host "[ BIOS INFORMATION ]"
        Write-Host "--------------------------------------------------------------"

        $biosInfo = Get-CimInstance -ClassName Win32_BIOS -ErrorAction Stop

        Write-Host "Manufacturer         : $(Get-SafeProperty $biosInfo 'Manufacturer')"
        Write-Host "Version              : $(Get-SafeProperty $biosInfo 'SMBIOSBIOSVersion')"

        $releaseDate = Get-SafeProperty $biosInfo 'ReleaseDate' $null
        if ($releaseDate -and $releaseDate -is [DateTime]) {
            Write-Host "Release Date         : $($releaseDate.ToString('yyyy-MM-dd'))"
        } else {
            Write-Host "Release Date         : N/A"
        }
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
    Write-Host "Failed to collect hardware information:"
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
    Write-Host "Hardware report generation failed. See error details above."
} else {
    Write-Host "Hardware report generated successfully."
}

Write-Host ""
Write-Host "[ SCRIPT COMPLETED ]"
Write-Host "--------------------------------------------------------------"

if ($errorOccurred) {
    exit 1
} else {
    exit 0
}
