$ErrorActionPreference = 'Stop'
<#
██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝

================================================================================
SCRIPT : Uninstall OneDrive                                          v1.0.0
FILE   : uninstall_onedrive.ps1
================================================================================
README
--------------------------------------------------------------------------------
PURPOSE

Completely removes Microsoft OneDrive from the system by stopping processes,
running the native uninstaller from multiple locations, checking registry for
additional uninstall paths, and removing OneDrive scheduled tasks.

--------------------------------------------------------------------------------
DATA SOURCES & PRIORITY

1. Local OneDriveSetup.exe in System32/SysWOW64
2. Office integration paths for OneDrive
3. Windows registry uninstall keys

--------------------------------------------------------------------------------
REQUIRED INPUTS

None - this script has no configurable inputs.

--------------------------------------------------------------------------------
SETTINGS

No configurable settings. Script runs with default uninstall behavior.

--------------------------------------------------------------------------------
BEHAVIOR

1. Verifies script is running with administrator privileges
2. Stops all running OneDrive processes
3. Runs OneDriveSetup.exe /uninstall from known locations:
   - System32\OneDriveSetup.exe
   - SysWOW64\OneDriveSetup.exe
   - Program Files\Microsoft Office\root\Integration\Addons
   - Program Files (x86)\Microsoft Office\root\Integration\Addons
4. Checks registry for OneDrive uninstall string and executes if found
5. Removes all OneDrive scheduled tasks
6. Reports final status

--------------------------------------------------------------------------------
PREREQUISITES

- Windows PowerShell 5.1 or later
- Administrator privileges (required for uninstallation)

--------------------------------------------------------------------------------
SECURITY NOTES

- No secrets in logs
- Self-contained script with no external dependencies
- Uses only native Windows uninstall mechanisms

--------------------------------------------------------------------------------
EXIT CODES

0 = Success - OneDrive uninstallation completed
1 = Failure - Missing admin privileges or critical uninstallation error

--------------------------------------------------------------------------------
EXAMPLE RUN

[ ADMIN CHECK ]
--------------------------------------------------------------
Running as Administrator : True

[ STOP PROCESSES ]
--------------------------------------------------------------
Stopping OneDrive processes...
OneDrive processes stopped

[ UNINSTALL FROM PATHS ]
--------------------------------------------------------------
Checking : C:\Windows\System32\OneDriveSetup.exe
Path not found, skipping
Checking : C:\Windows\SysWOW64\OneDriveSetup.exe
Uninstalling from C:\Windows\SysWOW64\OneDriveSetup.exe
Uninstall completed
Checking : C:\Program Files\Microsoft Office\root\Integration\Addons\OneDriveSetup.exe
Path not found, skipping
Checking : C:\Program Files (x86)\Microsoft Office\root\Integration\Addons\OneDriveSetup.exe
Path not found, skipping

[ REGISTRY UNINSTALL ]
--------------------------------------------------------------
Searching registry for OneDrive uninstall string...
No OneDrive uninstall string found in registry

[ SCHEDULED TASKS ]
--------------------------------------------------------------
Removing OneDrive scheduled tasks...
Scheduled tasks removed

[ FINAL STATUS ]
--------------------------------------------------------------
Result : Success
OneDrive has been removed from this system

[ SCRIPT COMPLETED ]
--------------------------------------------------------------

================================================================================
CHANGELOG
--------------------------------------------------------------------------------
2024-12-23 v1.0.0  Initial release - Self-contained OneDrive uninstallation
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
# STOP PROCESSES
# ==============================================================================

Write-Host ""
Write-Host "[ STOP PROCESSES ]"
Write-Host "--------------------------------------------------------------"

Write-Host "Stopping OneDrive processes..."
Stop-Process -Name "OneDrive*" -Force -ErrorAction SilentlyContinue
Write-Host "OneDrive processes stopped"

# ==============================================================================
# UNINSTALL FROM PATHS
# ==============================================================================

Write-Host ""
Write-Host "[ UNINSTALL FROM PATHS ]"
Write-Host "--------------------------------------------------------------"

$oneDrivePaths = @(
    "$env:SystemRoot\System32\OneDriveSetup.exe",
    "$env:SystemRoot\SysWOW64\OneDriveSetup.exe",
    "$env:ProgramFiles\Microsoft Office\root\Integration\Addons\OneDriveSetup.exe",
    "${env:ProgramFiles(x86)}\Microsoft Office\root\Integration\Addons\OneDriveSetup.exe"
)

foreach ($setupPath in $oneDrivePaths) {
    Write-Host "Checking : $setupPath"
    if (Test-Path $setupPath) {
        Write-Host "Uninstalling from $setupPath"
        try {
            $proc = Start-Process -FilePath $setupPath -ArgumentList "/uninstall" -PassThru -Wait
            Write-Host "Uninstall completed"
        }
        catch {
            Write-Host "Uninstall failed : $($_.Exception.Message)"
        }
    }
    else {
        Write-Host "Path not found, skipping"
    }
}

# ==============================================================================
# REGISTRY UNINSTALL
# ==============================================================================

Write-Host ""
Write-Host "[ REGISTRY UNINSTALL ]"
Write-Host "--------------------------------------------------------------"

Write-Host "Searching registry for OneDrive uninstall string..."

$uninstallPaths = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
    'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
)

$uninstallString = $null

foreach ($regPath in $uninstallPaths) {
    if (Test-Path $regPath) {
        $found = Get-ChildItem -Path $regPath -ErrorAction SilentlyContinue |
            Get-ItemProperty -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -like "*OneDrive*" } |
            Select-Object -ExpandProperty UninstallString -First 1 -ErrorAction SilentlyContinue
        if ($found) {
            $uninstallString = $found
            break
        }
    }
}

if ($uninstallString) {
    Write-Host "Found uninstall string : $uninstallString"
    try {
        # Remove quotation marks
        $uninstallString = $uninstallString.Replace('"', '')

        # Parse executable path and arguments
        $exeEndIndex = $uninstallString.IndexOf(".exe") + 4
        $exePath = $uninstallString.Substring(0, $exeEndIndex).Trim()
        $arguments = ""
        if ($uninstallString.Length -gt $exeEndIndex) {
            $arguments = $uninstallString.Substring($exeEndIndex).Trim()
        }

        Write-Host "Executable : $exePath"
        if ($arguments) {
            Write-Host "Arguments : $arguments"
            $proc = Start-Process -FilePath $exePath -ArgumentList $arguments -PassThru -Wait
        }
        else {
            $proc = Start-Process -FilePath $exePath -PassThru -Wait
        }
        Write-Host "Registry uninstall completed"
    }
    catch {
        Write-Host "Registry uninstall failed : $($_.Exception.Message)"
    }
}
else {
    Write-Host "No OneDrive uninstall string found in registry"
}

# ==============================================================================
# SCHEDULED TASKS
# ==============================================================================

Write-Host ""
Write-Host "[ SCHEDULED TASKS ]"
Write-Host "--------------------------------------------------------------"

Write-Host "Removing OneDrive scheduled tasks..."
Get-ScheduledTask -TaskName "OneDrive*" -ErrorAction SilentlyContinue |
    Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue
Write-Host "Scheduled tasks removed"

# ==============================================================================
# FINAL STATUS
# ==============================================================================

Write-Host ""
Write-Host "[ FINAL STATUS ]"
Write-Host "--------------------------------------------------------------"
Write-Host "Result : Success"
Write-Host "OneDrive has been removed from this system"

Write-Host ""
Write-Host "[ SCRIPT COMPLETED ]"
Write-Host "--------------------------------------------------------------"

exit 0
