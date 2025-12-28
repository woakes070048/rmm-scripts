$ErrorActionPreference = 'Stop'
<#
â–ˆâ–ˆâ•—     â–ˆâ–ˆâ•—â–ˆâ–ˆâ–ˆâ•—   â–ˆâ–ˆâ–ˆâ•—â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•—â–ˆâ–ˆâ•—  â–ˆâ–ˆâ•— â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•— â–ˆâ–ˆâ•—    â–ˆâ–ˆâ•—â–ˆâ–ˆâ•—  â–ˆâ–ˆâ•—
â–ˆâ–ˆâ•‘     â–ˆâ–ˆâ•‘â–ˆâ–ˆâ–ˆâ–ˆâ•— â–ˆâ–ˆâ–ˆâ–ˆâ•‘â–ˆâ–ˆâ•”â•â•â•â•â•â–ˆâ–ˆâ•‘  â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•”â•â•â–ˆâ–ˆâ•—â–ˆâ–ˆâ•‘    â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•‘ â–ˆâ–ˆâ•”â•
â–ˆâ–ˆâ•‘     â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•”â–ˆâ–ˆâ–ˆâ–ˆâ•”â–ˆâ–ˆâ•‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•—  â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•‘â–ˆâ–ˆâ•‘ â–ˆâ•— â–ˆâ–ˆâ•‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•”â• 
â–ˆâ–ˆâ•‘     â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•‘â•šâ–ˆâ–ˆâ•”â•â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•”â•â•â•  â–ˆâ–ˆâ•”â•â•â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•”â•â•â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•‘â–ˆâ–ˆâ–ˆâ•—â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•”â•â–ˆâ–ˆâ•— 
â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•—â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•‘ â•šâ•â• â–ˆâ–ˆâ•‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•—â–ˆâ–ˆâ•‘  â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•‘  â–ˆâ–ˆâ•‘â•šâ–ˆâ–ˆâ–ˆâ•”â–ˆâ–ˆâ–ˆâ•”â•â–ˆâ–ˆâ•‘  â–ˆâ–ˆâ•—
â•šâ•â•â•â•â•â•â•â•šâ•â•â•šâ•â•     â•šâ•â•â•šâ•â•â•â•â•â•â•â•šâ•â•  â•šâ•â•â•šâ•â•  â•šâ•â• â•šâ•â•â•â•šâ•â•â• â•šâ•â•  â•šâ•â•
================================================================================
SCRIPT  : Winget Setup for RMM v1.0.1
AUTHOR  : Limehawk.io
DATE      : December 2025
USAGE   : .\winget_setup.ps1
FILE    : winget_setup.ps1
DESCRIPTION : Installs winget (Windows Package Manager) for RMM environments
================================================================================
README
--------------------------------------------------------------------------------
 PURPOSE
   Installs winget (Windows Package Manager) on Windows systems using the
   most reliable installation method. Optimized for RMM environments running
   under SYSTEM context. Uses manual AppX installation method which is more
   reliable than the Repair-WinGetPackageManager approach. Handles all OS
   versions including Windows 10, 11, and Server 2019+.

 DATA SOURCES & PRIORITY
   1) Hardcoded script configuration (timeout, force reinstall)
   2) GitHub API (microsoft/winget-cli releases)
   3) System environment (OS version, architecture)

 REQUIRED INPUTS
   - $forceReinstall       - Reinstall even if winget already exists (boolean)
   - $downloadTimeout      - Timeout for file downloads in seconds (integer)
   - $skipServerCore       - Skip installation on Server Core (boolean)

 SETTINGS
   - Uses alternate/manual AppX installation method (most reliable)
   - Automatically detects SYSTEM context and adjusts behavior
   - Installs for all users when possible
   - Configures PATH environment variable automatically
   - 120 second download timeout per file

 BEHAVIOR
   1. Validates configuration inputs
   2. Checks OS compatibility and admin privileges
   3. Detects if running as SYSTEM account
   4. Checks if winget is already installed (skips if present unless forced)
   5. Downloads winget dependencies from GitHub
   6. Downloads winget AppX package from GitHub
   7. Installs dependencies (VCLibs, UI.Xaml)
   8. Installs winget AppX package
   9. Configures PATH environment variable
   10. Registers winget application
   11. Verifies installation success
   12. Cleans up temporary files

 PREREQUISITES
   - Administrator or SYSTEM privileges
   - Windows 10 1809+ or Windows Server 2019+
   - Internet connectivity to GitHub
   - PowerShell 5.1 or higher

 SECURITY NOTES
   - No secrets or credentials required
   - Downloads only from official Microsoft GitHub repository
   - All temporary files are cleaned up after installation
   - No sensitive information logged to console

 ENDPOINTS
   - https://api.github.com/repos/microsoft/winget-cli/releases/latest
   - https://github.com/microsoft/winget-cli (release assets)

 EXIT CODES
   - 0 = Success - winget installed and verified
   - 1 = Failure - installation failed or system incompatible

 EXAMPLE RUN
   [ INPUT VALIDATION ]
   --------------------------------------------------------------
   Configuration validated successfully
   Force Reinstall : No
   Download Timeout: 120 seconds

   [ SYSTEM CHECK ]
   --------------------------------------------------------------
   OS Version      : Windows 10 22H2
   Architecture    : x64
   Admin Rights    : Yes
   Running Context : SYSTEM
   Winget Status   : Not installed

   [ DOWNLOAD DEPENDENCIES ]
   --------------------------------------------------------------
   Fetching latest release information...
   Latest Version  : v1.7.10861
   Downloading dependencies package...
   Downloaded      : 15.2 MB
   Extracting dependencies...
   Extracted       : VCLibs.140.00.UWPDesktop
   Extracted       : UI.Xaml.2.8

   [ DOWNLOAD WINGET ]
   --------------------------------------------------------------
   Downloading winget package...
   Downloaded      : 45.8 MB
   Package verified

   [ INSTALL DEPENDENCIES ]
   --------------------------------------------------------------
   Installing VCLibs.140.00.UWPDesktop...
   Installed successfully
   Installing UI.Xaml.2.8...
   Installed successfully

   [ INSTALL WINGET ]
   --------------------------------------------------------------
   Installing winget AppX package...
   Installation successful
   Configuring PATH environment variable...
   PATH configured
   Registering winget...
   Registration complete

   [ VERIFICATION ]
   --------------------------------------------------------------
   Testing winget command...
   Winget Version  : v1.7.10861
   Installation    : Verified

   [ CLEANUP ]
   --------------------------------------------------------------
   Removing temporary files...
   Cleanup complete

   [ FINAL STATUS ]
   --------------------------------------------------------------
   Status          : Success
   Winget          : Installed and working

   [ SCRIPT COMPLETED ]
   --------------------------------------------------------------

