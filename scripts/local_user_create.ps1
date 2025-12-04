$ErrorActionPreference = 'Stop'

<#
██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
================================================================================
 SCRIPT   : Local User Create v1.1.0
 VERSION  : v1.1.0
================================================================================
 FILE     : local_user_create.ps1
--------------------------------------------------------------------------------
 README
--------------------------------------------------------------------------------
 PURPOSE

 Creates a new local user account with specified username and password.
 Optionally adds the user to the Administrators group.

 DATA SOURCES & PRIORITY

 1) Hardcoded values (username, password, admin flag)

 REQUIRED INPUTS

 - Username    : Username for the new account (via SuperOps $YourUsernameHere)
 - Password    : Password for the account (via SuperOps $YourPasswordHere)
 - AddToAdmin  : "Yes" or "No" (default: "No")

 SETTINGS

 - Creates standard local user account
 - Optional administrator privileges

 BEHAVIOR

 1. Validates inputs
 2. Creates local user account
 3. Optionally adds to Administrators group
 4. Reports final status

 PREREQUISITES

 - Windows 10/11
 - Admin privileges required
 - PowerShell 5.1+

 SECURITY NOTES

 - Password visible in script - use RMM variables for production
 - No secrets logged to output

 EXIT CODES

 - 0: Success
 - 1: Failure

 EXAMPLE RUN

 [ INPUT VALIDATION ]
 --------------------------------------------------------------
 Username    : newuser
 Add to Admin: No

 [ OPERATION ]
 --------------------------------------------------------------
 Creating user account...
 User created successfully

 [ RESULT ]
 --------------------------------------------------------------
 Status : Success
 User   : newuser
 Admin  : No

 [ SCRIPT COMPLETED ]
 --------------------------------------------------------------
--------------------------------------------------------------------------------
 CHANGELOG
 2025-12-03 v1.1.0 Use SuperOps runtime variables for all inputs
 2025-11-29 v1.0.0 Initial Style A implementation
================================================================================
#>

Set-StrictMode -Version Latest

# ==== STATE ====
$errorOccurred = $false
$errorText = ""

# ==== HARDCODED INPUTS ====
$Username = "$YourUsernameHere"
$Password = "$YourPasswordHere"
$AddToAdmin = "No"  # "Yes" or "No"

# ==== VALIDATION ====
if ([string]::IsNullOrWhiteSpace($Username) -or $Username -eq '$' + 'YourUsernameHere') {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- Username is required (set via SuperOps runtime variable)."
}

if ([string]::IsNullOrWhiteSpace($Password) -or $Password -eq '$' + 'YourPasswordHere') {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- Password is required (set via SuperOps runtime variable)."
}

if ($AddToAdmin -ne "Yes" -and $AddToAdmin -ne "No") {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- AddToAdmin must be 'Yes' or 'No'."
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
Write-Host "Username     : $Username"
Write-Host "Add to Admin : $AddToAdmin"

Write-Host ""
Write-Host "[ OPERATION ]"
Write-Host "--------------------------------------------------------------"

try {
    # Check if user already exists
    $existingUser = Get-LocalUser -Name $Username -ErrorAction SilentlyContinue
    if ($existingUser) {
        throw "User '$Username' already exists on this system."
    }

    # Create the user
    Write-Host "Creating user account..."
    $securePassword = ConvertTo-SecureString $Password -AsPlainText -Force
    New-LocalUser -Name $Username -Password $securePassword -Description "User created via RMM" -ErrorAction Stop | Out-Null
    Write-Host "User created successfully"

    # Add to Administrators if requested
    if ($AddToAdmin -eq "Yes") {
        Write-Host "Adding to Administrators group..."
        Add-LocalGroupMember -Group "Administrators" -Member $Username -ErrorAction Stop
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
    Write-Host "Status : Failure"
} else {
    Write-Host "Status : Success"
    Write-Host "User   : $Username"
    Write-Host "Admin  : $AddToAdmin"
}

Write-Host ""
Write-Host "[ FINAL STATUS ]"
Write-Host "--------------------------------------------------------------"
if ($errorOccurred) {
    Write-Host "User creation failed. See error above."
} else {
    Write-Host "User '$Username' has been created successfully."
    if ($AddToAdmin -eq "Yes") {
        Write-Host "User has administrator privileges."
    } else {
        Write-Host "User is a standard user (no admin privileges)."
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
