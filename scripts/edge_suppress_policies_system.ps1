$ErrorActionPreference = 'Stop'
<#
██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
================================================================================
 SCRIPT   : Edge Suppress Policies                                        v1.1.2
 AUTHOR   : Limehawk.io
 DATE      : January 2026
 USAGE    : .\edge_suppress_policies_system.ps1
================================================================================
 FILE     : edge_suppress_policies_system.ps1
 DESCRIPTION : Applies machine-wide policies to suppress Edge nagging behaviors
--------------------------------------------------------------------------------
 README
--------------------------------------------------------------------------------
 PURPOSE

   Applies machine-wide policies to suppress Microsoft Edge nagging behaviors.
   Stops Edge from prompting to become default, auto-importing from other
   browsers, running in background, and showing promotional UI elements.
   Run as SYSTEM via RMM - this is the machine policy script.

 DATA SOURCES & PRIORITY

   - Windows Registry: Edge and EdgeUpdate policy keys (HKLM)
   - Scheduled Tasks: EdgeUpdate background tasks
   - Startup entries: Edge auto-start configurations

 REQUIRED INPUTS

   All inputs are hardcoded in the script body (booleans, $true/$false):

   UI & Prompts:
     - $disableFirstRun: Skip welcome/setup screens
     - $disableDefaultBrowserCheck: Stop "make Edge default" prompts
     - $disableImportOnLaunch: Prevent importing from Chrome/Firefox
     - $disableBrowserSignIn: Stop Microsoft account sign-in prompts

   Features:
     - $disableCollections: Turn off Collections feature
     - $disableShoppingAssistant: Turn off shopping/coupon features
     - $disableSidebar: Turn off Bing sidebar
     - $disableEdgeBar: Turn off floating Edge widget
     - $disableCopilot: Turn off Copilot integration
     - $disableSuggestions: Turn off search/site suggestions

   Background Behavior:
     - $disableStartupBoost: Stop Edge preloading at Windows startup
     - $disableBackgroundMode: Stop Edge running after closing
     - $disablePrelaunch: Stop Edge prelaunching
     - $disableUpdateNotifications: Stop "restart to update" prompts
     - $disableDesktopShortcut: Prevent Edge shortcut creation

   Maintenance:
     - $disableScheduledTasks: Disable EdgeUpdate scheduled tasks
     - $cleanStartupEntries: Remove Edge from startup programs

 SETTINGS

   All options default to $true (suppress everything). Set individual
   options to $false if you want to keep specific Edge behaviors.

 BEHAVIOR

   The script performs the following actions in order:
   1. Verifies admin privileges
   2. Creates Edge policy registry keys
   3. Applies 15+ registry policies to suppress Edge behaviors
   4. Disables EdgeUpdate scheduled tasks
   5. Removes Edge from startup programs

 PREREQUISITES

   - PowerShell 5.1 or later
   - Administrator privileges required (runs as SYSTEM via RMM)
   - Windows 10/11 with Microsoft Edge installed

 SECURITY NOTES

   - No secrets exposed in output
   - Modifies HKLM registry (machine-wide policies)
   - All changes are persistent across reboots
   - Does not uninstall Edge, just suppresses behaviors

 ENDPOINTS

   - Not applicable (local operations only)

 EXIT CODES

   0 = Success
   1 = Failure (error occurred)

 EXAMPLE RUN

   [INFO] ADMIN CHECK
   ==============================================================
   Running as Administrator

   [RUN] EDGE POLICIES
   ==============================================================
   Created Edge policy registry key
   Disabled first run experience
   Disabled default browser check
   Disabled import on launch
   Disabled browser sign-in
   Disabled collections
   Disabled shopping assistant
   Disabled sidebar
   Disabled Edge bar
   Disabled Copilot
   Disabled suggestions

   [RUN] EDGE BEHAVIOR
   ==============================================================
   Disabled startup boost
   Disabled background mode
   Disabled prelaunch
   Disabled update notifications
   Disabled desktop shortcut creation

   [RUN] SCHEDULED TASKS
   ==============================================================
   Disabled MicrosoftEdgeUpdateTaskMachineCore
   Disabled MicrosoftEdgeUpdateTaskMachineUA

   [RUN] STARTUP CLEANUP
   ==============================================================
   No Edge startup entries found
   Prevented Edge shortcut creation

   [INFO] FINAL STATUS
   ==============================================================
   Result : SUCCESS
   Changes applied : 18

   [OK] SCRIPT COMPLETE
   ==============================================================

--------------------------------------------------------------------------------
 CHANGELOG
--------------------------------------------------------------------------------
 2026-01-19 v1.1.2 Fixed EXAMPLE RUN section formatting
 2026-01-19 v1.1.1 Updated to two-line ASCII console output style
 2024-12-27 v1.1.0 Added boolean settings at top for each feature
 2024-12-27 v1.0.0 Initial release - split from combined script
================================================================================
#>
Set-StrictMode -Version Latest

# ============================================================================
# SETTINGS - Set to $false to keep specific Edge behaviors
# ============================================================================