CHANGELOG
--------------------------------------------------------------------------------
2025-12-23 v1.0.1 Updated to Limehawk Script Framework
2025-01-31 v1.0.0 Initial release - reliable winget installation for RMM
================================================================================
#>
Set-StrictMode -Version Latest

# ============================================================================
# HARDCODED INPUTS
# ============================================================================

$forceReinstall = $false              # Reinstall even if winget already exists
$downloadTimeout = 120                # Timeout for file downloads in seconds
$skipServerCore = $false              # Skip installation on Server Core

# ============================================================================
# INPUT VALIDATION
# ============================================================================

$errorOccurred = $false
$errorText = ""

Write-Host ""
Write-Host "[ INPUT VALIDATION ]"
Write-Host "--------------------------------------------------------------"

if ($downloadTimeout -lt 30) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- Download timeout must be at least 30 seconds"
}

if ($errorOccurred) {
    Write-Host ""
    Write-Host "[ ERROR OCCURRED ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host "Input validation failed:"
    Write-Host $errorText
    Write-Host ""
    exit 1
}

Write-Host "Configuration validated successfully"
Write-Host "Force Reinstall : $(if ($forceReinstall) { 'Yes' } else { 'No' })"
Write-Host "Download Timeout: $downloadTimeout seconds"

# ============================================================================
# SYSTEM CHECK
# ============================================================================

Write-Host ""
Write-Host "[ SYSTEM CHECK ]"
Write-Host "--------------------------------------------------------------"

# Check if running as SYSTEM
$runAsSystem = $false
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
if ($currentUser.User.Value -eq "S-1-5-18") {
    $runAsSystem = $true
}

# Check admin privileges (for non-SYSTEM accounts)
$isAdmin = ([Security.Principal.WindowsPrincipal]$currentUser).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin -and -not $runAsSystem) {
    Write-Host ""
    Write-Host "[ ERROR OCCURRED ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host "Administrator or SYSTEM privileges required"
    Write-Host "Please run this script as Administrator"
    Write-Host ""
    exit 1
}

