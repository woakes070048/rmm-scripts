$ErrorActionPreference = 'Stop'

<#
██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
================================================================================
 SCRIPT   : Restic Backup B2 Install                                    v1.1.0
 AUTHOR   : Limehawk.io
 DATE     : March 2026
 USAGE    : .\restic_backup_b2_install.ps1
================================================================================
 FILE     : restic_backup_b2_install.ps1
 DESCRIPTION : Installs Restic, configures B2 repository, schedules daily backups
--------------------------------------------------------------------------------
 README
--------------------------------------------------------------------------------
 PURPOSE

   All-in-one installer for Restic backup to Backblaze B2 with immutable
   storage. Downloads Restic, initializes an encrypted B2 repository scoped
   to the machine hostname, generates a daily backup script with embedded
   credentials, and creates a Windows Scheduled Task. Designed for deployment
   via SuperOps RMM to client workstations and servers.

 DATA SOURCES & PRIORITY

   - Hardcoded B2 credentials and repo password (operator fills per deployment)
   - Restic binary from GitHub releases (SHA256-verified)

 REQUIRED INPUTS

   SuperOps runtime variables (prompted at deploy time):
     - $B2AccountId    : Backblaze B2 Application Key ID
     - $B2AccountKey   : Backblaze B2 Application Key
     - $B2BucketName   : B2 bucket name (e.g., limehawk-backups-clientname)
     - $ResticPassword : Repository encryption password
     - $ClientName     : Short client identifier for display (e.g., bell)

 SETTINGS

   Configuration with sensible defaults:
     - $backupPaths      : Array of paths to back up (default: user data)
     - $excludePatterns  : Array of exclude globs (default: temp/cache files)
     - $backupHour       : Hour to run backup (default: 2)
     - $backupMinute     : Minute to run backup (default: 0)
     - $keepDaily        : Daily snapshots to retain (default: 7)
     - $keepWeekly       : Weekly snapshots to retain (default: 4)
     - $keepMonthly      : Monthly snapshots to retain (default: 6)
     - $resticVersion    : Pinned Restic version (default: 0.17.3)

 BEHAVIOR

   The script performs the following actions in order:
   1. Validates all hardcoded inputs are non-empty
   2. Downloads Restic from GitHub, verifies SHA256, extracts to install dir
   3. ACL-locks install directory to SYSTEM + Administrators only
   4. Initializes B2 repository (skips if already exists)
   5. Generates daily backup script with embedded credentials and retention
   6. Creates Windows Scheduled Task for daily execution
   7. Runs dry-run backup to verify B2 connectivity and path access

 PREREQUISITES

   - Windows 10/11 or Windows Server 2016+
   - Administrator privileges (runs as SYSTEM via RMM)
   - Network access to github.com and Backblaze B2

 SECURITY NOTES

   - B2 credentials are embedded in the generated backup script
   - Install directory is ACL-locked to SYSTEM + Administrators
   - No secrets printed to console output
   - Repo password encrypts all backup data at rest

 ENDPOINTS

   - https://github.com/restic/restic/releases - Restic binary download
   - Backblaze B2 API (via Restic) - backup storage

 EXIT CODES

   0 = Success
   1 = Failure (validation, download, init, or config error)

 EXAMPLE RUN

   [INFO] INPUT VALIDATION
   ==============================================================
     B2 Bucket    : limehawk-backups-bell
     Client       : bell
     Repository   : b2:limehawk-backups-bell:WORKSTATION01
     Restic Ver   : 0.17.3
     Schedule     : Daily at 02:00
     Retention    : 7 daily, 4 weekly, 6 monthly
     Backup Paths : 5 paths configured
     Excludes     : 10 patterns configured

   [RUN] INSTALL RESTIC
   ==============================================================
     Downloading restic 0.17.3 for windows/amd64...
     Download complete (15.2 MB)
     SHA256 verified
     Extracted to C:\ProgramData\Limehawk\Restic\restic.exe
     Directory ACL locked to SYSTEM + Administrators

   [RUN] INITIALIZE REPOSITORY
   ==============================================================
     Repository : b2:limehawk-backups-bell:WORKSTATION01
     Initializing new repository...
     Repository initialized successfully

   [RUN] CREATE BACKUP SCRIPT
   ==============================================================
     Generated C:\ProgramData\Limehawk\Restic\restic-backup.ps1
     File ACL locked to SYSTEM + Administrators

   [RUN] CREATE SCHEDULED TASK
   ==============================================================
     Task Name : Limehawk Restic Backup
     Schedule  : Daily at 02:00
     Run As    : SYSTEM
     Task created successfully

   [RUN] TEST BACKUP
   ==============================================================
     Running dry-run backup...
     Dry-run completed successfully

   [OK] FINAL STATUS
   ==============================================================
     Result   : SUCCESS
     Restic   : C:\ProgramData\Limehawk\Restic\restic.exe
     Repo     : b2:limehawk-backups-bell:WORKSTATION01
     Schedule : Daily at 02:00
     Client   : bell

   [OK] SCRIPT COMPLETED
   ==============================================================

