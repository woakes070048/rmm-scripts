Import-Module $SuperOpsModule
$ErrorActionPreference = 'Stop'

<#
██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝ 
██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗ 
███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
================================================================================
 SCRIPT    : limehawk_admin_profile_branding.ps1
 VERSION   : v3.2.1
================================================================================
 README
--------------------------------------------------------------------------------
 PURPOSE
   Standardized Limehawk MSP automation to:
     1) Rename built-in Administrator (SID *-500) to "hawkadmin" and disable it
     2) Create/update "limehawk" MSP admin account (enabled for daily use)
     3) Generate strong passwords for both, push to SuperOps custom fields
     4) Clean up old MSP accounts (m5sadmin, tlitlocal, clientadmin)
     5) Apply account pictures and wallpaper branding

 WINDOWS / RUNTIME REQUIREMENTS
   - PowerShell 5.1+
   - Run as local Administrator (elevated)
   - Local user management available (Server/Client SKUs)

 SUPEROPS REQUIREMENTS
   - $SuperOpsModule available (Import-Module on line 1)
   - Runtime cmdlet Send-CustomField available
   - Custom fields: "Built-in Admin Password", "MSP Admin Password"

 SAFETY / IDEMPOTENCE
   - Built-in admin identified by SID *-500, not by name
   - If limehawk account exists, password is reset (safe for existing clients)
   - Account picture & wallpaper operations are no-throw best-effort

 EXIT CODES
   - 0 = success
   - 1 = failure (see “ERROR OCCURRED” diagnostics)
--------------------------------------------------------------------------------
 CHANGELOG
--------------------------------------------------------------------------------
 v3.2.1  (2025-12-04)  Add account labels to branding output for clarity.
 v3.2.0  (2025-12-04)  Change profile photo to .jpg; auto-delete old .png file.
 v3.1.8  (2025-12-03)  Unhide limehawk from login screen if hidden via registry.
 v3.1.7  (2025-12-03)  Clean up settings: remove dead variables, clarify which
                       account is which, update README to reflect current behavior.
 v3.1.6  (2025-12-03)  Remove re-enable logic for hawkadmin; clear FullName to
                       avoid login screen confusion; remove dead $SuperOpsPasswordField.
 v3.1.5  (2025-12-01)  Fix typo in OldMspAccounts: tiltlocal -> tlitlocal.
 v3.1.4  (2025-12-01)  Fix cleanup section using old admin name after rename.
 v3.1.3  (2025-12-01)  Fix error when limehawk account doesn't exist by moving
                       MSP admin profile lookup to after account creation.
 v3.1.2  (2025-10-31)  Improved wallpaper application by defaulting profile paths
                       and adding clearer warnings for missing profiles. Set
                       'Limehawk' MSP admin full name.
 v3.1.1  (2025-09-05)  Reordered sections to set/sync password before profile check.
 v3.1.0  (2025-08-20)  Standardized sections (ASCII headers), PS5.1-safe helpers,
                       consolidated diagnostics, strong password generator, file
                       existence checks, registry hive load/unload hardening.
 v3.0.0  (2025-08-19)  Initial combined automation (user/profile cleanup, branding,
                       password handling, SuperOps custom field update).
#>

# Optional strict mode
Set-StrictMode -Version Latest

# ============================== SETTINGS =====================================

# Built-in Administrator (SID *-500) - DISABLED, password stored as backup
$BuiltInAdminNewName       = "hawkadmin"                    # Rename built-in admin to this
$BuiltInAdminPasswordField = "Built-in Admin Password"      # SuperOps custom field for password

# MSP Administrator - ENABLED, used for daily MSP access
$MspAdminName              = "limehawk"                     # MSP admin account name
$MspAdminFullName          = "Limehawk"                     # Display name on login screen
$MspAdminPasswordField     = "MSP Admin Password"           # SuperOps custom field for password

# Branding assets (applied to both accounts)
$PhotoSource               = "$env:PUBLIC\Pictures\limehawk_profile.jpg"
$WallpaperPath             = "$env:PUBLIC\Pictures\limehawk_wallpaper.png"
$OldPhotoSource            = "$env:PUBLIC\Pictures\limehawk_profile.png"  # Legacy file to clean up

# Misc
$GeneratedPasswordLength   = 16                             # Password length for both accounts

# =============================================================================
# VALIDATION
# =============================================================================
$errorOccurred = $false
$errorText = ""

