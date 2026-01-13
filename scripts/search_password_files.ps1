$ErrorActionPreference = 'Stop'
<#
██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
================================================================================
 SCRIPT   : Search Password Files                                        v1.1.1
 AUTHOR   : Limehawk.io
 DATE     : January 2026
 USAGE    : .\search_password_files.ps1
================================================================================
 FILE     : search_password_files.ps1
 DESCRIPTION : Searches user profiles for password and credential files
--------------------------------------------------------------------------------
 README
--------------------------------------------------------------------------------
 PURPOSE

   Scans all user profiles on a Windows machine for files that may contain
   passwords or credentials. Useful for security audits to identify exposed
   sensitive data in common user directories.

 DATA SOURCES & PRIORITY

   - Windows Search Index: Fast search if directories are indexed
   - Filesystem: Direct recursive search as fallback

 REQUIRED INPUTS

   All inputs are hardcoded in the script body:
     - $searchPatterns: Array of filename patterns to match
     - $subDirectories: User subdirectories to search
     - $useIndex: Whether to attempt Windows Search Index first
     - $maxDepth: Maximum folder depth for filesystem search
     - $googleChatWebhookUrl: Google Chat webhook (SuperOps replaces $GoogleChatWebhook)

 SETTINGS

   Configuration details and default values:
     - Search patterns include: *password*, *credential*, *secret*, etc.
     - Subdirectories: Desktop, Documents, Downloads, Pictures, cloud folders
     - Index search enabled by default
     - Max depth: 10 levels
     - Webhook alert sent only when files are found (not on zero results)

 BEHAVIOR

   The script performs the following actions in order:
   1. Enumerates all user profiles in C:\Users
   2. Builds list of target directories across all profiles
   3. Attempts Windows Search Index query if enabled
   4. Falls back to filesystem search if index unavailable or incomplete
   5. Reports all matching files with path, size, and modified date
   6. Sends Google Chat alert if files found and webhook URL configured

 PREREQUISITES

   - PowerShell 5.1 or later
   - Administrator privileges (to access other user profiles)

 SECURITY NOTES

   - No secrets exposed in output
   - Read-only operation - does not modify or delete files
   - File contents are NOT read, only metadata reported

 ENDPOINTS

   - Google Chat Webhook: Receives alert when password files found

 EXIT CODES

   0 = Success (search completed, results may be empty)
   1 = Failure (error occurred)

 EXAMPLE RUN

   [ INPUT VALIDATION ]
   --------------------------------------------------------------
   All required inputs are valid

   [ ENUMERATING USER PROFILES ]
   --------------------------------------------------------------
   Found 3 user profiles
   Profile : Administrator
   Profile : JohnDoe
   Profile : Guest

   [ SEARCHING FILESYSTEM ]
   --------------------------------------------------------------
   Searching 18 directories across 3 profiles
   Search patterns: *password*, *credential*, *secret*, *creds*, *logins*

   [ RESULTS ]
   --------------------------------------------------------------
   Found 2 potential password files

   Path     : C:\Users\JohnDoe\Documents\passwords.xlsx
   Size     : 15.2 KB
   Modified : 2025-11-15

   Path     : C:\Users\JohnDoe\Desktop\old_credentials.txt
   Size     : 1.3 KB
   Modified : 2024-08-22

   [ FINAL STATUS ]
   --------------------------------------------------------------
   Result : SUCCESS
   Files Found : 2

   [ SCRIPT COMPLETE ]
   --------------------------------------------------------------

--------------------------------------------------------------------------------
 CHANGELOG
--------------------------------------------------------------------------------
 2026-01-13 v1.1.1 Skip webhook section entirely if URL blank or placeholder not replaced
 2026-01-13 v1.1.0 Add Google Chat webhook alert when password files found
 2026-01-13 v1.0.1 Fix DBNull handling for Size/Modified from Windows Search Index
 2026-01-12 v1.0.0 Initial release
================================================================================
#>
Set-StrictMode -Version Latest

# ============================================================================
# STATE VARIABLES
# ============================================================================
$errorOccurred = $false
$errorText = ""
$foundFiles = @()

# ============================================================================
# HARDCODED INPUTS
# ============================================================================
$searchPatterns = @(
    '*password*',
    '*credential*',
    '*creds*',
    '*secret*',
    '*logins*',
    '*accounts*'
)

$subDirectories = @(
    'Desktop',
    'Documents',
    'Downloads',
    'Pictures',
    'OneDrive',
    'OneDrive - *',
    'Dropbox',
    'Google Drive',
    'Box'
)

$useIndex = $true
$maxDepth = 10

$excludedProfiles = @(
    'Public',
    'Default',
    'Default User',
    'All Users'
)