# UI & Prompts
$disableFirstRun           = $true  # Skip welcome/setup screens
$disableDefaultBrowserCheck = $true  # Stop "make Edge default" prompts
$disableImportOnLaunch     = $true  # Prevent importing from Chrome/Firefox
$disableBrowserSignIn      = $true  # Stop Microsoft account sign-in prompts

# Features
$disableCollections        = $true  # Turn off Collections feature
$disableShoppingAssistant  = $true  # Turn off shopping/coupon features
$disableSidebar            = $true  # Turn off Bing sidebar
$disableEdgeBar            = $true  # Turn off floating Edge widget
$disableCopilot            = $true  # Turn off Copilot integration
$disableSuggestions        = $true  # Turn off search/site suggestions

# Background Behavior
$disableStartupBoost       = $true  # Stop Edge preloading at Windows startup
$disableBackgroundMode     = $true  # Stop Edge running after closing
$disablePrelaunch          = $true  # Stop Edge prelaunching
$disableUpdateNotifications = $true  # Stop "restart to update" prompts
$disableDesktopShortcut    = $true  # Prevent Edge shortcut creation

# Maintenance
$disableScheduledTasks     = $true  # Disable EdgeUpdate scheduled tasks
$cleanStartupEntries       = $true  # Remove Edge from startup programs

# ============================================================================
# STATE VARIABLES
# ============================================================================
$errorOccurred = $false
$errorText = ""
$changesApplied = 0

# ============================================================================
# ADMIN CHECK
# ============================================================================
Write-Host ""
Write-Host "[INFO] ADMIN CHECK"
Write-Host "=============================================================="

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ERROR: This script requires Administrator privileges"
    Write-Host ""
    Write-Host "[ERROR] PRIVILEGE CHECK FAILED"
    Write-Host "=============================================================="
    Write-Host "Run as Administrator or deploy via RMM as SYSTEM"
    exit 1
}
Write-Host "Running as Administrator"

# ============================================================================
# EDGE POLICIES
# ============================================================================
Write-Host ""
Write-Host "[RUN] EDGE POLICIES"
Write-Host "=============================================================="

try {
    $edgePolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
    if (-not (Test-Path $edgePolicyPath)) {
        New-Item -Path $edgePolicyPath -Force | Out-Null
        Write-Host "Created Edge policy registry key"
    }

    if ($disableFirstRun) {
        Set-ItemProperty -Path $edgePolicyPath -Name "HideFirstRunExperience" -Value 1 -Type DWord -Force
        Write-Host "Disabled first run experience"
        $changesApplied++
    }

    if ($disableDefaultBrowserCheck) {
        Set-ItemProperty -Path $edgePolicyPath -Name "DefaultBrowserSettingEnabled" -Value 0 -Type DWord -Force
        Write-Host "Disabled default browser check"
        $changesApplied++
    }

    if ($disableImportOnLaunch) {
        Set-ItemProperty -Path $edgePolicyPath -Name "ImportOnEachLaunch" -Value 0 -Type DWord -Force
        Set-ItemProperty -Path $edgePolicyPath -Name "AutoImportAtFirstRun" -Value 4 -Type DWord -Force
        Write-Host "Disabled import on launch"
        $changesApplied++
    }

    if ($disableBrowserSignIn) {
        Set-ItemProperty -Path $edgePolicyPath -Name "BrowserSignin" -Value 0 -Type DWord -Force
        Write-Host "Disabled browser sign-in"
        $changesApplied++
    }

    if ($disableCollections) {
        Set-ItemProperty -Path $edgePolicyPath -Name "EdgeCollectionsEnabled" -Value 0 -Type DWord -Force
        Write-Host "Disabled collections"
        $changesApplied++
    }

    if ($disableShoppingAssistant) {
        Set-ItemProperty -Path $edgePolicyPath -Name "EdgeShoppingAssistantEnabled" -Value 0 -Type DWord -Force
        Write-Host "Disabled shopping assistant"
        $changesApplied++
    }

    if ($disableSidebar) {
        Set-ItemProperty -Path $edgePolicyPath -Name "HubsSidebarEnabled" -Value 0 -Type DWord -Force
        Write-Host "Disabled sidebar"
        $changesApplied++
    }

    if ($disableEdgeBar) {
        Set-ItemProperty -Path $edgePolicyPath -Name "WebWidgetAllowed" -Value 0 -Type DWord -Force
        Write-Host "Disabled Edge bar"
        $changesApplied++
    }

    if ($disableCopilot) {
        Set-ItemProperty -Path $edgePolicyPath -Name "CopilotCDPPageContext" -Value 0 -Type DWord -Force
        Write-Host "Disabled Copilot"
        $changesApplied++
    }

    if ($disableSuggestions) {
        Set-ItemProperty -Path $edgePolicyPath -Name "SearchSuggestEnabled" -Value 0 -Type DWord -Force
        Set-ItemProperty -Path $edgePolicyPath -Name "LocalProvidersEnabled" -Value 0 -Type DWord -Force
        Write-Host "Disabled suggestions"
        $changesApplied++
    }

} catch {
    $errorOccurred = $true
    $errorText = "Failed to apply Edge policies: $($_.Exception.Message)"
}

