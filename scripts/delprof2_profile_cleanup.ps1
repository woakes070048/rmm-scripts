$ErrorActionPreference = 'Stop'

<#
██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
================================================================================
 SCRIPT   : DelProf2 Profile Cleanup v1.0.0
 VERSION  : v1.0.0
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
 2) Chocolatey for DelProf2 installation

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

 - Uses Chocolatey to install/upgrade DelProf2
 - Always protects specified profiles (default: gaia, administrator)
 - Unattended mode (/u flag)

 BEHAVIOR

 1. Installs/upgrades DelProf2 via Chocolatey
 2. Builds command based on selected mode
 3. Executes DelProf2 with appropriate flags
 4. Reports results

 PREREQUISITES

 - Windows 10/11
 - Admin privileges required
 - Chocolatey installed (for DelProf2 installation)
 - Internet access for initial DelProf2 download

 SECURITY NOTES

 - DESTRUCTIVE OPERATION - profiles cannot be recovered
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
 Installing/upgrading DelProf2...
 Executing: delprof2.exe /u /d:30 /ed:gaia /ed:administrator
 DelProf2 completed successfully

 [ RESULT ]
 --------------------------------------------------------------
 Status : Success

 [ SCRIPT COMPLETED ]
 --------------------------------------------------------------
--------------------------------------------------------------------------------
 CHANGELOG
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

# Whether to uninstall DelProf2 after completion
$UninstallAfter = $false

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

Write-Host "Uninstall After   : $UninstallAfter"

Write-Host ""
Write-Host "[ OPERATION ]"
Write-Host "--------------------------------------------------------------"

try {
    # Install/upgrade DelProf2
    Write-Host "Installing/upgrading DelProf2 via Chocolatey..."
    $chocoResult = choco upgrade delprof2 -y --no-progress 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Chocolatey failed to install DelProf2: $chocoResult"
    }
    Write-Host "DelProf2 ready"

    # Build the command arguments
    $delprof2Args = "/u"  # Unattended mode

    # Add protected profiles
    $protectedList = $ProtectedProfiles -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
    foreach ($profile in $protectedList) {
        $delprof2Args += " /ed:$profile"
    }

    # Add mode-specific arguments
    switch ($Mode) {
        "delete_all" {
            # No additional args needed - deletes all except protected
        }
        "older_than" {
            $delprof2Args += " /d:$DaysOld"
        }
        "keep_only" {
            $delprof2Args += " /ed:$ProfileToKeep"
        }
        "delete_specific" {
            $delprof2Args += " /id:$ProfileToDelete"
        }
    }

    Write-Host "Executing: delprof2.exe $delprof2Args"

    # Execute DelProf2
    $processInfo = New-Object System.Diagnostics.ProcessStartInfo
    $processInfo.FileName = "delprof2.exe"
    $processInfo.Arguments = $delprof2Args
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

    # Uninstall if requested
    if ($UninstallAfter) {
        Write-Host "Uninstalling DelProf2..."
        choco uninstall delprof2 -y --no-progress 2>&1 | Out-Null
        Write-Host "DelProf2 uninstalled"
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