# Google Chat webhook URL - SuperOps replaces $GoogleChatWebhook at runtime
# Leave as placeholder to disable webhook alerts
$googleChatWebhookUrl = '$GoogleChatWebhook'

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Search-WithIndex {
    param (
        [string[]]$Patterns,
        [string[]]$Paths
    )

    $results = @()

    try {
        $connection = New-Object -ComObject ADODB.Connection
        $recordset = New-Object -ComObject ADODB.Recordset
        $connection.Open("Provider=Search.CollatorDSO;Extended Properties='Application=Windows';")

        foreach ($pattern in $Patterns) {
            $searchPattern = $pattern.Replace('*', '%')

            $pathConditions = ($Paths | ForEach-Object {
                "SCOPE='file:$_'"
            }) -join ' OR '

            $query = @"
SELECT System.ItemPathDisplay, System.Size, System.DateModified
FROM SystemIndex
WHERE System.FileName LIKE '$searchPattern'
AND ($pathConditions)
"@

            $recordset.Open($query, $connection)

            while (-not $recordset.EOF) {
                $sizeValue = $recordset.Fields.Item("System.Size").Value
                $modifiedValue = $recordset.Fields.Item("System.DateModified").Value

                $results += [PSCustomObject]@{
                    Path = $recordset.Fields.Item("System.ItemPathDisplay").Value
                    Size = if ($null -eq $sizeValue -or $sizeValue -is [DBNull]) { 0 } else { [long]$sizeValue }
                    Modified = if ($null -eq $modifiedValue -or $modifiedValue -is [DBNull]) { $null } else { $modifiedValue }
                }
                $recordset.MoveNext()
            }
            $recordset.Close()
        }

        $connection.Close()
    }
    catch {
        return $null
    }

    return $results
}

function Search-Filesystem {
    param (
        [string[]]$Patterns,
        [string[]]$Paths,
        [int]$Depth
    )

    $results = @()

    foreach ($path in $Paths) {
        if (-not (Test-Path $path -PathType Container)) {
            continue
        }

        foreach ($pattern in $Patterns) {
            try {
                $files = Get-ChildItem -Path $path -Filter $pattern -Recurse -File -Depth $Depth -ErrorAction SilentlyContinue

                foreach ($file in $files) {
                    $results += [PSCustomObject]@{
                        Path = $file.FullName
                        Size = $file.Length
                        Modified = $file.LastWriteTime
                    }
                }
            }
            catch {
                # Continue on access denied errors
            }
        }
    }

    return $results
}

function Format-FileSize {
    param ([long]$Bytes)

    if ($Bytes -ge 1GB) { return "{0:N1} GB" -f ($Bytes / 1GB) }
    if ($Bytes -ge 1MB) { return "{0:N1} MB" -f ($Bytes / 1MB) }
    if ($Bytes -ge 1KB) { return "{0:N1} KB" -f ($Bytes / 1KB) }
    return "$Bytes B"
}

function Send-GoogleChatAlert {
    param (
        [string]$WebhookUrl,
        [string]$Hostname,
        [int]$FileCount,
        [PSCustomObject[]]$Files
    )

    # Check if placeholder was replaced (use concatenation to avoid SuperOps replacing this check)
    if ([string]::IsNullOrWhiteSpace($WebhookUrl) -or $WebhookUrl -eq '$' + 'GoogleChatWebhook') {
        return $false
    }

    $fileList = ($Files | Select-Object -First 10 | ForEach-Object {
        "• $($_.Path)"
    }) -join "\n"

    if ($Files.Count -gt 10) {
        $fileList += "\n• ... and $($Files.Count - 10) more"
    }

    $message = @{
        text = "⚠️ *Password Files Found*\n\n*Host:* $Hostname\n*Files Found:* $FileCount\n\n$fileList"
    } | ConvertTo-Json -Compress

    try {
        $null = Invoke-RestMethod -Uri $WebhookUrl -Method Post -ContentType 'application/json' -Body $message
        return $true
    }
    catch {
        Write-Host "Warning : Failed to send webhook alert"
        Write-Host "Error   : $($_.Exception.Message)"
        return $false
    }
}

# ============================================================================
# INPUT VALIDATION
# ============================================================================
Write-Host ""
Write-Host "[ INPUT VALIDATION ]"
Write-Host "--------------------------------------------------------------"

if ($searchPatterns.Count -eq 0) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- At least one search pattern is required"
}

if ($subDirectories.Count -eq 0) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- At least one subdirectory is required"
}

if ($maxDepth -lt 1) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- Max depth must be at least 1"
}

if ($errorOccurred) {
    Write-Host ""
    Write-Host "[ ERROR OCCURRED ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host $errorText
    Write-Host ""
    exit 1
}

Write-Host "All required inputs are valid"

# ============================================================================
# ENUMERATE USER PROFILES
# ============================================================================
Write-Host ""
Write-Host "[ ENUMERATING USER PROFILES ]"
Write-Host "--------------------------------------------------------------"

$usersPath = "C:\Users"
$userProfiles = @()

try {
    $profileFolders = Get-ChildItem -Path $usersPath -Directory -ErrorAction Stop

    foreach ($folder in $profileFolders) {
        if ($excludedProfiles -notcontains $folder.Name) {
            $userProfiles += $folder.FullName
            Write-Host "Profile : $($folder.Name)"
        }
    }
}
catch {
    Write-Host ""
    Write-Host "[ ERROR OCCURRED ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host "Failed to enumerate user profiles"
    Write-Host "Error : $($_.Exception.Message)"
    Write-Host ""
    Write-Host "Ensure script is running with administrator privileges"
    Write-Host ""
    exit 1
}

