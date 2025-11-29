$ErrorActionPreference = 'Stop'

<#
██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
================================================================================
 SCRIPT   : DelProf2 Profile Cleanup v1.1.0
 VERSION  : v1.1.0
================================================================================
 FILE     : delprof2_profile_cleanup.ps1
--------------------------------------------------------------------------------
 README
--------------------------------------------------------------------------------
 PURPOSE

 Manages Windows user profiles using the DelProf2 utility. Supports multiple
 cleanup modes: delete all profiles, delete old profiles, keep specific
 profiles, or remove a specific profile.

 DATA SOURCES & PRIORITY

 1) Hardcoded values (mode, profile names, age threshold)
 2) Direct download from helgeklein.com

 REQUIRED INPUTS

 - Mode              : Operation mode (see below)
 - ProtectedProfiles : Profiles to never delete (comma-separated)
 - ProfileToKeep     : For "keep_only" mode - profile to preserve
 - ProfileToDelete   : For "delete_specific" mode - profile to remove
 - DaysOld           : For "older_than" mode - age threshold in days

 MODES

 - "delete_all"      : Delete all profiles except protected ones
 - "older_than"      : Delete profiles older than X days
 - "keep_only"       : Delete all except specified profile
 - "delete_specific" : Delete only the specified profile

 SETTINGS

 - Downloads DelProf2 directly from helgeklein.com (no Chocolatey required)
 - Caches executable in Windows TEMP directory
 - Always protects specified profiles (default: gaia, administrator)
 - Unattended mode (/u flag)

 BEHAVIOR

 1. Downloads/extracts DelProf2 if not cached
 2. Builds command based on selected mode
 3. Executes DelProf2 with appropriate flags
 4. Optionally cleans up cached files
 5. Reports results

 PREREQUISITES

 - Windows 10/11
 - Admin privileges required
 - Internet access for initial DelProf2 download

 SECURITY NOTES

 - DESTRUCTIVE OPERATION - profiles cannot be recovered
 - Downloads from official helgeklein.com source
 - No secrets in logs
 - Backup important data before running

 EXIT CODES

 - 0: Success
 - 1: Failure

 EXAMPLE RUN

 [ INPUT VALIDATION ]
 --------------------------------------------------------------
 Mode              : older_than
 Days Old          : 30
 Protected         : gaia, administrator

 [ OPERATION ]
 --------------------------------------------------------------
 Downloading DelProf2...
 Executing: DelProf2.exe /u /d:30 /ed:gaia /ed:administrator
 DelProf2 completed successfully

 [ RESULT ]
 --------------------------------------------------------------
 Status : Success

 [ SCRIPT COMPLETED ]
 --------------------------------------------------------------
--------------------------------------------------------------------------------
 CHANGELOG
 2025-11-29 v1.1.0 Removed Chocolatey dependency, direct download from source
 2025-11-29 v1.0.0 Initial Style A implementation (consolidated 4 scripts)
================================================================================
#>

Set-StrictMode -Version Latest

# ==== STATE ====
$errorOccurred = $false
$errorText = ""
$delprof2Output = ""

# ==== HARDCODED INPUTS ====
# Mode options: "delete_all", "older_than", "keep_only", "delete_specific"
$Mode = "older_than"

# Protected profiles - NEVER deleted (comma-separated)
$ProtectedProfiles = "gaia,administrator"

# For "keep_only" mode - profile to preserve (in addition to protected)
$ProfileToKeep = "$YourProfileToKeepHere"

# For "delete_specific" mode - profile to remove
$ProfileToDelete = "$YourProfileToDeleteHere"

# For "older_than" mode - age in days
$DaysOld = 30

# Whether to cleanup DelProf2 after completion
$CleanupAfter = $true

# DelProf2 download settings
$DelProf2Url = "https://helgeklein.com/downloads/DelProf2/current/Delprof2%201.6.0.zip"
$DelProf2CacheDir = Join-Path $env:TEMP "delprof2_cache"

# ==== VALIDATION ====
$validModes = @("delete_all", "older_than", "keep_only", "delete_specific")
if ($Mode -notin $validModes) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- Mode must be one of: $($validModes -join ', ')"
}

if ($Mode -eq "keep_only" -and [string]::IsNullOrWhiteSpace($ProfileToKeep)) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- ProfileToKeep is required for 'keep_only' mode."
}

if ($Mode -eq "delete_specific" -and [string]::IsNullOrWhiteSpace($ProfileToDelete)) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- ProfileToDelete is required for 'delete_specific' mode."
}

if ($Mode -eq "older_than" -and $DaysOld -lt 1) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- DaysOld must be at least 1."
}