if ([string]::IsNullOrWhiteSpace($BuiltInAdminNewName)) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- BuiltInAdminNewName is required."
}
if ([string]::IsNullOrWhiteSpace($MspAdminName)) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- MspAdminName is required."
}
if ([string]::IsNullOrWhiteSpace($MspAdminFullName)) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- MspAdminFullName is required."
}
if ([string]::IsNullOrWhiteSpace($PhotoSource)) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- PhotoSource is required."
}
if ([string]::IsNullOrWhiteSpace($WallpaperPath)) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- WallpaperPath is required."
}
if ($GeneratedPasswordLength -lt 8) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- GeneratedPasswordLength must be at least 8."
}

if ($errorOccurred) {
    Write-Host ""
    Write-Host "[ ERROR OCCURRED ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host "Input validation failed:"
    Write-Host $errorText
    exit 1
}

# =============================================================================
# HELPERS (ASCII formatting, sanitization, etc.)
# =============================================================================
function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host ("[ {0} ]" -f $Title)
    Write-Host ("-" * 80)
}
function PrintKV {
    param([string]$Label,[string]$Value)
    $lbl = $Label.PadRight(28)
    Write-Host (" {0} : {1}" -f $lbl, $Value)
}
function Test-IsElevated {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p  = New-Object Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}
function New-RandomPassword {
    param([int]$Length=16)

    $lower = 'abcdefghijklmnopqrstuvwxyz'.ToCharArray()
    $upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.ToCharArray()
    $number = '0123456789'.ToCharArray()
    $symbol = '!@#$%^&*()'.ToCharArray()

    $allChars = $lower + $upper + $number + $symbol

    $password = ""
    $password += $lower | Get-Random -Count 1
    $password += $upper | Get-Random -Count 1
    $password += $number | Get-Random -Count 1
    $password += $symbol | Get-Random -Count 1

    for ($i = 0; $i -lt ($Length - 4); $i++) {
        $password += $allChars | Get-Random -Count 1
    }

    $passwordArray = $password.ToCharArray()
    $shuffledPassword = $passwordArray | Get-Random -Count $passwordArray.Length
    return -join $shuffledPassword
}
function Get-BuiltInAdmin {
    $admin = Get-LocalUser | Where-Object { $_.SID -like "*-500" }
    if (-not $admin) { throw "BUILT-IN ADMINISTRATOR ACCOUNT NOT FOUND (SID *-500)." }
    return $admin
}
function Load-UserHive {
    param([string]$HivePath,[string]$MountName)
    if (-not (Test-Path $HivePath)) { throw "HIVE NOT FOUND: $HivePath" }
    & reg.exe load ("HKU\{0}" -f $MountName) $HivePath | Out-Null
}
function Unload-UserHive {
    param([string]$MountName)
    & reg.exe unload ("HKU\{0}" -f $MountName) | Out-Null
}
function Set-AdminAccountPictures {
    param(
        [string]$ImageSourcePng,
        [string]$AdminSid
    )
    try {
        if (-not (Test-Path $ImageSourcePng)) {
            Write-Host "   (skip) Photo source not found: $ImageSourcePng"
            return
        }
        Add-Type -AssemblyName "System.Drawing"
        $prefixGuid = [guid]::NewGuid().ToString("B").ToUpper()
        $destDir    = Join-Path $env:PUBLIC ("AccountPictures\{0}" -f $AdminSid)

        if (Test-Path $destDir) { Remove-Item -Force -Recurse -Path $destDir }
        $null = New-Item -ItemType Directory -Force -Path $destDir

        $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AccountPicture\Users\$AdminSid"
        if (-not (Test-Path $regPath)) { $null = New-Item -Path $regPath -Force }

        $photo   = [System.Drawing.Image]::FromFile($ImageSourcePng)
        $sizes   = @(32,40,48,64,96,192,208,240,424,448,1080)

        $pngCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/png" }
        $enc      = [System.Drawing.Imaging.Encoder]::Quality
        $params   = New-Object System.Drawing.Imaging.EncoderParameters(1)
        $params.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter($enc, 90)

        foreach ($sz in $sizes) {
            $bmp = New-Object System.Drawing.Bitmap $sz, $sz
            $gfx = [System.Drawing.Graphics]::FromImage($bmp)
            $gfx.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $gfx.Clear([System.Drawing.Color]::White)
            $gfx.DrawImage($photo, 0, 0, $sz, $sz)
            $destFile = Join-Path $destDir ("{0}-Image{1}.png" -f $prefixGuid,$sz)
            $bmp.Save($destFile, $pngCodec, $params)
            $gfx.Dispose()
            $bmp.Dispose()
            Set-ItemProperty -Path $regPath -Name ("Image{0}" -f $sz) -Value $destFile
        }
        $photo.Dispose()
        Write-Host "   Profile pictures applied under $destDir"
    } catch {
        Write-Host "   (warn) Account picture failed: $($_.Exception.Message)"
    }
}
function Set-AdminWallpaper {
    param(
        [string]$WallpaperPng,
        [string]$AdminProfileNtuserPath
    )
    try {
        if (-not (Test-Path $WallpaperPng)) {
            Write-Host "   (skip) Wallpaper source not found: $WallpaperPng"
            return
        }
        if (-not (Test-Path $AdminProfileNtuserPath)) {
            Write-Host "   (warn) NTUSER.DAT not found for wallpaper: $AdminProfileNtuserPath. User profile may not have been created yet (first login required)."
            return
        }
        $mount = "TempAdminHive"
        try {
            Load-UserHive -HivePath $AdminProfileNtuserPath -MountName $mount
            $desktopKey = "Registry::HKEY_USERS\{0}\Control Panel\Desktop" -f $mount
            if (-not (Test-Path $desktopKey)) { $null = New-Item -Path $desktopKey -Force }
            Set-ItemProperty -Path $desktopKey -Name "Wallpaper" -Value $WallpaperPng
            Write-Host "   Wallpaper registry set: $WallpaperPng"
        } finally {
            Unload-UserHive -MountName $mount
        }
    } catch {
        Write-Host "   (warn) Wallpaper set failed: $($_.Exception.Message)"
    }
}
# ============================================================================