if ($userProfiles.Count -eq 0) {
    Write-Host "No user profiles found"
    Write-Host ""
    Write-Host "[ FINAL STATUS ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host "Result : SUCCESS"
    Write-Host "Files Found : 0"
    Write-Host ""
    Write-Host "[ SCRIPT COMPLETE ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host ""
    exit 0
}

Write-Host ""
Write-Host "Found $($userProfiles.Count) user profile(s)"

# ============================================================================
# BUILD TARGET PATHS
# ============================================================================
$targetPaths = @()

foreach ($profile in $userProfiles) {
    foreach ($subDir in $subDirectories) {
        if ($subDir -like '*`**') {
            $wildcardPath = Join-Path $profile $subDir
            $matchedPaths = Get-ChildItem -Path (Split-Path $wildcardPath -Parent) -Directory -Filter (Split-Path $wildcardPath -Leaf) -ErrorAction SilentlyContinue
            foreach ($matched in $matchedPaths) {
                $targetPaths += $matched.FullName
            }
        }
        else {
            $fullPath = Join-Path $profile $subDir
            if (Test-Path $fullPath -PathType Container) {
                $targetPaths += $fullPath
            }
        }
    }
}

# ============================================================================
# SEARCH
# ============================================================================
$indexUsed = $false

if ($useIndex) {
    Write-Host ""
    Write-Host "[ SEARCHING INDEX ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host "Attempting Windows Search Index query"

    $indexResults = Search-WithIndex -Patterns $searchPatterns -Paths $targetPaths

    if ($null -ne $indexResults) {
        $foundFiles = $indexResults
        $indexUsed = $true
        Write-Host "Index search completed"
        Write-Host "Results from index : $($foundFiles.Count)"
    }
    else {
        Write-Host "Index unavailable or query failed, falling back to filesystem"
    }
}

if (-not $indexUsed) {
    Write-Host ""
    Write-Host "[ SEARCHING FILESYSTEM ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host "Searching $($targetPaths.Count) directories across $($userProfiles.Count) profile(s)"
    Write-Host "Search patterns : $($searchPatterns -join ', ')"
    Write-Host "Max depth : $maxDepth"

    $foundFiles = Search-Filesystem -Patterns $searchPatterns -Paths $targetPaths -Depth $maxDepth
}

# ============================================================================
# RESULTS
# ============================================================================
Write-Host ""
Write-Host "[ RESULTS ]"
Write-Host "--------------------------------------------------------------"

$uniqueFiles = $foundFiles | Sort-Object -Property Path -Unique

if ($uniqueFiles.Count -eq 0) {
    Write-Host "No password or credential files found"
}
else {
    Write-Host "Found $($uniqueFiles.Count) potential password file(s)"
    Write-Host ""

    foreach ($file in $uniqueFiles) {
        Write-Host "Path     : $($file.Path)"
        Write-Host "Size     : $(Format-FileSize $file.Size)"
        $modifiedDisplay = if ($null -eq $file.Modified) { 'Unknown' } else { ([datetime]$file.Modified).ToString('yyyy-MM-dd') }
        Write-Host "Modified : $modifiedDisplay"
        Write-Host ""
    }

    # Send webhook alert (skip if blank or placeholder not replaced)
    Write-Host "[ WEBHOOK DEBUG ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host "Raw value : [$googleChatWebhookUrl]"
    Write-Host "IsNullOrWhiteSpace : $([string]::IsNullOrWhiteSpace($googleChatWebhookUrl))"
    Write-Host "Equals placeholder : $($googleChatWebhookUrl -eq ('$' + 'GoogleChatWebhook'))"
    Write-Host ""

    $webhookConfigured = -not [string]::IsNullOrWhiteSpace($googleChatWebhookUrl) -and $googleChatWebhookUrl -ne ('$' + 'GoogleChatWebhook')
    if ($webhookConfigured) {
        Write-Host "[ WEBHOOK ALERT ]"
        Write-Host "--------------------------------------------------------------"
        $hostname = $env:COMPUTERNAME
        $sent = Send-GoogleChatAlert -WebhookUrl $googleChatWebhookUrl -Hostname $hostname -FileCount $uniqueFiles.Count -Files $uniqueFiles
        if ($sent) {
            Write-Host "Alert sent to Google Chat"
        }
        Write-Host ""
    }
}

# ============================================================================
# FINAL STATUS
# ============================================================================
Write-Host "[ FINAL STATUS ]"
Write-Host "--------------------------------------------------------------"
Write-Host "Result : SUCCESS"
Write-Host "Files Found : $($uniqueFiles.Count)"
Write-Host "Search Method : $(if ($indexUsed) { 'Windows Search Index' } else { 'Filesystem' })"

Write-Host ""
Write-Host "[ SCRIPT COMPLETE ]"
Write-Host "--------------------------------------------------------------"
Write-Host ""

exit 0
