$ErrorActionPreference = 'Stop'

<#
██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
================================================================================
SCRIPT  : User Accounts Report v1.0.2
AUTHOR  : Limehawk.io
DATE    : January 2026
USAGE   : .\user_accounts_report.ps1
FILE    : user_accounts_report.ps1
DESCRIPTION : Generates report of local user accounts and group memberships
================================================================================
README
--------------------------------------------------------------------------------
 PURPOSE

 Generates a comprehensive report of all local user accounts, their group
 memberships, login sessions, and user profiles on the system. Provides a
 single view of all user-related information for auditing and troubleshooting.

 DATA SOURCES & PRIORITY

 1) Local User Accounts (Get-LocalUser)
 2) Local Group Memberships (Get-LocalGroupMember)
 3) Active Sessions (quser/query user)
 4) User Profiles on disk (Win32_UserProfile)

 REQUIRED INPUTS

 None - script reports on current system state.

 SETTINGS

 - Reports all local users including disabled accounts
 - Shows group membership for each user
 - Displays active login sessions
 - Lists user profile folders with last use time

 BEHAVIOR

 1. Retrieves all local user accounts with details
 2. Queries group membership for each user
 3. Gets current active login sessions
 4. Lists all user profiles on disk
 5. Displays formatted report

 PREREQUISITES

 - Windows 10/11 or Windows Server
 - PowerShell 5.1+
 - Admin privileges recommended for full details

 SECURITY NOTES

 - No secrets in logs
 - Read-only operation, no changes made
 - May expose usernames and login times

 EXIT CODES

 - 0: Success
 - 1: Failure

 EXAMPLE RUN

 [INFO] LOCAL USER ACCOUNTS
 ==============================================================
 Name            Enabled  LastLogon             PasswordLastSet
 ----            -------  ---------             ---------------
 Administrator   False    12/1/2025 9:00 AM     11/15/2025
 limehawk        True     12/1/2025 10:30 AM    11/20/2025
 DefaultAccount  False    <never>               <never>

 [INFO] GROUP MEMBERSHIPS
 ==============================================================
 User: limehawk
   - Administrators
   - Users

 [INFO] ACTIVE SESSIONS
 ==============================================================
 USERNAME       SESSIONNAME  ID  STATE   IDLE TIME  LOGON TIME
 limehawk       console      1   Active  none       12/1/2025 8:00 AM

 [INFO] USER PROFILES ON DISK
 ==============================================================
 LocalPath                    LastUseTime           Special
 ---------                    -----------           -------
 C:\Users\limehawk            12/1/2025 10:30 AM    False
 C:\Users\Administrator       11/15/2025 2:00 PM    False

 [INFO] SCRIPT COMPLETED
 ==============================================================

CHANGELOG
--------------------------------------------------------------------------------
2026-01-19 v1.0.2 Updated to two-line ASCII console output style
2025-12-23 v1.0.1 Updated to Limehawk Script Framework
2025-12-01 v1.0.0 Initial Style A implementation
================================================================================
#>

Set-StrictMode -Version Latest

# ==== HELPER FUNCTIONS ====
function Write-Section {
    param([string]$Prefix, [string]$Title)
    Write-Host ""
    Write-Host "[$Prefix] $Title"
    Write-Host ("=" * 62)
}

