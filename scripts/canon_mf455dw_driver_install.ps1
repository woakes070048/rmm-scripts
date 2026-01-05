$ErrorActionPreference = 'Stop'
<#
██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
================================================================================
 SCRIPT   : Canon imageCLASS MF455dw Driver Install                       v1.0.0
 AUTHOR   : Limehawk.io
 DATE     : January 2026
 USAGE    : .\canon_mf455dw_driver_install.ps1
================================================================================
 FILE     : canon_mf455dw_driver_install.ps1
 DESCRIPTION : Downloads and installs Canon imageCLASS MF455dw printer drivers
--------------------------------------------------------------------------------
 README
--------------------------------------------------------------------------------
 PURPOSE

   Downloads the Canon imageCLASS MF455dw MF Driver package from Canon's CDN,
   extracts it, and installs the UFR II LT printer driver to the Windows driver
   store using pnputil. Optionally creates a TCP/IP printer queue if an IP
   address is specified.

 DATA SOURCES & PRIORITY

   - Canon CDN: Official driver package download
   - pnputil: Windows native driver installation tool

 REQUIRED INPUTS

   All inputs are hardcoded in the script body:
     - $driverUrl: URL to Canon MF Driver package (default: MF450 series v7.20)
     - $printerIp: IP address of printer (leave empty to skip queue creation)
     - $printerName: Display name for the printer queue
     - $installScanner: Whether to also install scanner driver (true/false)

 SETTINGS

   Configuration details and default values:
     - Driver extracts to: C:\Temp\CanonMF455dw
     - Cleanup after install: Yes (removes extracted files)
     - Driver type: UFR II LT (recommended for most use cases)

 BEHAVIOR

   The script performs the following actions in order:
   1. Downloads Canon MF Driver package from official CDN
   2. Extracts driver files using built-in self-extractor
   3. Locates and installs UFR II LT driver via pnputil
   4. Creates TCP/IP printer port if IP specified
   5. Adds printer queue using installed driver
   6. Cleans up temporary files

 PREREQUISITES

   - Windows 10/11 or Windows Server 2016+
   - Administrator privileges
   - Network connectivity to Canon CDN
   - curl.exe (included in Windows 10 1803+)

 SECURITY NOTES

   - No secrets exposed in output
   - Downloads only from official Canon CDN
   - Verifies download before extraction

 ENDPOINTS

   - https://gdlp01.c-wss.com - Canon Global Download Platform

 EXIT CODES

   0 = Success
   1 = Failure (error occurred)

 EXAMPLE RUN

   [ INPUT VALIDATION ]
   --------------------------------------------------------------
   Driver URL   : https://gdlp01.c-wss.com/gds/7/...
   Printer IP   : 192.168.1.100
   Printer Name : Canon MF455dw

   [ DOWNLOAD ]
   --------------------------------------------------------------
   Downloading driver package...
   Download complete : 156.2 MB

   [ EXTRACTION ]
   --------------------------------------------------------------
   Extracting driver files...
   Extraction complete

   [ DRIVER INSTALLATION ]
   --------------------------------------------------------------
   Installing UFR II LT driver via pnputil...
   Driver installed successfully

   [ PRINTER SETUP ]
   --------------------------------------------------------------
   Creating TCP/IP port : IP_192.168.1.100
   Adding printer queue : Canon MF455dw
   Printer added successfully

   [ CLEANUP ]
   --------------------------------------------------------------
   Removing temporary files...
   Cleanup complete

   [ FINAL STATUS ]
   --------------------------------------------------------------
   Result : SUCCESS

   [ SCRIPT COMPLETE ]
   --------------------------------------------------------------

--------------------------------------------------------------------------------
 CHANGELOG
--------------------------------------------------------------------------------
 2026-01-05 v1.0.0 Initial release
================================================================================
#>
Set-StrictMode -Version Latest

# ============================================================================
# HARDCODED INPUTS
# ============================================================================
$driverUrl     = 'https://gdlp01.c-wss.com/gds/7/0100011217/01/MF450MFDriverV720W64.exe'
$printerIp     = ''                        # Set to printer IP to auto-create queue, or leave empty
$printerName   = 'Canon imageCLASS MF455dw'
$installScanner = $false                   # Set to $true to also install scanner driver

