#!/bin/bash
#
# SentinelOne Agent Uninstall Script for Linux/macOS
# Version: 1.0.0
# Description: Uninstalls SentinelOne agent using sentinelctl command
#

set -e

echo ""
echo "[ SENTINELONE UNINSTALL ]"
echo "--------------------------------------------------------------"
echo "Starting SentinelOne agent uninstallation..."
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: This script must be run as root"
    echo ""
    echo "Troubleshooting:"
    echo "- Run with: sudo $0"
    echo "- Or run from RMM with root/sudo privileges"
    echo ""
    exit 1
fi

echo "Permissions : root"
echo ""

# Check if sentinelctl exists
if ! command -v sentinelctl &> /dev/null; then
    echo "ERROR: sentinelctl command not found"
    echo ""
    echo "Troubleshooting:"
    echo "- SentinelOne agent may not be installed"
    echo "- sentinelctl should be in /usr/local/bin or /opt/sentinelone/bin"
    echo ""
    exit 1
fi

echo "sentinelctl found : yes"
echo ""

# Uninstall SentinelOne agent
echo "Running uninstall command..."
sudo sentinelctl uninstall

# Check exit code
if [ $? -eq 0 ]; then
    echo ""
    echo "[ SUCCESS ]"
    echo "--------------------------------------------------------------"
    echo "SentinelOne agent uninstalled successfully"
    echo ""
    exit 0
else
    echo ""
    echo "[ ERROR ]"
    echo "--------------------------------------------------------------"
    echo "SentinelOne uninstall failed"
    echo ""
    echo "Troubleshooting:"
    echo "- Check if agent is protected by tamper protection"
    echo "- Verify sentinelctl has proper permissions"
    echo "- Review system logs for details"
    echo ""
    exit 1
fi
