#!/bin/bash
#
# ██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
# ██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
# ██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
# ██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
# ███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
# ╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
# ================================================================================
#  SCRIPT   : Splashtop Uninstall (macOS)                                  v1.1.1
#  AUTHOR   : Limehawk.io
#  DATE     : January 2026
#  USAGE    : sudo ./splashtop_uninstall_macos.sh
# ================================================================================
#  FILE     : splashtop_uninstall_macos.sh
#  DESCRIPTION : Completely removes Splashtop Streamer and all components from macOS
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
#    [RUN] STOPPING PROCESSES
#    ==============================================================
#    Stopping Splashtop processes...
#
#    [RUN] UNLOADING DAEMONS
#    ==============================================================
#    Unloading launch daemons...
#
#    [RUN] REMOVING DAEMON FILES
#    ==============================================================
#    Removing launch daemon files...
#
#    [RUN] REMOVING APPLICATION
#    ==============================================================
#    Removing application...
#
#    [RUN] REMOVING DATA
#    ==============================================================
#    Removing shared data...
#    Removing kernel extensions...
#
#    [RUN] REMOVING PREFERENCES
#    ==============================================================
#    Removing preferences...
#
#    [RUN] CLEANING RECEIPTS
#    ==============================================================
#    Cleaning package receipts...
#
#    [OK] SCRIPT COMPLETED
#    ==============================================================
#    Splashtop Streamer has been uninstalled
#
# --------------------------------------------------------------------------------
#  CHANGELOG
# --------------------------------------------------------------------------------
#  2026-01-19 v1.1.1 Updated to two-line ASCII console output style
#  2025-12-23 v1.1.0 Updated to Limehawk Script Framework
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
echo "[RUN] STOPPING PROCESSES"
echo "=============================================================="

# Kill running processes
echo "Stopping Splashtop processes..."
killall "Splashtop Streamer" 2>/dev/null || true
killall "inputserv" 2>/dev/null || true
killall "spupnp" 2>/dev/null || true
killall "SRProxy" 2>/dev/null || true
killall "SRFeature" 2>/dev/null || true
killall "SplashtopRemote" 2>/dev/null || true
killall "SRStreamerDaemon" 2>/dev/null || true

echo ""
echo "[RUN] UNLOADING DAEMONS"
echo "=============================================================="

# Unload launch daemons
echo "Unloading launch daemons..."
sudo launchctl unload /Library/LaunchDaemons/com.splashtop.streamer-daemon.plist 2>/dev/null || true
sudo launchctl unload /Library/LaunchDaemons/com.splashtop.streamer-srioframebuffer.plist 2>/dev/null || true
sudo launchctl unload /Library/LaunchAgents/com.splashtop.streamer-for-user.plist 2>/dev/null || true
sudo launchctl unload /Library/LaunchAgents/com.splashtop.streamer-for-root.plist 2>/dev/null || true

echo ""
echo "[RUN] REMOVING DAEMON FILES"
echo "=============================================================="

# Remove launch daemon files
echo "Removing launch daemon files..."
sudo rm -rf /Library/LaunchDaemons/com.splashtop.streamer*.plist 2>/dev/null || true
sudo rm -rf /Library/LaunchAgents/com.splashtop.streamer*.plist 2>/dev/null || true

echo ""
echo "[RUN] REMOVING APPLICATION"
echo "=============================================================="

# Remove application
echo "Removing application..."
sudo rm -rf "/Applications/$APP_NAME" 2>/dev/null || true
sudo rm -rf "/Applications/Splashtop Streamer for Business.app" 2>/dev/null || true
sudo rm -rf "/Applications/SplashtopRemote.app" 2>/dev/null || true

echo ""
echo "[RUN] REMOVING DATA"
echo "=============================================================="

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

echo ""
echo "[RUN] REMOVING PREFERENCES"
echo "=============================================================="

# Remove preferences
echo "Removing preferences..."
sudo rm -rf ~/Library/Preferences/${APP_BUNDLE_ID}.plist* 2>/dev/null || true
sudo rm -rf /var/root/Library/Preferences/${APP_BUNDLE_ID}.plist* 2>/dev/null || true

# Remove user caches
sudo rm -rf ~/Library/Caches/${APP_BUNDLE_ID} 2>/dev/null || true
sudo rm -rf ~/Library/Caches/iris-proxy-pipe* 2>/dev/null || true

echo ""
echo "[RUN] CLEANING RECEIPTS"
echo "=============================================================="

# Forget package receipts
echo "Cleaning package receipts..."
sudo pkgutil --forget com.splashtop.splashtopStreamer.com.splashtop.streamer-daemon.pkg 2>/dev/null || true
sudo pkgutil --forget com.splashtop.splashtopStreamer.SplashtopStreamer.pkg 2>/dev/null || true
sudo pkgutil --forget ${APP_BUNDLE_ID} 2>/dev/null || true

echo ""
echo "[OK] SCRIPT COMPLETED"
echo "=============================================================="
echo "Splashtop Streamer has been uninstalled"
exit 0
