$ErrorActionPreference = 'Stop'
<#
██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
================================================================================
 SCRIPT   : Edge Suppress Policies                                        v1.0.0
 AUTHOR   : Limehawk.io
 DATE     : December 2024
 USAGE    : .\edge_suppress_policies_system.ps1
================================================================================
 FILE     : edge_suppress_policies_system.ps1
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

   All inputs are hardcoded in the script body:
     - No configurable inputs required

 SETTINGS

   This script applies the following machine-wide policies:
     - HideFirstRunExperience: Skips welcome screens
     - DefaultBrowserSettingEnabled: Stops "make default" prompts
     - AutoImportAtFirstRun: Prevents importing from Chrome/Firefox
     - StartupBoostEnabled: Stops Edge preloading in background
     - BackgroundModeEnabled: Stops Edge running when closed
     - HubsSidebarEnabled: Disables sidebar
     - EdgeShoppingAssistantEnabled: Disables shopping features

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

   [ ADMIN CHECK ]
   --------------------------------------------------------------
   Running as Administrator

   [ EDGE POLICIES ]
   --------------------------------------------------------------
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

   [ EDGE BEHAVIOR ]
   --------------------------------------------------------------
   Disabled startup boost
   Disabled background mode
   Disabled prelaunch
   Disabled update notifications
   Disabled desktop shortcut creation

   [ SCHEDULED TASKS ]
   --------------------------------------------------------------
   Disabled MicrosoftEdgeUpdateTaskMachineCore
   Disabled MicrosoftEdgeUpdateTaskMachineUA

   [ STARTUP CLEANUP ]
   --------------------------------------------------------------
   No Edge startup entries found
   Prevented Edge shortcut creation

   [ FINAL STATUS ]
   --------------------------------------------------------------
   Result : SUCCESS
   Changes applied : 18

   [ SCRIPT COMPLETE ]
   --------------------------------------------------------------

--------------------------------------------------------------------------------
 CHANGELOG
--------------------------------------------------------------------------------
 2024-12-27 v1.0.0 Initial release - split from combined script
================================================================================
#>
Set-StrictMode -Version Latest

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
Write-Host "[ ADMIN CHECK ]"
Write-Host "--------------------------------------------------------------"

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ERROR: This script requires Administrator privileges"
    Write-Host ""
    Write-Host "[ ERROR OCCURRED ]"
    Write-Host "--------------------------------------------------------------"
    Write-Host "Run as Administrator or deploy via RMM as SYSTEM"
    exit 1
}
Write-Host "Running as Administrator"

# ============================================================================
# EDGE POLICIES
# ============================================================================
Write-Host ""
Write-Host "[ EDGE POLICIES ]"
Write-Host "--------------------------------------------------------------"