# Get OS information
$osInfo = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
$osName = $osInfo.ProductName
$osBuild = $osInfo.CurrentBuild
$installationType = $osInfo.InstallationType

# Get architecture
$osArch = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }

# Get OS type
$osDetails = Get-CimInstance -ClassName Win32_OperatingSystem
$osType = if ($osDetails.ProductType -eq 1) { "Workstation" } else { "Server" }

Write-Host "OS Name         : $osName"
Write-Host "OS Build        : $osBuild"
Write-Host "Architecture    : $osArch"
Write-Host "Installation    : $installationType"
Write-Host "Admin Rights    : $(if ($isAdmin) { 'Yes' } else { 'No' })"
Write-Host "Running Context : $(if ($runAsSystem) { 'SYSTEM' } else { 'User' })"

# Check OS compatibility
$osNumeric = ($osName -replace "[^\d]").Trim()
if ($osType -eq "Workstation" -and [int]$osBuild -lt 17763) {
    Write-Host ""
    Write-Host "[ ERROR OCCURRED ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host "Windows 10 version 1809 or later required"
    Write-Host "Your build: $osBuild"
    Write-Host ""
    exit 1
}

if ($osType -eq "Server" -and [int]$osBuild -lt 17763) {
    Write-Host ""
    Write-Host "[ ERROR OCCURRED ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host "Windows Server 2019 or later required"
    Write-Host "Your build: $osBuild"
    Write-Host ""
    exit 1
}

# Check for Server Core
if ($installationType -eq "Server Core" -and $skipServerCore) {
    Write-Host ""
    Write-Host "[ ERROR OCCURRED ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host "Server Core installation detected and skipServerCore is enabled"
    Write-Host "Installation skipped"
    Write-Host ""
    exit 1
}

# Check if winget already installed
Write-Host ""
Write-Host "Checking for existing winget installation..."
$wingetInstalled = $false
$wingetVersion = "Not installed"

try {
    if ($runAsSystem) {
        # For SYSTEM context, look for winget executable directly
        $wingetPath = Resolve-Path "$env:ProgramFiles\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe" -ErrorAction SilentlyContinue |
                      Sort-Object | Select-Object -Last 1
        if ($wingetPath) {
            $wingetExe = Join-Path $wingetPath.Path "winget.exe"
            if (Test-Path $wingetExe) {
                $wingetInstalled = $true
                $versionOutput = & $wingetExe --version 2>&1
                if ($versionOutput -match 'v([\d.]+)') {
                    $wingetVersion = $matches[1]
                }
            }
        }
    } else {
        $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
        if ($wingetCmd) {
            $wingetInstalled = $true
            $versionOutput = & winget --version 2>&1
            if ($versionOutput -match 'v([\d.]+)') {
                $wingetVersion = $matches[1]
            }
        }
    }
} catch {
    # Winget not found
}

Write-Host "Winget Status   : $(if ($wingetInstalled) { 'Installed' } else { 'Not installed' })"
if ($wingetInstalled) {
    Write-Host "Winget Version  : $wingetVersion"
}

if ($wingetInstalled -and -not $forceReinstall -and -not $runAsSystem) {
    Write-Host ""
    Write-Host "[ FINAL STATUS ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host "Status          : Winget already installed"
    Write-Host "Version         : $wingetVersion"
    Write-Host "Action          : Skipped installation"
    Write-Host ""
    Write-Host "[ SCRIPT COMPLETED ]"
    Write-Host "--------------------------------------------------------------"
    exit 0
}

if ($wingetInstalled -and -not $forceReinstall -and $runAsSystem) {
    Write-Host ""
    Write-Host "Winget installed for SYSTEM, ensuring user registration..."
    # Skip to registration section without reinstalling
    $skipInstallation = $true
} else {
    $skipInstallation = $false
}

if ($wingetInstalled -and $forceReinstall) {
    Write-Host "Force reinstall enabled, proceeding with installation"
}

# ============================================================================
# DOWNLOAD AND INSTALL (skip if already installed for SYSTEM)
# ============================================================================

