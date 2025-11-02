$ErrorActionPreference = 'Stop'

<#
██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝ 
██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗ 
███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
================================================================================
 SCRIPT    : bitlocker-enable-style-a.ps1
 VERSION   : v1.0.0
================================================================================
 README
--------------------------------------------------------------------------------
 PURPOSE
 This script enables BitLocker on the OS drive (C:) using a TPM protector and a
 Recovery Password protector. It ensures protectors are not duplicated and prints
 the recovery key to standard output for RMM log capture.

 DATA SOURCES & PRIORITY
 1) Hardcoded values (defined within the script body)
 2) Error

 REQUIRED INPUTS
 - Drive: 'C:' (Target drive for BitLocker enablement)
 - Force: $true (Forces removal of all existing RecoveryPassword protectors before
          creating a new one, ensuring a unique key is generated and printed.
          This overrides the safety of an existing key being present.)

 SETTINGS
 - Encryption Method: XTS-AES 256
 - Used Space Only: $true
 - Skip Hardware Test: $true

 BEHAVIOR
 - Requires Administrator privileges.
 - Ensures BDESVC (BitLocker Drive Encryption Service) is running and set to Automatic.
 - Checks for and adds a TPM protector if available and missing.
 - Rotates the Recovery Password protector ($Force=$true) to ensure a new key is
   generated and printed to the console.
 - Initiates BitLocker encryption using the configured protectors.
 - Uses a basic `manage-bde -on` fallback if cmdlets fail or protectors already exist.
 - Prints the generated/rotated Recovery Key to the console.

 PREREQUISITES
 - Windows 10/11 Pro or Enterprise.
 - BitLocker features must be enabled/available.
 - Run as Administrator.

 SECURITY NOTES
 - The Recovery Password is printed to the console output, which is generally
   captured by the RMM tool's script log. This is the intended behavior for RMM
   integration but means the log contains a secret. No files or transcripts are
   used.

 ENDPOINTS
 - Local TPM (Trusted Platform Module)
 - Local BitLocker Service (BDESVC)

 EXIT CODES
 - 0 success
 - 1 failure due to prerequisites, validation, or cmdlet errors

 EXAMPLE RUN (Style A)
 [ INPUT VALIDATION ]
 --------------------------------------------------------------
 Drive : C:
 Force : True

 [ PRECHECK ]
 --------------------------------------------------------------
 BDESVC Status : Running
 TPM Ready : True

 [ OPERATION ]
 --------------------------------------------------------------
 INFO : Removing 1 existing RecoveryPassword protector(s).
 OK : Removed old recovery protector {<GUID>}
 OK : Added new RecoveryPassword protector: {<NEW-GUID>}
 INFO : TPM protector already present.
 OK : manage-bde -on issued.

 [ RESULT ]
 --------------------------------------------------------------
 Protection Status : On
 Volume Status : EncryptionInProgress
 Recovery Key ID : {<NEW-GUID>}
 Recovery Password:
 ------------------------------------------------------------
 123456-789012-345678-901234-567890-123456-789012-345678
 ------------------------------------------------------------

 [ FINAL STATUS ]
 --------------------------------------------------------------
 OK : BitLocker enablement process successfully initiated.

 [ SCRIPT COMPLETED ]
 --------------------------------------------------------------
--------------------------------------------------------------------------------
 CHANGELOG
 2025-09-29 v1.0.0 Initial Style A implementation with hardcoded inputs.
================================================================================
#>

# Optional strict mode
Set-StrictMode -Version Latest

# ==== STATE (NO ARRAYS/LISTS) ====
$errorOccurred = $false
$errorText     = ""
$recoveryKey   = ""
$recoveryKpId  = ""

# ==== HARDCODED INPUTS (MANDATORY) ====
$Drive           = 'C:'
$Force           = $true # Force recovery key rotation/creation

# ==== VALIDATION ====
if ([string]::IsNullOrWhiteSpace($Drive)) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- Drive is required."
}
if ($null -eq $Force -or ($Force -isnot [bool])) {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "- Force must be a boolean ($true or $false)."
}

# --- Core Functions (Non-helper, required for clean output) ---

function Write-Host-KV {
    param([string]$k,[string]$v)
    Write-Host ("{0} : {1}" -f $k, $v)
}
function Write-Host-OK { param([string]$m) Write-Host "OK : $m" }
function Write-Host-INFO { param([string]$m) Write-Host "INFO : $m" }
function Write-Host-FAIL { param([string]$m) Write-Host "FAIL : $m" }