try {
    # =============================================================================
    # PRECHECKS & MODULE
    # =============================================================================
    Write-Section "PRECHECKS"
    $elev = Test-IsElevated
    PrintKV "Elevated"               ($(if ($elev) {"Yes"} else {"No"}))
    if (-not $elev) { throw "SCRIPT MUST RUN ELEVATED." }

    Write-Section "SUPEROPS MODULE"
    try {
        PrintKV "Importing Module"    "SuperOps"
        # Module is already imported on line 1; this validates presence
        $null = Get-Command Send-CustomField -ErrorAction Stop
        PrintKV "SuperOps Cmdlets"    "OK"
    } catch {
        throw "FAILED TO VALIDATE SUPEROPS MODULE/CMDLETS: $($_.Exception.Message)"
    }

    # =============================================================================
    # GATHER SYSTEM / TARGETS
    # =============================================================================
    Write-Section "TARGET ACCOUNTS / PATHS"
    $admin = Get-BuiltInAdmin
    $AdminUser = $admin.Name
    $AdminSID  = $admin.SID.Value
    PrintKV "Built-in Admin"      "$AdminUser ($AdminSID)"

    $AdminProfileObj  = Get-CimInstance Win32_UserProfile | Where-Object { $_.SID -eq $AdminSID }
    $AdminProfilePath = if ($AdminProfileObj) { $AdminProfileObj.LocalPath } else { "C:\Users\Administrator" }
    $NtUserDatPath    = if ($AdminProfilePath) { Join-Path $AdminProfilePath 'NTUSER.DAT' } else { $null }

    PrintKV "Admin Profile Path"     ($(if ($AdminProfilePath) { $AdminProfilePath } else { "<none>" }))
    PrintKV "Admin NTUSER.DAT"       ($(if ($NtUserDatPath)   { $NtUserDatPath   } else { "<none>" }))

    # =============================================================================
    # BUILT-IN ADMINISTRATOR MANAGEMENT
    # =============================================================================
    Write-Section "BUILT-IN ADMINISTRATOR MANAGEMENT"

    # Rename the built-in admin account
    if ($admin.Name -ne $BuiltInAdminNewName) {
        Rename-LocalUser -Name $admin.Name -NewName $BuiltInAdminNewName
        PrintKV "Built-in Admin Renamed" "$($admin.Name) -> $BuiltInAdminNewName"
    } else {
        PrintKV "Built-in Admin Name" "Already '$BuiltInAdminNewName'"
    }

    # Clear FullName to avoid confusion with limehawk account on login screen
    Set-LocalUser -Name $BuiltInAdminNewName -FullName ""
    PrintKV "Built-in Admin FullName" "Cleared"

    # Set a new password for the built-in admin
    $BuiltInAdminPassword = New-RandomPassword -Length $GeneratedPasswordLength
    try {
        Set-LocalUser -Name $BuiltInAdminNewName -Password (ConvertTo-SecureString $BuiltInAdminPassword -AsPlainText -Force)
        PrintKV "Built-in Admin Password" "Set"
    } catch {
        throw "Failed to set password on built-in Administrator account: $($_.Exception.Message)"
    }

    # Sync the password to SuperOps
    try {
        Send-CustomField -CustomFieldName $BuiltInAdminPasswordField -Value $BuiltInAdminPassword
        PrintKV "SuperOps Sync (Built-in)" "Password for '$BuiltInAdminNewName' updated in '$BuiltInAdminPasswordField'"
    } catch {
        throw "Failed to sync built-in admin password to SuperOps: $($_.Exception.Message)"
    }

    # Ensure the built-in admin account is disabled
    try {
        Disable-LocalUser -Name $BuiltInAdminNewName
        PrintKV "Built-in Admin Status" "Disabled"
    } catch {
        throw "Failed to disable built-in Administrator account: $($_.Exception.Message)"
    }

    # =============================================================================
    # MSP ADMINISTRATOR ACCOUNT MANAGEMENT
    # =============================================================================
    Write-Section "MSP ADMINISTRATOR ACCOUNT MANAGEMENT"

    # Check if the MSP admin account exists
    $MspAdmin = Get-LocalUser -Name $MspAdminName -ErrorAction SilentlyContinue
    if (-not $MspAdmin) {
        # Create the MSP admin account
        $MspAdminPassword = New-RandomPassword -Length $GeneratedPasswordLength
        try {
            $MspAdmin = New-LocalUser -Name $MspAdminName -Password (ConvertTo-SecureString $MspAdminPassword -AsPlainText -Force) -FullName $MspAdminFullName -Description "Limehawk MSP Admin Account"
            PrintKV "MSP Admin Account" "Created '$MspAdminName'"
        } catch {
            throw "Failed to create MSP admin account: $($_.Exception.Message)"
        }
        # Add the new user to the local Administrators group
        try {
            Add-LocalGroupMember -Group "Administrators" -Member $MspAdminName
            PrintKV "MSP Admin Group" "Added to Administrators"
        } catch {
            throw "Failed to add MSP admin to Administrators group: $($_.Exception.Message)"
        }
    } else {
        PrintKV "MSP Admin Account" "Already exists"
        # Just set a new password if the account already exists
        $MspAdminPassword = New-RandomPassword -Length $GeneratedPasswordLength
        try {
            Set-LocalUser -Name $MspAdminName -Password (ConvertTo-SecureString $MspAdminPassword -AsPlainText -Force)
            PrintKV "MSP Admin Password" "Set"
        } catch {
            throw "Failed to set password on MSP admin account: $($_.Exception.Message)"
        }
    }

    # Sync the password to SuperOps
    try {
        Send-CustomField -CustomFieldName $MspAdminPasswordField -Value $MspAdminPassword
        PrintKV "SuperOps Sync (MSP)" "Password for '$MspAdminName' updated in '$MspAdminPasswordField'"
    } catch {
        throw "Failed to sync MSP admin password to SuperOps: $($_.Exception.Message)"
    }

    # Ensure the MSP admin account is enabled
    try {
        Enable-LocalUser -Name $MspAdminName
        PrintKV "MSP Admin Status" "Enabled"
    } catch {
        throw "Failed to enable MSP admin account: $($_.Exception.Message)"
    }

    # Ensure MSP admin is visible on login screen (remove from hidden accounts list)
    $hiddenUsersPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList"
    if (Test-Path $hiddenUsersPath) {
        $hiddenValue = Get-ItemProperty -Path $hiddenUsersPath -Name $MspAdminName -ErrorAction SilentlyContinue
        if ($null -ne $hiddenValue -and $hiddenValue.$MspAdminName -eq 0) {
            Remove-ItemProperty -Path $hiddenUsersPath -Name $MspAdminName -ErrorAction SilentlyContinue
            PrintKV "MSP Admin Visibility" "Unhidden from login screen"
        } else {
            PrintKV "MSP Admin Visibility" "Already visible"
        }
    } else {
        PrintKV "MSP Admin Visibility" "No hidden accounts registry"
    }

    # Get MSP Admin SID and Profile Path (after account is created/verified)
    $MspAdmin = Get-LocalUser -Name $MspAdminName
    $MspAdminSID = $MspAdmin.SID.Value
    $MspAdminProfileObj = Get-CimInstance Win32_UserProfile | Where-Object { $_.SID -eq $MspAdminSID }
    $MspAdminProfilePath = if ($MspAdminProfileObj) { $MspAdminProfileObj.LocalPath } else { "C:\Users\$MspAdminName" }
    $MspAdminNtUserDatPath = if ($MspAdminProfilePath) { Join-Path $MspAdminProfilePath 'NTUSER.DAT' } else { $null }

    PrintKV "MSP Admin SID"              $MspAdminSID
    PrintKV "MSP Admin Profile Path"     ($(if ($MspAdminProfilePath) { $MspAdminProfilePath } else { "<none>" }))
    PrintKV "MSP Admin NTUSER.DAT"       ($(if ($MspAdminNtUserDatPath) { $MspAdminNtUserDatPath } else { "<none>" }))

    # =============================================================================
    # OLD MSP ACCOUNT CLEANUP
    # =============================================================================
    Write-Section "OLD MSP ACCOUNT CLEANUP"
    $OldMspAccounts = @("m5sadmin", "tlitlocal", "clientadmin")
    $BuiltInAdminSID = (Get-LocalUser -Name $BuiltInAdminNewName).SID.Value # Get SID of the built-in admin

    foreach ($accountName in $OldMspAccounts) {
        $user = Get-LocalUser -Name $accountName -ErrorAction SilentlyContinue
        if ($user) {
            if ($user.SID.Value -eq $BuiltInAdminSID) {
                PrintKV "Skipping Built-in Admin" "Account '$accountName' is the built-in Administrator (SID: $BuiltInAdminSID). Not deleting."
            } else {
                try {
                    Remove-LocalUser -Name $accountName -ErrorAction Stop
                    PrintKV "Removed Old Account" $accountName
                } catch {
                    PrintKV "Error Removing Account" "Failed to remove '$accountName': $($_.Exception.Message)"
                }
            }
        } else {
            PrintKV "Old Account Check" "'$accountName' not found"
        }
    }




    # =============================================================================
    # ACCOUNT PICTURE + WALLPAPER
    # =============================================================================
    Write-Section "ADMIN PICTURE & WALLPAPER"

    # Clean up old .png profile photo if it exists
    if (Test-Path $OldPhotoSource) {
        Remove-Item -Path $OldPhotoSource -Force -ErrorAction SilentlyContinue
        PrintKV "Removed Old Photo" $OldPhotoSource
    }

    PrintKV "Photo Source"            ($(if (Test-Path $PhotoSource) {$PhotoSource}else{"<missing>"}))
    PrintKV "Wallpaper Path"          ($(if (Test-Path $WallpaperPath) {$WallpaperPath}else{"<missing>"}))

    # Branding for Built-in Admin (renamed to hawkadmin)
    Write-Host "   [$BuiltInAdminNewName] Applying profile picture..."
    Set-AdminAccountPictures -ImageSourcePng $PhotoSource -AdminSid $AdminSID
    Write-Host "   [$BuiltInAdminNewName] Applying wallpaper..."
    Set-AdminWallpaper        -WallpaperPng  $WallpaperPath -AdminProfileNtuserPath $NtUserDatPath

    # Branding for MSP Admin (limehawk)
    Write-Host "   [$MspAdminName] Applying profile picture..."
    Set-AdminAccountPictures -ImageSourcePng $PhotoSource -AdminSid $MspAdminSID
    Write-Host "   [$MspAdminName] Applying wallpaper..."
    Set-AdminWallpaper        -WallpaperPng  $WallpaperPath -AdminProfileNtuserPath $MspAdminNtUserDatPath

    # =============================================================================
    # DONE
    # =============================================================================
    Write-Section "FINAL STATUS"
    PrintKV "hawkadmin (built-in)" "Disabled, password synced to SuperOps"
    PrintKV "limehawk (MSP admin)" "Enabled, password synced to SuperOps"

    Write-Section "SCRIPT COMPLETED"
    exit 0
}
catch {
    Write-Section "ERROR OCCURRED"
    PrintKV "ERROR MESSAGE" ($_.Exception.Message.ToUpper())
    exit 1
}