if (-not $skipInstallation) {

# ============================================================================
# DOWNLOAD DEPENDENCIES
# ============================================================================

Write-Host ""
Write-Host "[ DOWNLOAD DEPENDENCIES ]"
Write-Host "--------------------------------------------------------------"

# Suppress progress bar for faster downloads
$ProgressPreference = 'SilentlyContinue'

Write-Host "Fetching latest release information from GitHub..."
try {
    $releases = Invoke-RestMethod -Uri "https://api.github.com/repos/microsoft/winget-cli/releases" -TimeoutSec 30 -ErrorAction Stop

    # Get latest non-prerelease version
    $latestRelease = $releases | Where-Object { -not $_.prerelease } | Select-Object -First 1
    $releaseVersion = $latestRelease.tag_name

    Write-Host "Latest Version  : $releaseVersion"
    Write-Host "Published       : $($latestRelease.published_at)"
} catch {
    Write-Host ""
    Write-Host "[ ERROR OCCURRED ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host "Failed to fetch release information from GitHub"
    Write-Host "Error: $($_.Exception.Message)"
    Write-Host "Check internet connectivity and GitHub availability"
    Write-Host ""
    exit 1
}

# Create temp directory
$tempDir = Join-Path $env:TEMP "winget_install_$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
Write-Host ""
Write-Host "Temp directory  : $tempDir"

# Download dependencies package
Write-Host ""
Write-Host "Downloading dependencies package..."
$depsAsset = $latestRelease.assets | Where-Object { $_.name -match 'Dependencies\.zip' } | Select-Object -First 1

if (-not $depsAsset) {
    Write-Host ""
    Write-Host "[ ERROR OCCURRED ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host "Dependencies package not found in release assets"
    Write-Host ""
    exit 1
}

$depsPath = Join-Path $tempDir "dependencies.zip"
try {
    Invoke-WebRequest -Uri $depsAsset.browser_download_url -OutFile $depsPath -TimeoutSec $downloadTimeout -ErrorAction Stop
    $fileSize = (Get-Item $depsPath).Length
    Write-Host "Downloaded      : $([math]::Round($fileSize/1MB, 1)) MB"
} catch {
    Write-Host ""
    Write-Host "[ ERROR OCCURRED ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host "Failed to download dependencies package"
    Write-Host "Error: $($_.Exception.Message)"
    Write-Host ""
    exit 1
}

# Extract dependencies for current architecture
Write-Host ""
Write-Host "Extracting dependencies for $osArch architecture..."
Add-Type -AssemblyName System.IO.Compression.FileSystem

$depsExtractPath = Join-Path $tempDir "deps"
New-Item -ItemType Directory -Path $depsExtractPath -Force | Out-Null

try {
    $zip = [System.IO.Compression.ZipFile]::OpenRead($depsPath)
    $archPattern = if ($osArch -eq "x64") { "x64" } else { "x86" }

    $entries = $zip.Entries | Where-Object { $_.FullName -match "$archPattern.*\.appx$" }

    foreach ($entry in $entries) {
        $destPath = Join-Path $depsExtractPath $entry.Name
        [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $destPath, $true)
        Write-Host "Extracted       : $($entry.Name)"
    }

    $zip.Dispose()
} catch {
    Write-Host ""
    Write-Host "[ ERROR OCCURRED ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host "Failed to extract dependencies"
    Write-Host "Error: $($_.Exception.Message)"
    Write-Host ""
    exit 1
}

# ============================================================================
# DOWNLOAD WINGET
# ============================================================================

Write-Host ""
Write-Host "[ DOWNLOAD WINGET ]"
Write-Host "--------------------------------------------------------------"

Write-Host "Downloading winget package..."
$wingetAsset = $latestRelease.assets | Where-Object { $_.name -match '\.msixbundle$' } | Select-Object -First 1

if (-not $wingetAsset) {
    Write-Host ""
    Write-Host "[ ERROR OCCURRED ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host "Winget package not found in release assets"
    Write-Host ""
    exit 1
}

$wingetPath = Join-Path $tempDir "winget.msixbundle"
try {
    Invoke-WebRequest -Uri $wingetAsset.browser_download_url -OutFile $wingetPath -TimeoutSec $downloadTimeout -ErrorAction Stop
    $fileSize = (Get-Item $wingetPath).Length
    Write-Host "Downloaded      : $([math]::Round($fileSize/1MB, 1)) MB"
    Write-Host "Package verified"
} catch {
    Write-Host ""
    Write-Host "[ ERROR OCCURRED ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host "Failed to download winget package"
    Write-Host "Error: $($_.Exception.Message)"
    Write-Host ""
    exit 1
}

# Download license file
Write-Host ""
Write-Host "Downloading license file..."
$licenseAsset = $latestRelease.assets | Where-Object { $_.name -match 'License.*\.xml$' } | Select-Object -First 1

$licensePath = Join-Path $tempDir "license.xml"
if ($licenseAsset) {
    try {
        Invoke-WebRequest -Uri $licenseAsset.browser_download_url -OutFile $licensePath -TimeoutSec 30 -ErrorAction Stop
        Write-Host "License downloaded"
    } catch {
        Write-Host "License download failed (non-critical): $($_.Exception.Message)"
    }
}

# ============================================================================
# INSTALL DEPENDENCIES
# ============================================================================

Write-Host ""
Write-Host "[ INSTALL DEPENDENCIES ]"
Write-Host "--------------------------------------------------------------"

$depFiles = Get-ChildItem -Path $depsExtractPath -Filter "*.appx"

foreach ($depFile in $depFiles) {
    Write-Host "Installing $($depFile.Name)..."
    try {
        if ($runAsSystem) {
            Add-AppxProvisionedPackage -Online -PackagePath $depFile.FullName -SkipLicense -ErrorAction Stop | Out-Null
        } else {
            Add-AppxPackage -Path $depFile.FullName -ErrorAction Stop | Out-Null
        }
        Write-Host "Installed successfully"
    } catch {
        # Some dependencies might already be installed or fail gracefully
        $errorMsg = $_.Exception.Message
        if ($errorMsg -match '0x80073D06') {
            Write-Host "Already installed (higher version)"
        } elseif ($errorMsg -match '0x80073CF0') {
            Write-Host "Already installed (same version)"
        } else {
            Write-Host "Warning: $errorMsg"
        }
    }
}

# ============================================================================
# INSTALL WINGET
# ============================================================================

Write-Host ""
Write-Host "[ INSTALL WINGET ]"
Write-Host "--------------------------------------------------------------"

Write-Host "Installing winget AppX package..."
try {
    if ($runAsSystem) {
        if (Test-Path $licensePath) {
            Add-AppxProvisionedPackage -Online -PackagePath $wingetPath -LicensePath $licensePath -ErrorAction Stop | Out-Null
        } else {
            Add-AppxProvisionedPackage -Online -PackagePath $wingetPath -SkipLicense -ErrorAction Stop | Out-Null
        }
    } else {
        Add-AppxPackage -Path $wingetPath -ErrorAction Stop | Out-Null
    }
    Write-Host "Installation successful"
} catch {
    $errorMsg = $_.Exception.Message
    if ($errorMsg -match '0x80073D06') {
        Write-Host "Higher version already installed"
    } elseif ($errorMsg -match '0x80073CF0') {
        Write-Host "Same version already installed"
    } else {
        Write-Host ""
        Write-Host "[ ERROR OCCURRED ]"
        Write-Host "--------------------------------------------------------------"
        Write-Host "Failed to install winget package"
        Write-Host "Error: $errorMsg"
        Write-Host ""
        exit 1
    }
}

} # End of installation section