# ============================================================================
# EDGE BEHAVIOR
# ============================================================================
Write-Host ""
Write-Host "[RUN] EDGE BEHAVIOR"
Write-Host "=============================================================="

try {
    $edgePolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"

    if ($disableStartupBoost) {
        Set-ItemProperty -Path $edgePolicyPath -Name "StartupBoostEnabled" -Value 0 -Type DWord -Force
        Write-Host "Disabled startup boost"
        $changesApplied++
    }

    if ($disableBackgroundMode) {
        Set-ItemProperty -Path $edgePolicyPath -Name "BackgroundModeEnabled" -Value 0 -Type DWord -Force
        Write-Host "Disabled background mode"
        $changesApplied++
    }

    if ($disablePrelaunch) {
        Set-ItemProperty -Path $edgePolicyPath -Name "AllowPrelaunch" -Value 0 -Type DWord -Force
        Write-Host "Disabled prelaunch"
        $changesApplied++
    }

    if ($disableUpdateNotifications) {
        Set-ItemProperty -Path $edgePolicyPath -Name "RelaunchNotification" -Value 0 -Type DWord -Force
        Write-Host "Disabled update notifications"
        $changesApplied++
    }

    if ($disableDesktopShortcut) {
        $edgeUpdatePath = "HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate"
        if (-not (Test-Path $edgeUpdatePath)) {
            New-Item -Path $edgeUpdatePath -Force | Out-Null
        }
        Set-ItemProperty -Path $edgeUpdatePath -Name "CreateDesktopShortcutDefault" -Value 0 -Type DWord -Force
        Write-Host "Disabled desktop shortcut creation"
        $changesApplied++
    }

} catch {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "Failed to apply Edge behavior settings: $($_.Exception.Message)"
}

# ============================================================================
# SCHEDULED TASKS
# ============================================================================
if ($disableScheduledTasks) {
    Write-Host ""
    Write-Host "[RUN] SCHEDULED TASKS"
    Write-Host "=============================================================="

    try {
        $edgeTasks = @(
            "MicrosoftEdgeUpdateTaskMachineCore",
            "MicrosoftEdgeUpdateTaskMachineUA",
            "MicrosoftEdgeUpdateBrowserReplacementTask"
        )

        $tasksDisabled = 0
        foreach ($taskName in $edgeTasks) {
            $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
            if ($task) {
                Disable-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue | Out-Null
                Write-Host "Disabled $taskName"
                $tasksDisabled++
                $changesApplied++
            }
        }

        if ($tasksDisabled -eq 0) {
            Write-Host "No EdgeUpdate tasks found"
        }

    } catch {
        Write-Host "Note: Some scheduled tasks may not exist"
    }
}

# ============================================================================
# STARTUP CLEANUP
# ============================================================================
if ($cleanStartupEntries) {
    Write-Host ""
    Write-Host "[RUN] STARTUP CLEANUP"
    Write-Host "=============================================================="

    try {
        $runPaths = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"
        )

        $cleanedEntries = 0
        foreach ($runPath in $runPaths) {
            if (Test-Path $runPath) {
                $properties = Get-ItemProperty -Path $runPath -ErrorAction SilentlyContinue
                if ($properties) {
                    $properties.PSObject.Properties | Where-Object { $_.Name -like "*Edge*" -or $_.Name -like "*MicrosoftEdge*" } | ForEach-Object {
                        Remove-ItemProperty -Path $runPath -Name $_.Name -Force -ErrorAction SilentlyContinue
                        Write-Host "Removed startup entry : $($_.Name)"
                        $cleanedEntries++
                        $changesApplied++
                    }
                }
            }
        }

        if ($cleanedEntries -eq 0) {
            Write-Host "No Edge startup entries found"
        }

        $edgeRunOncePath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer"
        Set-ItemProperty -Path $edgeRunOncePath -Name "DisableEdgeDesktopShortcutCreation" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        Write-Host "Prevented Edge shortcut creation"
        $changesApplied++

    } catch {
        Write-Host "Note: Some cleanup steps skipped"
    }
}

# ============================================================================
# FINAL STATUS
# ============================================================================
Write-Host ""
Write-Host "[INFO] FINAL STATUS"
Write-Host "=============================================================="

if ($errorOccurred) {
    Write-Host "Result : PARTIAL SUCCESS"
    Write-Host "Changes applied : $changesApplied"
    Write-Host ""
    Write-Host "Warnings:"
    Write-Host $errorText
} else {
    Write-Host "Result : SUCCESS"
    Write-Host "Changes applied : $changesApplied"
    Write-Host ""
    Write-Host "Edge policies applied - nagging behaviors suppressed"
    Write-Host "Run edge_set_chrome_default_user.ps1 as user to set Chrome default"
}

Write-Host ""
Write-Host "[OK] SCRIPT COMPLETE"
Write-Host "=============================================================="
exit 0