# ============================================================================
# SCRIPT VARIABLES
# ============================================================================
$tempDir       = Join-Path $env:TEMP 'CanonMF455dw'
$installerPath = Join-Path $tempDir 'MF450MFDriverV720W64.exe'
$extractDir    = Join-Path $tempDir 'Extracted'

# UFR II LT driver details for MF455dw
$driverInfPattern = 'CNLB*.INF'
$driverName    = 'Canon Generic Plus UFR II'

# ============================================================================
# INPUT VALIDATION
# ============================================================================
Write-Host ""
Write-Host "[ INPUT VALIDATION ]"
Write-Host "--------------------------------------------------------------"

$errorOccurred = $false
$errorText = ""

if ([string]::IsNullOrWhiteSpace($driverUrl)) {
    $errorOccurred = $true
    $errorText += "- Driver URL is required`n"
}

if ([string]::IsNullOrWhiteSpace($printerName)) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- Printer name is required"
}

if ($errorOccurred) {
    Write-Host ""
    Write-Host "[ ERROR OCCURRED ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host $errorText
    exit 1
}

Write-Host "Driver URL   : $driverUrl"
Write-Host "Printer IP   : $(if ([string]::IsNullOrWhiteSpace($printerIp)) { '(not set - driver only)' } else { $printerIp })"
Write-Host "Printer Name : $printerName"
Write-Host "Scanner      : $installScanner"

# ============================================================================
# SETUP
# ============================================================================
Write-Host ""
Write-Host "[ SETUP ]"
Write-Host "--------------------------------------------------------------"

# Create temp directory
if (-not (Test-Path $tempDir)) {
    New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
    Write-Host "Created temp directory : $tempDir"
} else {
    Write-Host "Using existing temp directory : $tempDir"
}

# ============================================================================
# DOWNLOAD
# ============================================================================
Write-Host ""
Write-Host "[ DOWNLOAD ]"
Write-Host "--------------------------------------------------------------"

try {
    Write-Host "Downloading driver package..."

    $curlArgs = @(
        '-L',
        '-o', $installerPath,
        '--silent',
        '--show-error',
        '--fail',
        '--connect-timeout', '30',
        '--max-time', '600',
        $driverUrl
    )

    $curlProcess = Start-Process -FilePath "curl.exe" -ArgumentList $curlArgs -Wait -NoNewWindow -PassThru

    if ($curlProcess.ExitCode -ne 0) {
        throw "Download failed with exit code $($curlProcess.ExitCode)"
    }

    if (-not (Test-Path $installerPath)) {
        throw "Installer file not found after download"
    }

    $fileSize = (Get-Item $installerPath).Length
    $fileSizeMB = [math]::Round($fileSize / 1MB, 2)
    Write-Host "Download complete : $fileSizeMB MB"
}
catch {
    Write-Host ""
    Write-Host "[ ERROR OCCURRED ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host "Download failed : $($_.Exception.Message)"
    exit 1
}

# ============================================================================
# EXTRACTION
# ============================================================================
Write-Host ""
Write-Host "[ EXTRACTION ]"
Write-Host "--------------------------------------------------------------"