# Helper to get Recovery Password via WMI (best effort)
function Get-RecoveryPasswordForId {
    param([string]$MountPoint, [string]$KeyProtectorId)
    try {
        $wmi = Get-WmiObject -Namespace root\CIMV2\Security\MicrosoftVolumeEncryption -Class Win32_EncryptableVolume -ErrorAction Stop |
               Where-Object { $_.DriveLetter -eq $MountPoint }
        if (-not $wmi) { return $null }

        $pw = $wmi.GetKeyProtectorNumericalPassword($KeyProtectorId).NumericalPassword
        if ($pw) { return $pw }
    } catch {
        # Fallback to manage-bde parsing if WMI fails
        $out = & manage-bde -protectors -get $MountPoint 2>$null
        $currentId = $null
        foreach ($line in $out) {
            $idMatch = [regex]::Match($line, 'ID:\s*([0-9A-Fa-f\-]{36})')
            if ($idMatch.Success) { $currentId = $idMatch.Groups[1].Value }
            $pwMatch = [regex]::Match($line, '([0-9]{6}-){7}[0-9]{6}')
            if ($pwMatch.Success -and $currentId -eq $KeyProtectorId) {
                return $pwMatch.Value
            }
        }
    }
    return $null
}

if ($errorOccurred) {
    Write-Host ""
    Write-Host "[ ERROR OCCURRED ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host $errorText
    exit 1
}

# ==== RUNTIME OUTPUT (Style A) ====
Write-Host ""
Write-Host "[ INPUT VALIDATION ]"
Write-Host "--------------------------------------------------------------"
Write-Host-KV "Drive" $Drive
Write-Host-KV "Force" $Force

Write-Host ""
Write-Host "[ PRECHECK ]"
Write-Host "--------------------------------------------------------------"

# 1. Check Admin
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host-FAIL "Must run as Administrator"
    exit 1
}

# 2. Check Drive Exists
$vol = $null
try {
    $vol = Get-CimInstance Win32_Volume -Filter ("DriveLetter='{0}'" -f $Drive)
} catch {}
if (-not $vol) {
    Write-Host-FAIL "Target Drive $Drive not found."
    exit 1
}

# 3. Check and start BDESVC
try {
    $svc = Get-Service -Name "BDESVC" -ErrorAction Stop
    if ($svc.Status -ne "Running") { Start-Service -Name "BDESVC" | Out-Null }
    Set-Service -Name "BDESVC" -StartupType Automatic | Out-Null
    $svcStatus = (Get-Service BDESVC).Status
} catch {
    $svcStatus = "Error"
    Write-Host-FAIL "BDESVC (BitLocker Service) check failed: $($_.Exception.Message)"
    exit 1
}
Write-Host-KV "BDESVC Status" $svcStatus

# 4. Check TPM Status
$tpmPresent = $false; $tpmReady = $false
try {
    $tpm = Get-Tpm -ErrorAction Stop
    $tpmPresent = $tpm.TpmPresent
    $tpmReady = $tpm.TpmReady
} catch {}
Write-Host-KV "TPM Present" ($tpmPresent.ToString())
Write-Host-KV "TPM Ready" ($tpmReady.ToString())

# Check current BitLocker state
$blv = $null
try { $blv = Get-BitLockerVolume -MountPoint $Drive -ErrorAction Stop } catch { }
if ($blv) {
    Write-Host-KV "Existing Protection" ($blv.ProtectionStatus)
    Write-Host-KV "Existing Volume Status" ($blv.VolumeStatus)
} else {
    Write-Host-INFO "No existing BitLocker state found."
}

Write-Host ""
Write-Host "[ OPERATION ]"
Write-Host "--------------------------------------------------------------"

# --- CONFIGURATION SETTINGS ---
$encParams = @{
    MountPoint       = $Drive
    SkipHardwareTest = $true
    EncryptionMethod = 'XtsAes256'
    UsedSpaceOnly    = $true
    ErrorAction      = 'Stop'
}

# 1. Recovery Password Protector (Rotation/Creation)
$existingRecProtectors = @()
if ($blv -and $blv.KeyProtector) {
    $existingRecProtectors = @($blv.KeyProtector | Where-Object { $_.KeyProtectorType -eq 'RecoveryPassword' })
}

if ($Force -and $existingRecProtectors.Count -gt 0) {
    Write-Host-INFO "Removing $($existingRecProtectors.Count) existing RecoveryPassword protector(s) due to Force flag."
    foreach ($kp in $existingRecProtectors) {
        try {
            Remove-BitLockerKeyProtector -MountPoint $Drive -KeyProtectorId $kp.KeyProtectorId -ErrorAction Stop | Out-Null
            Write-Host-OK "Removed old recovery protector $($kp.KeyProtectorId)"
        } catch {
            Write-Host-FAIL "Could not remove protector $($kp.KeyProtectorId): $($_.Exception.Message)"
            $errorOccurred = $true
        }
    }
    # Refresh blv after removal
    try { $blv = Get-BitLockerVolume -MountPoint $Drive -ErrorAction Stop } catch { $blv = $null }
}

# Check again for existence after cleanup
$blv = Get-BitLockerVolume -MountPoint $Drive -ErrorAction SilentlyContinue
$recProtectorExists = $false
if ($blv -and $blv.KeyProtector) {
    $recProtectorExists = ($blv.KeyProtector.KeyProtectorType -contains 'RecoveryPassword')
}