--------------------------------------------------------------------------------
 CHANGELOG
--------------------------------------------------------------------------------
 2026-03-01 v1.1.0 Add SuperOps runtime variables for B2 credentials
 2026-03-01 v1.0.0 Initial release
================================================================================
#>

Set-StrictMode -Version Latest

# ==== STATE ====
$errorOccurred = $false
$errorText     = ""

# ==== HARDCODED INPUTS (MANDATORY) ====

# --- REQUIRED: Backblaze B2 Credentials (SuperOps runtime variables) ---
$b2AccountId    = "$B2AccountId"       # B2 Application Key ID
$b2AccountKey   = "$B2AccountKey"      # B2 Application Key
$b2BucketName   = "$B2BucketName"      # B2 bucket name (e.g., limehawk-backups-clientname)
$resticPassword = "$ResticPassword"    # Repository encryption password
$clientName     = "$ClientName"        # Short client ID (e.g., bell)

# --- Backup Paths (workstation defaults) ---
$backupPaths = @(
    'C:\Users\*\Documents'
    'C:\Users\*\Desktop'
    'C:\Users\*\Downloads'
    'C:\Users\*\Pictures'
    'C:\Users\*\Videos'
)

# --- Exclude Patterns ---
$excludePatterns = @(
    '*.tmp'
    'Thumbs.db'
    'desktop.ini'
    '~$*'
    'C:\Users\*\AppData\Local\Google\Chrome\User Data\*\Cache\*'
    'C:\Users\*\AppData\Local\Microsoft\Edge\User Data\*\Cache\*'
    'C:\Users\*\AppData\Local\Mozilla\Firefox\Profiles\*\cache2\*'
    'C:\Users\*\AppData\Local\Temp\*'
    'C:\Users\*\OneDrive\*'
    '$RECYCLE.BIN'
)

# --- Schedule ---
$backupHour   = 2
$backupMinute = 0

# --- Retention Policy ---
$keepDaily   = 7
$keepWeekly  = 4
$keepMonthly = 6

# --- Restic Version ---
$resticVersion = '0.17.3'

# ==== DERIVED VALUES ====
$installDir  = 'C:\ProgramData\Limehawk\Restic'
$resticExe   = "$installDir\restic.exe"
$backupScript = "$installDir\restic-backup.ps1"
$logDir      = "$installDir\Logs"
$repository  = "b2:${b2BucketName}:$env:COMPUTERNAME"
$taskName    = 'Limehawk Restic Backup'