if ($errorOccurred) {
    Write-Host ""
    Write-Host "[ ERROR OCCURRED ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host $errorText
    exit 1
}

# ==== RUNTIME OUTPUT ====
Write-Host ""
Write-Host "[ INPUT VALIDATION ]"
Write-Host "--------------------------------------------------------------"
Write-Host "Mode              : $Mode"
Write-Host "Protected         : $ProtectedProfiles"

switch ($Mode) {
    "older_than" { Write-Host "Days Old          : $DaysOld" }
    "keep_only" { Write-Host "Profile to Keep   : $ProfileToKeep" }
    "delete_specific" { Write-Host "Profile to Delete : $ProfileToDelete" }
}

Write-Host "Cleanup After     : $CleanupAfter"

Write-Host ""
Write-Host "[ OPERATION ]"
Write-Host "--------------------------------------------------------------"

try {
    # Ensure cache directory exists
    if (-not (Test-Path $DelProf2CacheDir)) {
        Write-Host "Creating cache directory..."
        New-Item -Path $DelProf2CacheDir -ItemType Directory -Force | Out-Null
    }

    $delprof2Exe = Join-Path $DelProf2CacheDir "DelProf2.exe"

    # Download and extract DelProf2 if not present
    if (-not (Test-Path $delprof2Exe)) {
        Write-Host "Downloading DelProf2 from helgeklein.com..."

        $zipPath = Join-Path $DelProf2CacheDir "DelProf2.zip"

        # Use TLS 1.2
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        # Download
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($DelProf2Url, $zipPath)
        $webClient.Dispose()

        Write-Host "Download complete, extracting..."

        # Extract
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $DelProf2CacheDir)

        # Cleanup zip
        Remove-Item $zipPath -Force -ErrorAction SilentlyContinue

        if (-not (Test-Path $delprof2Exe)) {
            throw "DelProf2.exe not found after extraction"
        }

        Write-Host "DelProf2 ready"
    } else {
        Write-Host "Using cached DelProf2"
    }

    # Build the command arguments
    $delprof2Args = @("/u")  # Unattended mode

    # Add protected profiles
    $protectedList = $ProtectedProfiles -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
    foreach ($profile in $protectedList) {
        $delprof2Args += "/ed:$profile"
    }

    # Add mode-specific arguments
    switch ($Mode) {
        "delete_all" {
            # No additional args needed - deletes all except protected
        }
        "older_than" {
            $delprof2Args += "/d:$DaysOld"
        }
        "keep_only" {
            $delprof2Args += "/ed:$ProfileToKeep"
        }
        "delete_specific" {
            $delprof2Args += "/id:$ProfileToDelete"
        }
    }

    Write-Host "Executing: DelProf2.exe $($delprof2Args -join ' ')"

    # Execute DelProf2
    $processInfo = New-Object System.Diagnostics.ProcessStartInfo
    $processInfo.FileName = $delprof2Exe
    $processInfo.Arguments = $delprof2Args -join ' '
    $processInfo.RedirectStandardOutput = $true
    $processInfo.RedirectStandardError = $true
    $processInfo.UseShellExecute = $false
    $processInfo.CreateNoWindow = $true

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $processInfo
    $process.Start() | Out-Null
    $delprof2Output = $process.StandardOutput.ReadToEnd()
    $delprof2Error = $process.StandardError.ReadToEnd()
    $process.WaitForExit()

    if ($process.ExitCode -ne 0) {
        throw "DelProf2 failed with exit code $($process.ExitCode): $delprof2Error"
    }

    Write-Host "DelProf2 completed successfully"

    if ($delprof2Output) {
        Write-Host ""
        Write-Host "DelProf2 Output:"
        Write-Host $delprof2Output
    }

    # Cleanup if requested
    if ($CleanupAfter) {
        Write-Host "Cleaning up cache directory..."
        Remove-Item $DelProf2CacheDir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Cleanup complete"
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
    Write-Host "Mode   : $Mode"
}

Write-Host ""
Write-Host "[ FINAL STATUS ]"
Write-Host "--------------------------------------------------------------"
if ($errorOccurred) {
    Write-Host "Profile cleanup failed. See error above."
} else {
    switch ($Mode) {
        "delete_all" {
            Write-Host "All profiles deleted except protected: $ProtectedProfiles"
        }
        "older_than" {
            Write-Host "Profiles older than $DaysOld days deleted."
            Write-Host "Protected profiles preserved: $ProtectedProfiles"
        }
        "keep_only" {
            Write-Host "All profiles deleted except: $ProfileToKeep, $ProtectedProfiles"
        }
        "delete_specific" {
            Write-Host "Profile '$ProfileToDelete' has been deleted."
        }
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