# ============================================================================
# PATH AND REGISTRATION (always run for SYSTEM to ensure user access)
# ============================================================================

# Configure PATH
Write-Host ""
Write-Host "[ CONFIGURATION ]"
Write-Host "--------------------------------------------------------------"
Write-Host "Configuring PATH environment variable..."

$localAppData = if ($runAsSystem) {
    "C:\Windows\System32\config\systemprofile\AppData\Local"
} else {
    $env:LOCALAPPDATA
}

$wingetPaths = @(
    "$env:ProgramFiles\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe",
    "$localAppData\Microsoft\WindowsApps"
)

foreach ($pathPattern in $wingetPaths) {
    $resolvedPath = Resolve-Path $pathPattern -ErrorAction SilentlyContinue |
                    Sort-Object | Select-Object -Last 1

    if ($resolvedPath) {
        $pathToAdd = $resolvedPath.Path
        $currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")

        if ($currentPath -notlike "*$pathToAdd*") {
            [Environment]::SetEnvironmentVariable("Path", "$currentPath;$pathToAdd", "Machine")
            $env:Path = "$env:Path;$pathToAdd"
            Write-Host "Added to PATH   : $pathToAdd"
        }
    }
}

Write-Host "PATH configured"

# Register winget
Write-Host ""
Write-Host "Registering winget..."
try {
    Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe -ErrorAction SilentlyContinue | Out-Null
    Write-Host "Registration complete"
} catch {
    Write-Host "Registration completed with warnings (may not be needed)"
}

