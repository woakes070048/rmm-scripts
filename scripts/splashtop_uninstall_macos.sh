#!/bin/bash
#
# ██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
# ██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
# ██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
# ██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
# ███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
# ╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
# ================================================================================
#  SCRIPT   : Splashtop Uninstall (macOS)                                  v1.1.0
#  AUTHOR   : Limehawk.io
#  DATE     : December 2024
#  USAGE    : sudo ./splashtop_uninstall_macos.sh
# ================================================================================
#  FILE     : splashtop_uninstall_macos.sh
# --------------------------------------------------------------------------------
#  README
# --------------------------------------------------------------------------------
#  PURPOSE
#
#    Completely removes Splashtop Streamer from macOS including all related
#    files, launch daemons, kernel extensions, and preferences. Performs a
#    thorough cleanup of all Splashtop components.
#
#  DATA SOURCES & PRIORITY
#
#    Not applicable - local system operation only
#
#  REQUIRED INPUTS
#
#    No hardcoded inputs required.
#
#  SETTINGS
#
#    Removes:
#      - Splashtop Streamer.app
#      - Splashtop Streamer for Business.app
#      - SplashtopRemote.app
#      - Launch daemons and agents
#      - Kernel extensions
#      - Audio plugins
#      - Preferences and caches
#      - Package receipts
#
#  BEHAVIOR
#
#    The script performs the following actions in order:
#    1. Kills all running Splashtop processes
#    2. Unloads launch daemons and agents
#    3. Removes launch daemon files
#    4. Removes applications
#    5. Removes shared data
#    6. Removes kernel extensions
#    7. Removes audio plugins
#    8. Removes preferences and caches
#    9. Forgets package receipts
#
#  PREREQUISITES
#
#    - macOS
#    - Root/sudo privileges
#
#  SECURITY NOTES
#
#    - No secrets exposed in output
#    - Requires elevated privileges
#    - Removes all Splashtop data permanently
#
#  ENDPOINTS
#
#    Not applicable - local system operation only
#
#  EXIT CODES
#
#    0 = Success
#    1 = Failure
#
#  EXAMPLE RUN
#
#    [ SPLASHTOP UNINSTALL - macOS ]
#    --------------------------------------------------------------
#    Stopping Splashtop processes...
#    Unloading launch daemons...
#    Removing launch daemon files...
#    Removing application...
#    Removing shared data...
#    Removing kernel extensions...
#    Removing preferences...
#    Cleaning package receipts...
#
#    [ FINAL STATUS ]
#    --------------------------------------------------------------
#    Splashtop Streamer has been uninstalled
#
#    [ SCRIPT COMPLETE ]
#    --------------------------------------------------------------
#
# --------------------------------------------------------------------------------
#  CHANGELOG
# --------------------------------------------------------------------------------
#  2024-12-23 v1.1.0 Updated to Limehawk Script Framework
#  2024-01-01 v1.0.0 Initial release
# ================================================================================

# ============================================================================
# HARDCODED INPUTS
# ============================================================================
APP_BUNDLE_ID="com.splashtop.Splashtop-Streamer"
APP_NAME="Splashtop Streamer.app"
# ============================================================================

# ============================================================================
# MAIN EXECUTION
# ============================================================================

echo ""
echo "[ SPLASHTOP UNINSTALL - macOS ]"
echo "--------------------------------------------------------------"

# Kill running processes
echo "Stopping Splashtop processes..."
killall "Splashtop Streamer" 2>/dev/null || true
killall "inputserv" 2>/dev/null || true
killall "spupnp" 2>/dev/null || true
killall "SRProxy" 2>/dev/null || true
killall "SRFeature" 2>/dev/null || true
killall "SplashtopRemote" 2>/dev/null || true
killall "SRStreamerDaemon" 2>/dev/null || true

# Unload launch daemons
echo "Unloading launch daemons..."
sudo launchctl unload /Library/LaunchDaemons/com.splashtop.streamer-daemon.plist 2>/dev/null || true
sudo launchctl unload /Library/LaunchDaemons/com.splashtop.streamer-srioframebuffer.plist 2>/dev/null || true
sudo launchctl unload /Library/LaunchAgents/com.splashtop.streamer-for-user.plist 2>/dev/null || true
sudo launchctl unload /Library/LaunchAgents/com.splashtop.streamer-for-root.plist 2>/dev/null || true

# Remove launch daemon files
echo "Removing launch daemon files..."
sudo rm -rf /Library/LaunchDaemons/com.splashtop.streamer*.plist 2>/dev/null || true
sudo rm -rf /Library/LaunchAgents/com.splashtop.streamer*.plist 2>/dev/null || true

# Remove application
echo "Removing application..."
sudo rm -rf "/Applications/$APP_NAME" 2>/dev/null || true
sudo rm -rf "/Applications/Splashtop Streamer for Business.app" 2>/dev/null || true
sudo rm -rf "/Applications/SplashtopRemote.app" 2>/dev/null || true

# Remove shared data
echo "Removing shared data..."
sudo rm -rf /Users/Shared/SplashtopStreamer 2>/dev/null || true

# Remove kernel extensions
echo "Removing kernel extensions..."
sudo rm -rf /Library/Extensions/SRXFrameBufferConnector.kext 2>/dev/null || true
sudo rm -rf /Library/Extensions/SplashtopSoundDriver.kext 2>/dev/null || true
sudo rm -rf /System/Library/Extensions/SRXFrameBufferConnector.kext 2>/dev/null || true

# Remove audio plugin
sudo rm -rf "/Library/Audio/Plug-Ins/HAL/SplashtopRemoteSound.driver" 2>/dev/null || true

# Remove preferences
echo "Removing preferences..."
sudo rm -rf ~/Library/Preferences/${APP_BUNDLE_ID}.plist* 2>/dev/null || true
sudo rm -rf /var/root/Library/Preferences/${APP_BUNDLE_ID}.plist* 2>/dev/null || true

# Remove user caches
sudo rm -rf ~/Library/Caches/${APP_BUNDLE_ID} 2>/dev/null || true
sudo rm -rf ~/Library/Caches/iris-proxy-pipe* 2>/dev/null || true

# Forget package receipts
echo "Cleaning package receipts..."
sudo pkgutil --forget com.splashtop.splashtopStreamer.com.splashtop.streamer-daemon.pkg 2>/dev/null || true
sudo pkgutil --forget com.splashtop.splashtopStreamer.SplashtopStreamer.pkg 2>/dev/null || true
sudo pkgutil --forget ${APP_BUNDLE_ID} 2>/dev/null || true

echo ""
echo "[ FINAL STATUS ]"
echo "--------------------------------------------------------------"
echo "Splashtop Streamer has been uninstalled"

echo ""
echo "[ SCRIPT COMPLETE ]"
echo "--------------------------------------------------------------"
exit 0
