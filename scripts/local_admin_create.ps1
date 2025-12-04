$ErrorActionPreference = 'Stop'

<#
██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
================================================================================
 SCRIPT   : Local Admin Create/Update v1.1.0
 VERSION  : v1.1.0
================================================================================
 FILE     : local_admin_create.ps1
--------------------------------------------------------------------------------
 README
--------------------------------------------------------------------------------
 PURPOSE

 Creates or updates a local administrator account with a cryptographically
 secure random password. If the account exists, resets the password. If not,
 creates the account and adds it to the Administrators group.

 DATA SOURCES & PRIORITY

 1) Hardcoded values (username)
 2) RNG for password generation

 REQUIRED INPUTS

 - AdminUsername : Username for the local admin account (via SuperOps $UsernameInput)

 SETTINGS

 - Password length: 16 characters
 - Password includes: uppercase, lowercase, numbers, special characters
 - Account added to local Administrators group

 BEHAVIOR

 1. Generates cryptographically secure random password
 2. Checks if user account exists
 3. If exists: resets password
 4. If not exists: creates account and adds to Administrators group
 5. Outputs password (for RMM custom field capture)

 PREREQUISITES

 - Windows 10/11
 - Admin privileges required
 - PowerShell 5.1+

 SECURITY NOTES

 - Password generated using RNGCryptoServiceProvider
 - Password output to console for RMM capture only
 - Consider storing password securely in RMM custom fields

 EXIT CODES

 - 0: Success
 - 1: Failure

 EXAMPLE RUN

 [ INPUT VALIDATION ]
 --------------------------------------------------------------
 Admin Username   : sudohawk
 Password Length  : 16

 [ OPERATION ]
 --------------------------------------------------------------
 Checking for existing account...
 Account does not exist, creating...
 Account created successfully
 Adding to Administrators group...

 [ RESULT ]
 --------------------------------------------------------------
 Status   : Success
 Action   : Created
 Password : ****************

 [ SCRIPT COMPLETED ]
 --------------------------------------------------------------
--------------------------------------------------------------------------------
 CHANGELOG
 2025-12-03 v1.1.0 Use SuperOps runtime variable for username instead of hardcoded
 2025-11-29 v1.0.0 Initial Style A implementation
================================================================================
#>

Set-StrictMode -Version Latest

# ==== STATE ====
$errorOccurred = $false
$errorText = ""
$actionTaken = ""
$generatedPassword = ""

# ==== HARDCODED INPUTS ====
$AdminUsername = '$UsernameInput'
$PasswordLength = 16

# ==== HELPER FUNCTIONS ====
function Get-SecureRandomPassword {
    param([int]$Length = 16)

    $charSet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789/*-+,!?=()@;:._"
    $rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
    $bytes = New-Object byte[]($Length)
    $rng.GetBytes($bytes)

    $result = New-Object char[]($Length)
    for ($i = 0; $i -lt $Length; $i++) {
        $result[$i] = $charSet[$bytes[$i] % $charSet.Length]
    }

    $rng.Dispose()
    return -join $result
}

# ==== VALIDATION ====
if ([string]::IsNullOrWhiteSpace($AdminUsername) -or $AdminUsername -eq '$' + 'UsernameInput') {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- AdminUsername is required (set via SuperOps runtime variable)."
}

if ($PasswordLength -lt 8) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- PasswordLength must be at least 8 characters."
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
Write-Host "Admin Username   : $AdminUsername"
Write-Host "Password Length  : $PasswordLength"

Write-Host ""
Write-Host "[ OPERATION ]"
Write-Host "--------------------------------------------------------------"

try {
    # Generate secure password
    $generatedPassword = Get-SecureRandomPassword -Length $PasswordLength
    $securePass = ConvertTo-SecureString $generatedPassword -AsPlainText -Force

    Write-Host "Checking for existing account..."
    $existingAccount = Get-LocalUser -Name $AdminUsername -ErrorAction SilentlyContinue

    if ($existingAccount) {
        Write-Host "Account exists, resetting password..."
        $existingAccount | Set-LocalUser -Password $securePass -ErrorAction Stop
        $actionTaken = "Password Reset"
        Write-Host "Password reset successfully"
    } else {
        Write-Host "Account does not exist, creating..."
        New-LocalUser -Name $AdminUsername -Password $securePass -FullName "Local Administrator" -Description "Local Administrator Account" -ErrorAction Stop | Out-Null
        $actionTaken = "Created"
        Write-Host "Account created successfully"

        Write-Host "Adding to Administrators group..."
        Add-LocalGroupMember -Group "Administrators" -Member $AdminUsername -ErrorAction Stop
        Write-Host "Added to Administrators group"
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
    Write-Host "Status   : Failure"
} else {
    Write-Host "Status   : Success"
    Write-Host "Action   : $actionTaken"
    Write-Host "Username : $AdminUsername"
    Write-Host "Password : $generatedPassword"
}

Write-Host ""
Write-Host "[ FINAL STATUS ]"
Write-Host "--------------------------------------------------------------"
if ($errorOccurred) {
    Write-Host "Local admin account operation failed. See error above."
} else {
    Write-Host "Local admin account '$AdminUsername' is ready."
    Write-Host "Store the password securely in your RMM system."
}

Write-Host ""
Write-Host "[ SCRIPT COMPLETED ]"
Write-Host "--------------------------------------------------------------"

if ($errorOccurred) {
    exit 1
} else {
    exit 0
}