# ==== VALIDATION ====
if ([string]::IsNullOrWhiteSpace($b2AccountId) -or $b2AccountId -eq '$' + 'B2AccountId') {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- SuperOps runtime variable `$B2AccountId was not replaced."
}
if ([string]::IsNullOrWhiteSpace($b2AccountKey) -or $b2AccountKey -eq '$' + 'B2AccountKey') {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- SuperOps runtime variable `$B2AccountKey was not replaced."
}
if ([string]::IsNullOrWhiteSpace($b2BucketName) -or $b2BucketName -eq '$' + 'B2BucketName') {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- SuperOps runtime variable `$B2BucketName was not replaced."
}
if ([string]::IsNullOrWhiteSpace($resticPassword) -or $resticPassword -eq '$' + 'ResticPassword') {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- SuperOps runtime variable `$ResticPassword was not replaced."
}
if ([string]::IsNullOrWhiteSpace($clientName) -or $clientName -eq '$' + 'ClientName') {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- SuperOps runtime variable `$ClientName was not replaced."
}
if ($backupPaths.Count -eq 0) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- At least one backup path is required"
}

if ($errorOccurred) {
    Write-Host ""
    Write-Host "[ERROR] INPUT VALIDATION"
    Write-Host "=============================================================="
    Write-Host $errorText
    Write-Host ""
    Write-Host "[ERROR] SCRIPT COMPLETED"
    Write-Host "=============================================================="
    exit 1
}

# ==== INPUT VALIDATION OUTPUT ====
Write-Host ""
Write-Host "[INFO] INPUT VALIDATION"
Write-Host "=============================================================="
Write-Host "  B2 Bucket    : $b2BucketName"
Write-Host "  Client       : $clientName"
Write-Host "  Repository   : $repository"
Write-Host "  Restic Ver   : $resticVersion"
Write-Host "  Schedule     : Daily at $($backupHour.ToString('00')):$($backupMinute.ToString('00'))"
Write-Host "  Retention    : $keepDaily daily, $keepWeekly weekly, $keepMonthly monthly"
Write-Host "  Backup Paths : $($backupPaths.Count) paths configured"
Write-Host "  Excludes     : $($excludePatterns.Count) patterns configured"

# ==== INSTALL RESTIC ====
Write-Host ""
Write-Host "[RUN] INSTALL RESTIC"
Write-Host "=============================================================="

try {
    # Create install directory
    if (-not (Test-Path $installDir)) {
        New-Item -Path $installDir -ItemType Directory -Force | Out-Null
    }
    if (-not (Test-Path $logDir)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }

    # Download restic zip and SHA256 checksum
    $zipFileName = "restic_${resticVersion}_windows_amd64.zip"
    $zipUrl      = "https://github.com/restic/restic/releases/download/v${resticVersion}/${zipFileName}"
    $shaUrl      = "https://github.com/restic/restic/releases/download/v${resticVersion}/SHA256SUMS"
    $zipPath     = "$installDir\$zipFileName"
    $shaPath     = "$installDir\SHA256SUMS"

    Write-Host "  Downloading restic $resticVersion for windows/amd64..."
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    $wc = New-Object System.Net.WebClient
    $wc.DownloadFile($zipUrl, $zipPath)
    $wc.DownloadFile($shaUrl, $shaPath)

    $sizeMB = [math]::Round((Get-Item $zipPath).Length / 1MB, 1)
    Write-Host "  Download complete ($sizeMB MB)"

    # Verify SHA256
    $actualHash = (Get-FileHash -Path $zipPath -Algorithm SHA256).Hash.ToLower()
    $expectedLine = Get-Content $shaPath | Where-Object { $_ -match $zipFileName }
    if (-not $expectedLine) {
        throw "Could not find SHA256 entry for $zipFileName in SHA256SUMS"
    }
    $expectedHash = ($expectedLine -split '\s+')[0].ToLower()

    if ($actualHash -ne $expectedHash) {
        throw "SHA256 mismatch! Expected: $expectedHash Got: $actualHash"
    }
    Write-Host "  SHA256 verified"

    # Extract
    Expand-Archive -Path $zipPath -DestinationPath $installDir -Force
    if (-not (Test-Path $resticExe)) {
        throw "restic.exe not found after extraction"
    }
    Write-Host "  Extracted to $resticExe"

    # Cleanup download artifacts
    Remove-Item -Path $zipPath -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $shaPath -Force -ErrorAction SilentlyContinue

    # ACL-lock directory: SYSTEM + Administrators only, disable inheritance
    $acl = New-Object System.Security.AccessControl.DirectorySecurity
    $acl.SetAccessRuleProtection($true, $false)
    $systemRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        'NT AUTHORITY\SYSTEM', 'FullControl', 'ContainerInherit,ObjectInherit', 'None', 'Allow')
    $adminRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        'BUILTIN\Administrators', 'FullControl', 'ContainerInherit,ObjectInherit', 'None', 'Allow')
    $acl.AddAccessRule($systemRule)
    $acl.AddAccessRule($adminRule)
    Set-Acl -Path $installDir -AclObject $acl
    Write-Host "  Directory ACL locked to SYSTEM + Administrators"

} catch {
    Write-Host ""
    Write-Host "[ERROR] INSTALL RESTIC FAILED"
    Write-Host "=============================================================="
    Write-Host "  $($_.Exception.Message)"
    Write-Host ""
    Write-Host "[ERROR] SCRIPT COMPLETED"
    Write-Host "=============================================================="
    exit 1
}

# ==== INITIALIZE REPOSITORY ====
Write-Host ""
Write-Host "[RUN] INITIALIZE REPOSITORY"
Write-Host "=============================================================="

try {
    $env:B2_ACCOUNT_ID   = $b2AccountId
    $env:B2_ACCOUNT_KEY  = $b2AccountKey
    $env:RESTIC_PASSWORD = $resticPassword

    Write-Host "  Repository : $repository"

    # Check if repo already exists by running snapshots
    $checkResult = & $resticExe snapshots --repo $repository --json 2>&1
    $repoExists = $LASTEXITCODE -eq 0

    if ($repoExists) {
        Write-Host "  Repository already initialized, skipping"
    } else {
        Write-Host "  Initializing new repository..."
        & $resticExe init --repo $repository 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "restic init failed with exit code $LASTEXITCODE"
        }
        Write-Host "  Repository initialized successfully"
    }

} catch {
    Write-Host ""
    Write-Host "[ERROR] INITIALIZE REPOSITORY FAILED"
    Write-Host "=============================================================="
    Write-Host "  $($_.Exception.Message)"
    Write-Host ""
    Write-Host "[ERROR] SCRIPT COMPLETED"
    Write-Host "=============================================================="
    exit 1
} finally {
    $env:B2_ACCOUNT_ID   = $null
    $env:B2_ACCOUNT_KEY  = $null
    $env:RESTIC_PASSWORD = $null
}

# ==== CREATE BACKUP SCRIPT ====
Write-Host ""
Write-Host "[RUN] CREATE BACKUP SCRIPT"
Write-Host "=============================================================="

try {
    # Build backup paths argument string
    $pathArgs = ($backupPaths | ForEach-Object { "`"$_`"" }) -join " "

    # Build exclude arguments
    $excludeArgs = ($excludePatterns | ForEach-Object { "--exclude `"$_`"" }) -join " "

    # Generate the daily backup script
    $scriptContent = @"
`$ErrorActionPreference = 'Stop'
# Limehawk Restic Daily Backup - $clientName
# Generated $(Get-Date -Format 'yyyy-MM-dd') by restic_backup_b2_install.ps1
# DO NOT EDIT - regenerate by re-running the installer

`$logDir  = '$logDir'
`$logFile = "`$logDir\restic-backup-`$(Get-Date -Format 'yyyy-MM-dd').log"
`$restic  = '$resticExe'

# Ensure log directory exists
if (-not (Test-Path `$logDir)) { New-Item -Path `$logDir -ItemType Directory -Force | Out-Null }

# Start transcript logging
Start-Transcript -Path `$logFile -Append

try {
    # Set credentials
    `$env:B2_ACCOUNT_ID     = '$b2AccountId'
    `$env:B2_ACCOUNT_KEY    = '$b2AccountKey'
    `$env:RESTIC_PASSWORD   = '$resticPassword'
    `$env:RESTIC_REPOSITORY = '$repository'

    Write-Output "[`$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Starting backup"

    # Run backup
    & `$restic backup $pathArgs $excludeArgs --verbose
    Write-Output "[`$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Backup completed with exit code `$LASTEXITCODE"

    # Run retention policy (prune may partially fail on Object Lock protected objects - expected)
    Write-Output "[`$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Applying retention policy"
    & `$restic forget --keep-daily $keepDaily --keep-weekly $keepWeekly --keep-monthly $keepMonthly --prune 2>&1
    Write-Output "[`$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Retention policy applied (exit code `$LASTEXITCODE)"

} catch {
    Write-Output "[`$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] ERROR: `$(`$_.Exception.Message)"
} finally {
    # Clear credentials from environment
    `$env:B2_ACCOUNT_ID     = `$null
    `$env:B2_ACCOUNT_KEY    = `$null
    `$env:RESTIC_PASSWORD   = `$null
    `$env:RESTIC_REPOSITORY = `$null

    Stop-Transcript
}

# Rotate logs - keep last 30
Get-ChildItem -Path `$logDir -Filter 'restic-backup-*.log' |
    Sort-Object LastWriteTime -Descending |
    Select-Object -Skip 30 |
    Remove-Item -Force -ErrorAction SilentlyContinue
"@

    Set-Content -Path $backupScript -Value $scriptContent -Force
    Write-Host "  Generated $backupScript"

    # ACL-lock the backup script file
    $fileAcl = New-Object System.Security.AccessControl.FileSecurity
    $fileAcl.SetAccessRuleProtection($true, $false)
    $fileSystemRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        'NT AUTHORITY\SYSTEM', 'FullControl', 'None', 'None', 'Allow')
    $fileAdminRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        'BUILTIN\Administrators', 'FullControl', 'None', 'None', 'Allow')
    $fileAcl.AddAccessRule($fileSystemRule)
    $fileAcl.AddAccessRule($fileAdminRule)
    Set-Acl -Path $backupScript -AclObject $fileAcl
    Write-Host "  File ACL locked to SYSTEM + Administrators"

} catch {
    Write-Host ""
    Write-Host "[ERROR] CREATE BACKUP SCRIPT FAILED"
    Write-Host "=============================================================="
    Write-Host "  $($_.Exception.Message)"
    Write-Host ""
    Write-Host "[ERROR] SCRIPT COMPLETED"
    Write-Host "=============================================================="
    exit 1
}

# ==== CREATE SCHEDULED TASK ====
Write-Host ""
Write-Host "[RUN] CREATE SCHEDULED TASK"
Write-Host "=============================================================="

try {
    # Remove existing task if present
    $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        Write-Host "  Removed existing task"
    }

    $action  = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$backupScript`""
    $trigger = New-ScheduledTaskTrigger -Daily -At "$($backupHour.ToString('00')):$($backupMinute.ToString('00'))"
    $principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest

    $settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -ExecutionTimeLimit (New-TimeSpan -Hours 4) `
        -RestartCount 1 `
        -RestartInterval (New-TimeSpan -Minutes 15)

    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "Limehawk Restic backup to B2 ($clientName)" | Out-Null

    Write-Host "  Task Name : $taskName"
    Write-Host "  Schedule  : Daily at $($backupHour.ToString('00')):$($backupMinute.ToString('00'))"
    Write-Host "  Run As    : SYSTEM"
    Write-Host "  Task created successfully"

} catch {
    Write-Host ""
    Write-Host "[ERROR] CREATE SCHEDULED TASK FAILED"
    Write-Host "=============================================================="
    Write-Host "  $($_.Exception.Message)"
    Write-Host ""
    Write-Host "[ERROR] SCRIPT COMPLETED"
    Write-Host "=============================================================="
    exit 1
}