# ==== MAIN SCRIPT ====
try {
    # =========================================================================
    # LOCAL USER ACCOUNTS
    # =========================================================================
    Write-Section "INFO" "LOCAL USER ACCOUNTS"

    $users = Get-LocalUser | Select-Object Name, Enabled, LastLogon, PasswordLastSet, Description, SID

    if ($users) {
        $users | Format-Table @(
            @{Label="Name"; Expression={$_.Name}; Width=20}
            @{Label="Enabled"; Expression={$_.Enabled}; Width=8}
            @{Label="LastLogon"; Expression={if($_.LastLogon) { $_.LastLogon.ToString("g") } else { "<never>" }}; Width=20}
            @{Label="PasswordSet"; Expression={if($_.PasswordLastSet) { $_.PasswordLastSet.ToString("d") } else { "<never>" }}; Width=12}
            @{Label="Description"; Expression={$_.Description}; Width=30}
        ) -Wrap
    } else {
        Write-Host " No local users found."
    }

    # =========================================================================
    # ADMINISTRATOR GROUP MEMBERS
    # =========================================================================
    Write-Section "INFO" "ADMINISTRATORS GROUP"

    try {
        $admins = Get-LocalGroupMember -Group "Administrators" -ErrorAction Stop
        foreach ($admin in $admins) {
            $type = $admin.ObjectClass
            $name = $admin.Name
            Write-Host " [$type] $name"
        }
    } catch {
        Write-Host " Unable to query Administrators group: $($_.Exception.Message)"
    }

    # =========================================================================
    # GROUP MEMBERSHIPS PER USER
    # =========================================================================
    Write-Section "INFO" "USER GROUP MEMBERSHIPS"

    $localGroups = Get-LocalGroup
    foreach ($user in $users) {
        $userGroups = @()
        foreach ($group in $localGroups) {
            try {
                $members = Get-LocalGroupMember -Group $group.Name -ErrorAction SilentlyContinue
                if ($members.Name -contains "$env:COMPUTERNAME\$($user.Name)") {
                    $userGroups += $group.Name
                }
            } catch {
                # Skip groups we can't query
            }
        }

        if ($userGroups.Count -gt 0) {
            Write-Host ""
            Write-Host " $($user.Name):"
            foreach ($g in $userGroups) {
                Write-Host "   - $g"
            }
        }
    }

    # =========================================================================
    # ACTIVE LOGIN SESSIONS
    # =========================================================================
    Write-Section "INFO" "ACTIVE LOGIN SESSIONS"

    try {
        $sessions = query user 2>&1
        if ($LASTEXITCODE -eq 0 -and $sessions) {
            $sessions | ForEach-Object { Write-Host " $_" }
        } else {
            Write-Host " No active sessions or unable to query."
        }
    } catch {
        Write-Host " Unable to query sessions: $($_.Exception.Message)"
    }

    # =========================================================================
    # USER PROFILES ON DISK
    # =========================================================================
    Write-Section "INFO" "USER PROFILES ON DISK"

    $profiles = Get-CimInstance Win32_UserProfile |
        Where-Object { -not $_.Special } |
        Select-Object LocalPath, LastUseTime, Loaded, @{
            Name="SizeMB"
            Expression={
                if (Test-Path $_.LocalPath) {
                    [math]::Round((Get-ChildItem $_.LocalPath -Recurse -Force -ErrorAction SilentlyContinue |
                        Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum / 1MB, 0)
                } else { "N/A" }
            }
        } | Sort-Object LastUseTime -Descending

    if ($profiles) {
        $profiles | Format-Table @(
            @{Label="Profile Path"; Expression={$_.LocalPath}; Width=35}
            @{Label="Last Used"; Expression={if($_.LastUseTime) { $_.LastUseTime.ToString("g") } else { "<unknown>" }}; Width=20}
            @{Label="Loaded"; Expression={$_.Loaded}; Width=8}
            @{Label="Size(MB)"; Expression={$_.SizeMB}; Width=10}
        )
    } else {
        Write-Host " No user profiles found."
    }

    # =========================================================================
    # SYSTEM PROFILE SUMMARY
    # =========================================================================
    Write-Section "INFO" "SUMMARY"

    $enabledUsers = ($users | Where-Object { $_.Enabled }).Count
    $disabledUsers = ($users | Where-Object { -not $_.Enabled }).Count
    $totalProfiles = $profiles.Count
    $adminCount = (Get-LocalGroupMember -Group "Administrators" -ErrorAction SilentlyContinue).Count

    Write-Host " Total Local Users     : $($users.Count)"
    Write-Host " Enabled Users         : $enabledUsers"
    Write-Host " Disabled Users        : $disabledUsers"
    Write-Host " Administrator Members : $adminCount"
    Write-Host " User Profiles on Disk : $totalProfiles"
    Write-Host ""
    Write-Host " Computer Name         : $env:COMPUTERNAME"
    Write-Host " Domain/Workgroup      : $((Get-CimInstance Win32_ComputerSystem).Domain)"

    Write-Section "INFO" "SCRIPT COMPLETED"
    exit 0

} catch {
    Write-Section "ERROR" "ERROR OCCURRED"
    Write-Host " Error: $($_.Exception.Message)"
    Write-Host " Line: $($_.InvocationInfo.ScriptLineNumber)"
    Write-Section "ERROR" "SCRIPT HALTED"
    exit 1
}