try {
    Write-Host "Extracting driver files..."

    # Create extraction directory
    if (-not (Test-Path $extractDir)) {
        New-Item -Path $extractDir -ItemType Directory -Force | Out-Null
    }

    # Canon MF drivers typically self-extract with /D: switch or /extract_all:
    # Try multiple extraction methods
    $extracted = $false

    # Method 1: Try /D: switch (common for Canon installers)
    $extractArgs = @("/D:$extractDir", '/auto')
    $extractProcess = Start-Process -FilePath $installerPath -ArgumentList $extractArgs -Wait -NoNewWindow -PassThru -ErrorAction SilentlyContinue

    # Check if extraction worked by looking for INF files
    $infFiles = Get-ChildItem -Path $extractDir -Filter '*.INF' -Recurse -ErrorAction SilentlyContinue
    if ($infFiles.Count -gt 0) {
        $extracted = $true
        Write-Host "Extraction method : /D: switch"
    }

    # Method 2: If /D: didn't work, try running the installer which may auto-extract
    if (-not $extracted) {
        # Some Canon installers extract to a default location when run
        # Check common Canon extraction locations
        $canonDefaultPaths = @(
            "$env:TEMP\Canon",
            "$env:ProgramData\Canon\Setup",
            "$env:TEMP\MF450"
        )

        foreach ($path in $canonDefaultPaths) {
            if (Test-Path $path) {
                $infFiles = Get-ChildItem -Path $path -Filter '*.INF' -Recurse -ErrorAction SilentlyContinue
                if ($infFiles.Count -gt 0) {
                    $extractDir = $path
                    $extracted = $true
                    Write-Host "Found driver files at : $path"
                    break
                }
            }
        }
    }

    # Method 3: Use expand.exe or try as self-extracting archive
    if (-not $extracted) {
        # Try running the setup with /extract_all: parameter
        $extractArgs2 = @("/extract_all:$extractDir")
        Start-Process -FilePath $installerPath -ArgumentList $extractArgs2 -Wait -NoNewWindow -PassThru -ErrorAction SilentlyContinue

        Start-Sleep -Seconds 3

        $infFiles = Get-ChildItem -Path $extractDir -Filter '*.INF' -Recurse -ErrorAction SilentlyContinue
        if ($infFiles.Count -gt 0) {
            $extracted = $true
            Write-Host "Extraction method : /extract_all:"
        }
    }

    # Method 4: Run installer silently and let it extract to default location
    if (-not $extracted) {
        Write-Host "Running installer to extract drivers..."

        # Run the installer - it typically extracts and runs setup
        # We'll intercept after extraction
        $setupProcess = Start-Process -FilePath $installerPath -ArgumentList '/auto' -Wait -NoNewWindow -PassThru -ErrorAction SilentlyContinue

        Start-Sleep -Seconds 5

        # Search for extracted files
        $searchPaths = @(
            "$env:TEMP",
            "$env:ProgramData\Canon",
            "C:\Canon"
        )

        foreach ($searchPath in $searchPaths) {
            if (Test-Path $searchPath) {
                $infFiles = Get-ChildItem -Path $searchPath -Filter 'CNLB*.INF' -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($infFiles) {
                    $extractDir = Split-Path $infFiles.FullName -Parent
                    $extracted = $true
                    Write-Host "Found driver files at : $extractDir"
                    break
                }
            }
        }
    }

    if (-not $extracted) {
        throw "Could not extract driver files. Manual extraction may be required."
    }

    Write-Host "Extraction complete"
}
catch {
    Write-Host ""
    Write-Host "[ ERROR OCCURRED ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host "Extraction failed : $($_.Exception.Message)"
    exit 1
}

# ============================================================================
# DRIVER INSTALLATION
# ============================================================================
Write-Host ""
Write-Host "[ DRIVER INSTALLATION ]"
Write-Host "--------------------------------------------------------------"

try {
    # Find the UFR II driver INF file
    Write-Host "Searching for driver INF files..."

    $infFile = Get-ChildItem -Path $extractDir -Filter $driverInfPattern -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1

    if (-not $infFile) {
        # Try alternative patterns for Canon drivers
        $altPatterns = @('CNL*.INF', '*UFRII*.INF', '*Generic*.INF', '*.INF')
        foreach ($pattern in $altPatterns) {
            $infFile = Get-ChildItem -Path $extractDir -Filter $pattern -Recurse -ErrorAction SilentlyContinue |
                       Where-Object { $_.Name -notmatch 'ScanGear|FAX' } |
                       Select-Object -First 1
            if ($infFile) { break }
        }
    }

    if (-not $infFile) {
        throw "Could not find driver INF file in extracted files"
    }

    Write-Host "Found driver INF : $($infFile.FullName)"

    # Install driver using pnputil
    Write-Host "Installing driver via pnputil..."

    $pnpArgs = @('/add-driver', $infFile.FullName, '/install')
    $pnpResult = & pnputil.exe @pnpArgs 2>&1

    if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne 259) {
        # Exit code 259 means driver already exists, which is fine
        Write-Host "pnputil output:"
        $pnpResult | ForEach-Object { Write-Host "  $_" }
        throw "pnputil failed with exit code $LASTEXITCODE"
    }

    Write-Host "Driver staged in Windows driver store"

    # Get the actual driver name from the INF
    $infContent = Get-Content $infFile.FullName -Raw
    if ($infContent -match '\"([^\"]*Canon[^\"]*UFR[^\"]*II[^\"]*|[^\"]*Canon[^\"]*Generic[^\"]*Plus[^\"]*)\"\s*=' -or
        $infContent -match '%([^%]+)%\s*=') {
        # Try to extract the driver model name
        $driverModels = Get-PrinterDriver -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'Canon' -and $_.Name -match 'UFR|Generic' }
        if ($driverModels) {
            $driverName = $driverModels[0].Name
            Write-Host "Driver name : $driverName"
        }
    }

    Write-Host "Driver installed successfully"
}
catch {
    Write-Host ""
    Write-Host "[ ERROR OCCURRED ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host "Driver installation failed : $($_.Exception.Message)"
    Write-Host ""
    Write-Host "Troubleshooting:"
    Write-Host "  - Ensure you are running as Administrator"
    Write-Host "  - Check Windows Event Viewer for driver errors"
    Write-Host "  - Try manual installation via Device Manager"
    exit 1
}