# ==== TEST BACKUP ====
Write-Host ""
Write-Host "[RUN] TEST BACKUP"
Write-Host "=============================================================="

try {
    $env:B2_ACCOUNT_ID   = $b2AccountId
    $env:B2_ACCOUNT_KEY  = $b2AccountKey
    $env:RESTIC_PASSWORD = $resticPassword

    Write-Host "  Running dry-run backup..."
    $dryRunOutput = & $resticExe backup --repo $repository --dry-run $backupPaths 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Dry-run failed with exit code $LASTEXITCODE`n$dryRunOutput"
    }
    Write-Host "  Dry-run completed successfully"

} catch {
    Write-Host ""
    Write-Host "[WARN] TEST BACKUP"
    Write-Host "=============================================================="
    Write-Host "  Dry-run failed: $($_.Exception.Message)"
    Write-Host "  Installation is complete but verify B2 connectivity manually"
} finally {
    $env:B2_ACCOUNT_ID   = $null
    $env:B2_ACCOUNT_KEY  = $null
    $env:RESTIC_PASSWORD = $null
}

# ==== FINAL STATUS ====
Write-Host ""
Write-Host "[OK] FINAL STATUS"
Write-Host "=============================================================="
Write-Host "  Result   : SUCCESS"
Write-Host "  Restic   : $resticExe"
Write-Host "  Repo     : $repository"
Write-Host "  Schedule : Daily at $($backupHour.ToString('00')):$($backupMinute.ToString('00'))"
Write-Host "  Client   : $clientName"

Write-Host ""
Write-Host "[OK] SCRIPT COMPLETED"
Write-Host "=============================================================="
exit 0