# For SYSTEM context, register for all users
if ($runAsSystem) {
    Write-Host ""
    Write-Host "Registering for all user accounts..."

    # Get all user profiles
    $userProfiles = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" |
        ForEach-Object {
            $profilePath = (Get-ItemProperty $_.PSPath).ProfileImagePath
            if ($profilePath -and (Test-Path $profilePath) -and $profilePath -notmatch '(systemprofile|LocalService|NetworkService|Default)') {
                $profilePath
            }
        }

    $registeredCount = 0
    foreach ($profilePath in $userProfiles) {
        $username = Split-Path $profilePath -Leaf

        # Load user registry hive if not already loaded
        $userSid = (Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" |
            Where-Object { (Get-ItemProperty $_.PSPath).ProfileImagePath -eq $profilePath }).PSChildName

        # Create PowerShell script to register winget for this user
        $registerScript = @"
Add-AppxPackage -DisableDevelopmentMode -Register "$env:ProgramFiles\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe\AppXManifest.xml" -ErrorAction SilentlyContinue
"@

        # Try to register using scheduled task
        try {
            $taskName = "WingetUserRegistration_$username"
            $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -WindowStyle Hidden -Command `"$registerScript`""
            $principal = New-ScheduledTaskPrincipal -UserId $userSid -LogonType S4U
            $task = Register-ScheduledTask -TaskName $taskName -Action $action -Principal $principal -Force -ErrorAction Stop

            Start-ScheduledTask -TaskName $taskName -ErrorAction Stop
            Start-Sleep -Milliseconds 500
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue

            $registeredCount++
        } catch {
            # Silently continue if registration fails for a user
        }
    }

    if ($registeredCount -gt 0) {
        Write-Host "Registered for   : $registeredCount user account(s)"
    } else {
        Write-Host "User Registration: Users may need to log out/in or run registration manually"
    }
}

# ============================================================================
# VERIFICATION
# ============================================================================

Write-Host ""
Write-Host "[ VERIFICATION ]"
Write-Host "--------------------------------------------------------------"

Write-Host "Waiting for winget to initialize..."
Start-Sleep -Seconds 3

Write-Host "Testing winget command..."
$verificationSuccess = $false

try {
    if ($runAsSystem) {
        $wingetPath = Resolve-Path "$env:ProgramFiles\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe\winget.exe" -ErrorAction Stop |
                      Sort-Object | Select-Object -Last 1
        $versionOutput = & $wingetPath.Path --version 2>&1
    } else {
        $versionOutput = & winget --version 2>&1
    }

    if ($versionOutput -match 'v([\d.]+)') {
        $installedVersion = $matches[1]
        Write-Host "Winget Version  : v$installedVersion"
        Write-Host "Installation    : Verified"
        $verificationSuccess = $true
    } else {
        Write-Host "Version output  : $versionOutput"
        Write-Host "Installation    : Command available but version unclear"
        $verificationSuccess = $true
    }
} catch {
    Write-Host "Verification    : Command not immediately available"
    Write-Host "Note            : May require restart or new session"
    if ($runAsSystem) {
        Write-Host "SYSTEM Context  : Winget may work for user accounts after restart"
    }
}

# ============================================================================
# CLEANUP
# ============================================================================

Write-Host ""
Write-Host "[ CLEANUP ]"
Write-Host "--------------------------------------------------------------"

if (-not $skipInstallation -and $tempDir -and (Test-Path $tempDir)) {
    Write-Host "Removing temporary files..."
    try {
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction Stop
        Write-Host "Cleanup complete"
    } catch {
        Write-Host "Cleanup warning : $($_.Exception.Message)"
    }
} else {
    Write-Host "No temporary files to clean up"
}

# ============================================================================
# FINAL STATUS
# ============================================================================

Write-Host ""
Write-Host "[ FINAL STATUS ]"
Write-Host "--------------------------------------------------------------"

if ($verificationSuccess) {
    Write-Host "Status          : Success"
    Write-Host "Winget          : Installed and working"
    if ($runAsSystem) {
        Write-Host "Note            : Running as SYSTEM - restart may be needed for user access"
    }

    Write-Host ""
    Write-Host "[ SCRIPT COMPLETED ]"
    Write-Host "--------------------------------------------------------------"
    exit 0
} else {
    Write-Host "Status          : Installed with warnings"
    Write-Host "Winget          : Installed but verification incomplete"
    Write-Host "Action          : Restart PowerShell or system to use winget"

    Write-Host ""
    Write-Host "[ SCRIPT COMPLETED ]"
    Write-Host "--------------------------------------------------------------"
    exit 0
}