try {
    $edgePolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
    if (-not (Test-Path $edgePolicyPath)) {
        New-Item -Path $edgePolicyPath -Force | Out-Null
        Write-Host "Created Edge policy registry key"
    }

    # Disable first run experience
    Set-ItemProperty -Path $edgePolicyPath -Name "HideFirstRunExperience" -Value 1 -Type DWord -Force
    Write-Host "Disabled first run experience"
    $changesApplied++

    # Disable default browser check/prompt
    Set-ItemProperty -Path $edgePolicyPath -Name "DefaultBrowserSettingEnabled" -Value 0 -Type DWord -Force
    Write-Host "Disabled default browser check"
    $changesApplied++

    # Disable import on launch (4 = don't import)
    Set-ItemProperty -Path $edgePolicyPath -Name "ImportOnEachLaunch" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $edgePolicyPath -Name "AutoImportAtFirstRun" -Value 4 -Type DWord -Force
    Write-Host "Disabled import on launch"
    $changesApplied++

    # Disable browser sign-in (0 = disabled)
    Set-ItemProperty -Path $edgePolicyPath -Name "BrowserSignin" -Value 0 -Type DWord -Force
    Write-Host "Disabled browser sign-in"
    $changesApplied++

    # Disable collections
    Set-ItemProperty -Path $edgePolicyPath -Name "EdgeCollectionsEnabled" -Value 0 -Type DWord -Force
    Write-Host "Disabled collections"
    $changesApplied++

    # Disable shopping assistant
    Set-ItemProperty -Path $edgePolicyPath -Name "EdgeShoppingAssistantEnabled" -Value 0 -Type DWord -Force
    Write-Host "Disabled shopping assistant"
    $changesApplied++

    # Disable sidebar
    Set-ItemProperty -Path $edgePolicyPath -Name "HubsSidebarEnabled" -Value 0 -Type DWord -Force
    Write-Host "Disabled sidebar"
    $changesApplied++

    # Disable Edge bar (floating widget)
    Set-ItemProperty -Path $edgePolicyPath -Name "WebWidgetAllowed" -Value 0 -Type DWord -Force
    Write-Host "Disabled Edge bar"
    $changesApplied++

    # Disable Copilot
    Set-ItemProperty -Path $edgePolicyPath -Name "CopilotCDPPageContext" -Value 0 -Type DWord -Force
    Write-Host "Disabled Copilot"
    $changesApplied++

    # Disable suggestions
    Set-ItemProperty -Path $edgePolicyPath -Name "SearchSuggestEnabled" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $edgePolicyPath -Name "LocalProvidersEnabled" -Value 0 -Type DWord -Force
    Write-Host "Disabled suggestions"
    $changesApplied++

} catch {
    $errorOccurred = $true
    $errorText = "Failed to apply Edge policies: $($_.Exception.Message)"
}

# ============================================================================
# EDGE BEHAVIOR
# ============================================================================
Write-Host ""
Write-Host "[ EDGE BEHAVIOR ]"
Write-Host "--------------------------------------------------------------"

try {
    $edgePolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"

    # Disable startup boost (stops Edge preloading at Windows startup)
    Set-ItemProperty -Path $edgePolicyPath -Name "StartupBoostEnabled" -Value 0 -Type DWord -Force
    Write-Host "Disabled startup boost"
    $changesApplied++

    # Disable background mode (stops Edge running after closing)
    Set-ItemProperty -Path $edgePolicyPath -Name "BackgroundModeEnabled" -Value 0 -Type DWord -Force
    Write-Host "Disabled background mode"
    $changesApplied++

    # Disable prelaunch
    Set-ItemProperty -Path $edgePolicyPath -Name "AllowPrelaunch" -Value 0 -Type DWord -Force
    Write-Host "Disabled prelaunch"
    $changesApplied++

    # Disable update notifications
    Set-ItemProperty -Path $edgePolicyPath -Name "RelaunchNotification" -Value 0 -Type DWord -Force
    Write-Host "Disabled update notifications"
    $changesApplied++

    # EdgeUpdate policies
    $edgeUpdatePath = "HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate"
    if (-not (Test-Path $edgeUpdatePath)) {
        New-Item -Path $edgeUpdatePath -Force | Out-Null
    }
    Set-ItemProperty -Path $edgeUpdatePath -Name "CreateDesktopShortcutDefault" -Value 0 -Type DWord -Force
    Write-Host "Disabled desktop shortcut creation"
    $changesApplied++

} catch {
    $errorOccurred = $true
    if ($errorText.Length -gt 0) { $errorText += "`n" }
    $errorText += "Failed to apply Edge behavior settings: $($_.Exception.Message)"
}

# ============================================================================
# SCHEDULED TASKS
# ============================================================================
Write-Host ""
Write-Host "[ SCHEDULED TASKS ]"
Write-Host "--------------------------------------------------------------"

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

# ============================================================================
# STARTUP CLEANUP
# ============================================================================
Write-Host ""
Write-Host "[ STARTUP CLEANUP ]"
Write-Host "--------------------------------------------------------------"

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

# ============================================================================
# FINAL STATUS
# ============================================================================
Write-Host ""
Write-Host "[ FINAL STATUS ]"
Write-Host "--------------------------------------------------------------"

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
Write-Host "[ SCRIPT COMPLETE ]"
Write-Host "--------------------------------------------------------------"
exit 0