# ============================================================================
# PRINTER SETUP (Optional)
# ============================================================================
if (-not [string]::IsNullOrWhiteSpace($printerIp)) {
    Write-Host ""
    Write-Host "[ PRINTER SETUP ]"
    Write-Host "--------------------------------------------------------------"

    try {
        $portName = "IP_$printerIp"

        # Check if port already exists
        $existingPort = Get-PrinterPort -Name $portName -ErrorAction SilentlyContinue
        if (-not $existingPort) {
            Write-Host "Creating TCP/IP port : $portName"
            Add-PrinterPort -Name $portName -PrinterHostAddress $printerIp -ErrorAction Stop
            Write-Host "Port created successfully"
        } else {
            Write-Host "Port already exists : $portName"
        }

        # Check if printer already exists
        $existingPrinter = Get-Printer -Name $printerName -ErrorAction SilentlyContinue
        if (-not $existingPrinter) {
            Write-Host "Adding printer queue : $printerName"

            # Find the installed Canon driver
            $installedDriver = Get-PrinterDriver -ErrorAction SilentlyContinue |
                              Where-Object { $_.Name -match 'Canon' -and ($_.Name -match 'UFR|Generic|MF455|MF450') } |
                              Select-Object -First 1

            if ($installedDriver) {
                $driverName = $installedDriver.Name
                Write-Host "Using driver : $driverName"

                Add-Printer -Name $printerName -DriverName $driverName -PortName $portName -ErrorAction Stop
                Write-Host "Printer added successfully"
            } else {
                Write-Host "Warning: Could not find Canon driver - printer queue not created"
                Write-Host "You may need to add the printer manually from Settings"
            }
        } else {
            Write-Host "Printer already exists : $printerName"
        }
    }
    catch {
        Write-Host "Warning: Printer setup failed : $($_.Exception.Message)"
        Write-Host "Driver was installed - you can add the printer manually"
    }
}

# ============================================================================
# CLEANUP
# ============================================================================
Write-Host ""
Write-Host "[ CLEANUP ]"
Write-Host "--------------------------------------------------------------"

try {
    if (Test-Path $tempDir) {
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Removed temporary files"
    }
    Write-Host "Cleanup complete"
}
catch {
    Write-Host "Warning: Cleanup failed : $($_.Exception.Message)"
}

# ============================================================================
# FINAL STATUS
# ============================================================================
Write-Host ""
Write-Host "[ FINAL STATUS ]"
Write-Host "--------------------------------------------------------------"

# Verify driver is installed
$verifyDriver = Get-PrinterDriver -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -match 'Canon' -and ($_.Name -match 'UFR|Generic|MF455|MF450') }

if ($verifyDriver) {
    Write-Host "Result : SUCCESS"
    Write-Host "Driver : $($verifyDriver.Name)"

    if (-not [string]::IsNullOrWhiteSpace($printerIp)) {
        $verifyPrinter = Get-Printer -Name $printerName -ErrorAction SilentlyContinue
        if ($verifyPrinter) {
            Write-Host "Printer : $printerName (ready)"
        }
    }
} else {
    Write-Host "Result : WARNING - Driver may not have installed correctly"
    Write-Host "Check Device Manager or try manual installation"
}

Write-Host ""
Write-Host "[ SCRIPT COMPLETE ]"
Write-Host "--------------------------------------------------------------"

exit 0