if (-not $recProtectorExists) {
    # Suppress the native output banner for key creation
    $null = (Add-BitLockerKeyProtector -MountPoint $Drive -RecoveryPasswordProtector -WarningAction SilentlyContinue) 3>$null 2>$null | Out-Null
    $blv = Get-BitLockerVolume -MountPoint $Drive -ErrorAction Stop
    $newKp = $blv.KeyProtector | Where-Object { $_.KeyProtectorType -eq 'RecoveryPassword' } | Select-Object -First 1
    if ($newKp) {
        $recoveryKpId = $newKp.KeyProtectorId
        $recoveryKey  = Get-RecoveryPasswordForId -MountPoint $Drive -KeyProtectorId $recoveryKpId
        Write-Host-OK "Added new RecoveryPassword protector: $recoveryKpId"
    } else {
        Write-Host-FAIL "Failed to add RecoveryPassword protector. Key ID not found."
        $errorOccurred = $true
    }
} else {
    $existingKp = $blv.KeyProtector | Where-Object { $_.KeyProtectorType -eq 'RecoveryPassword' } | Select-Object -First 1
    $recoveryKpId = $existingKp.KeyProtectorId
    $recoveryKey = Get-RecoveryPasswordForId -MountPoint $Drive -KeyProtectorId $recoveryKpId
    Write-Host-INFO "RecoveryPassword protector already exists: $recoveryKpId"
}

# 2. TPM Protector (Ensure no duplicates)
if ($tpmPresent -and $tpmReady -and $blv) {
    $hasTpm = $false
    if ($blv.KeyProtector) {
        $hasTpm = ($blv.KeyProtector.KeyProtectorType -contains 'Tpm')
    }
    if (-not $hasTpm) {
        try {
            Add-BitLockerKeyProtector -MountPoint $Drive -TpmProtector -WarningAction SilentlyContinue | Out-Null
            Write-Host-OK "TPM protector added."
            $blv = Get-BitLockerVolume -MountPoint $Drive -ErrorAction Stop
        } catch {
            Write-Host-FAIL "Could not add TPM protector: $($_.Exception.Message)"
            $errorOccurred = $true
        }
    } else {
        Write-Host-INFO "TPM protector already present."
    }
}

# 3. Enable Encryption
if (-not $errorOccurred) {
    $blv = Get-BitLockerVolume -MountPoint $Drive -ErrorAction SilentlyContinue
    $needEnable = $true
    if ($blv -and ($blv.VolumeStatus -in @('EncryptionInProgress','EncryptionSuspended','FullyEncrypted'))) {
        $needEnable = $false
        Write-Host-INFO "Encryption already started ($($blv.VolumeStatus)). Skipping Enable-BitLocker."
    }

    if ($needEnable) {
        # If any protectors exist, use manage-bde -on for cleaner state transition
        if ($blv -and $blv.KeyProtector.Count -gt 0) {
            Write-Host-INFO "Using existing protectors with manage-bde -on."
            $args = @('-on', $Drive, '-skiphardwaretest')
            if ($encParams.UsedSpaceOnly)      { $args += '-usedspaceonly' }
            if ($encParams.EncryptionMethod)   { $args += @('-encryptionmethod', $encParams.EncryptionMethod) }
            & manage-bde @args 2>$null | Out-Null
            Write-Host-OK "manage-bde -on issued."
        }
        # Fallback to Enable-BitLocker (should only happen if protectors were just added and manage-bde fails)
        else {
            Write-Host-FAIL "Failed to use manage-bde. Attempting direct Enable-BitLocker (less reliable)."
            try {
                Enable-BitLocker @encParams
                Write-Host-OK "Enable-BitLocker command issued."
            } catch {
                Write-Host-FAIL "Enable-BitLocker failed: $($_.Exception.Message)"
                $errorOccurred = $true
            }
        }
    }
}

Write-Host ""
Write-Host "[ RESULT ]"
Write-Host "--------------------------------------------------------------"

if ($errorOccurred) {
    Write-Host-FAIL "Configuration failed. Check [ OPERATION ] for details."
} else {
    $final = Get-BitLockerVolume -MountPoint $Drive
    Write-Host-KV "Protection Status" ($final.ProtectionStatus)
    Write-Host-KV "Volume Status" ($final.VolumeStatus)
    Write-Host-KV "Encryption %" ($final.EncryptionPercentage)
    Write-Host-KV "Recovery Key ID" ($recoveryKpId)

    if ([string]::IsNullOrWhiteSpace($recoveryKey)) {
        Write-Host-INFO "Recovery password was not retrieved (plaintext blocked by policy or provider)."
    } else {
        Write-Host "Recovery Password:"
        Write-Host " ------------------------------------------------------------"
        Write-Host " $recoveryKey"
        Write-Host " ------------------------------------------------------------"
    }
}

Write-Host ""
Write-Host "[ FINAL STATUS ]"
Write-Host "--------------------------------------------------------------"
if ($errorOccurred) {
    Write-Host-FAIL "BitLocker enablement process failed during configuration."
    exit 1
} else {
    Write-Host-OK "BitLocker enablement process successfully initiated."
}

Write-Host ""
Write-Host "[ SCRIPT COMPLETED ]"
Write-Host "--------------------------------------------------------------"
exit 0
