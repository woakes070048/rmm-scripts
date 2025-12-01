#!/bin/bash
# ==============================================================================
# SCRIPT : Workstation Information Popup (macOS)                         v1.0.0
# FILE   : workstation_info_macos.sh
# ==============================================================================
# PURPOSE:
#   Displays a popup dialog showing system information to the end user.
#   Designed to be triggered from the RMM tray icon for user self-service.
#
# COLLECTS:
#   - Operating System name and version
#   - Computer name and current user
#   - CPU name and core count
#   - Total RAM
#   - Network adapter info
#
# PREREQUISITES:
#   - macOS 10.14 or later
#   - No special privileges required
#
# CHANGELOG:
#   2024-12-01 v1.0.0  Initial release - migrated from SuperOps
# ==============================================================================

# Collect system information
os_name=$(sw_vers -productName 2>/dev/null || echo "macOS")
os_version=$(sw_vers -productVersion 2>/dev/null || echo "Unknown")
computer_name=$(scutil --get ComputerName 2>/dev/null || hostname)
current_user=$(whoami)
cpu_name=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "Unknown")
cpu_cores=$(sysctl -n hw.ncpu 2>/dev/null || echo "Unknown")
total_ram=$(sysctl -n hw.memsize 2>/dev/null | awk '{ printf "%.2f", $1/1024/1024/1024 }')

# Get primary network adapter info
primary_ip=$(ipconfig getifaddr en0 2>/dev/null || echo "Not connected")
if [[ "$primary_ip" == "Not connected" ]]; then
    primary_ip=$(ipconfig getifaddr en1 2>/dev/null || echo "Not connected")
fi

# Build the AppleScript dialog
applescript_code=$(cat <<EOF
display dialog "=== Workstation Information ===" & return & return ¬
  & "=== Operating System ===" & return ¬
  & "Name: $os_name" & return ¬
  & "Version: $os_version" & return & return ¬
  & "=== Computer ===" & return ¬
  & "Name: $computer_name" & return ¬
  & "User: $current_user" & return & return ¬
  & "=== Hardware ===" & return ¬
  & "CPU: $cpu_name" & return ¬
  & "Cores: $cpu_cores" & return ¬
  & "RAM: $total_ram GB" & return & return ¬
  & "=== Network ===" & return ¬
  & "IP Address: $primary_ip" ¬
  with title "Workstation Information" buttons {"OK"} default button "OK"
EOF
)

# Execute the AppleScript to display popup (run in background so script exits)
osascript -e "$applescript_code" >/dev/null 2>&1 &

exit 0
