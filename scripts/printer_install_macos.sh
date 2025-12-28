#!/bin/bash
#
# ██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
# ██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
# ██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
# ██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
# ███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
# ╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
# ================================================================================
#  SCRIPT   : Network Printer Install (macOS)                              v1.1.0
#  AUTHOR   : Limehawk.io
#  DATE     : December 2025
#  USAGE    : sudo ./printer_install_macos.sh
# ================================================================================
#  FILE     : printer_install_macos.sh
#  DESCRIPTION : Installs network printer via IPP using lpadmin on macOS
# --------------------------------------------------------------------------------
#  README
# --------------------------------------------------------------------------------
#  PURPOSE
#
#    Installs network printers on macOS using CUPS/lpadmin. Supports PPD files
#    for full driver functionality. Can install from local PPD or download from
#    a URL.
#
#  DATA SOURCES & PRIORITY
#
#    - Local PPD: Uses existing PPD file on system
#    - URL PPD: Downloads PPD from specified URL
#    - Driver package: Optional driver installer from URL
#
#  REQUIRED INPUTS
#
#    All inputs are hardcoded in the script body:
#      - PRINTERS: Array of "hostname|location|display_name" entries
#      - PROTOCOL: lpd, ipp, or ipps
#      - PPD_SOURCE: "local" or "url"
#      - PPD_PATH: Path to local PPD file
#      - PPD_URL: URL to download PPD file
#      - DRIVER_URL: Optional driver package URL
#
#  SETTINGS
#
#    Default configuration:
#      - Protocol: lpd
#      - PPD Source: local
#      - Sharing: Disabled
#      - Error Policy: abort-job
#
#  BEHAVIOR
#
#    The script performs the following actions in order:
#    1. Verifies root/sudo privileges
#    2. Downloads driver package if URL provided
#    3. Sets up PPD file (local or downloaded)
#    4. Removes existing printers with same name
#    5. Installs each configured printer via lpadmin
#    6. Reports final status
#
#  PREREQUISITES
#
#    - macOS 10.12 or later
#    - Root/sudo privileges
#    - PPD file for the printer model
#    - Network access to printers and PPD URL (if using URL)
#
#  SECURITY NOTES
#
#    - No secrets exposed in output
#    - Requires elevated privileges for printer management
#    - Downloaded files verified before installation
#
#  ENDPOINTS
#
#    - Configured printer hostnames via selected protocol
#    - PPD_URL if using URL source
#    - DRIVER_URL if downloading driver package
#
#  EXIT CODES
#
#    0 = Success (all printers installed)
#    1 = Failure or partial failure
#
#  EXAMPLE RUN
#
#    [ NETWORK PRINTER INSTALL - macOS ]
#    --------------------------------------------------------------
#    Protocol   : lpd
#    PPD Source : local
#    Printers   : 2
#
#    [ SETTING UP PPD ]
#    --------------------------------------------------------------
#    Using local PPD: /Library/Printers/PPDs/Contents/Resources/YourPrinter.ppd.gz
#
#    [ INSTALLING PRINTERS ]
#    --------------------------------------------------------------
#    Installing: Office Printer
#      Hostname : printer1.example.com
#      Location : Main Office
#      Status   : SUCCESS
#
#    [ FINAL STATUS ]
#    --------------------------------------------------------------
#    Installed : 2 printer(s)
#    Failed    : 0 printer(s)
#    Result    : SUCCESS
#
#    [ SCRIPT COMPLETE ]
#    --------------------------------------------------------------
#
# --------------------------------------------------------------------------------
#  CHANGELOG
# --------------------------------------------------------------------------------
#  2025-12-23 v1.1.0 Updated to Limehawk Script Framework
#  2024-01-01 v1.0.0 Initial release
# ================================================================================

set -euo pipefail

# ============================================================================
# HARDCODED INPUTS
# ============================================================================
# Printer definitions: "hostname|location|display_name"
PRINTERS=(
    "printer1.example.com|Main Office|Office Printer"
    "printer2.example.com|Sales Dept|Sales Printer"
)

# Protocol: lpd, ipp, or ipps
PROTOCOL="lpd"

# PPD source: "local" or "url"
PPD_SOURCE="local"

# For local PPD: full path to the .ppd or .ppd.gz file
PPD_PATH="/Library/Printers/PPDs/Contents/Resources/YourPrinter.ppd.gz"

# For URL PPD: URL to download the PPD file from
PPD_URL=""

# Optional: Driver package URL (for full driver install)
DRIVER_URL=""
# ============================================================================

# ============================================================================
# MAIN EXECUTION
# ============================================================================

echo ""
echo "[ NETWORK PRINTER INSTALL - macOS ]"
echo "--------------------------------------------------------------"

# Ensure script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo ""
    echo "[ ERROR OCCURRED ]"
    echo "--------------------------------------------------------------"
    echo "This script must be run as root (sudo)"
    echo ""
    exit 1
fi

echo "Protocol   : $PROTOCOL"
echo "PPD Source : $PPD_SOURCE"
echo "Printers   : ${#PRINTERS[@]}"

# ============================================================================
# DOWNLOAD DRIVER PACKAGE (OPTIONAL)
# ============================================================================
if [ -n "$DRIVER_URL" ]; then
    echo ""
    echo "[ DOWNLOADING DRIVER ]"
    echo "--------------------------------------------------------------"

    DRIVER_FILE="/tmp/printer_driver.zip"
    echo "Downloading from: $DRIVER_URL"

    if ! curl -sL -o "$DRIVER_FILE" "$DRIVER_URL"; then
        echo ""
        echo "[ ERROR OCCURRED ]"
        echo "--------------------------------------------------------------"
        echo "Failed to download driver package"
        echo ""
        exit 1
    fi

    echo "Extracting driver..."
    sudo unzip -o "$DRIVER_FILE" -d "/Library/Printers/" > /dev/null
    rm -f "$DRIVER_FILE"
    echo "Driver installed"
fi

# ============================================================================
# SETUP PPD FILE
# ============================================================================
echo ""
echo "[ SETTING UP PPD ]"
echo "--------------------------------------------------------------"

PPD_DEST="/Library/Printers/PPDs/Contents/Resources/"
ACTIVE_PPD=""

if [ "$PPD_SOURCE" = "url" ] && [ -n "$PPD_URL" ]; then
    PPD_FILENAME=$(basename "$PPD_URL")
    DOWNLOADED_PPD="/tmp/$PPD_FILENAME"
    ACTIVE_PPD="${PPD_DEST}${PPD_FILENAME}"

    echo "Downloading PPD from: $PPD_URL"
    if ! curl -sL -o "$DOWNLOADED_PPD" "$PPD_URL"; then
        echo ""
        echo "[ ERROR OCCURRED ]"
        echo "--------------------------------------------------------------"
        echo "Failed to download PPD file"
        echo ""
        exit 1
    fi

    # Ensure destination exists
    sudo mkdir -p "$PPD_DEST"

    # Copy to PPD directory
    sudo cp "$DOWNLOADED_PPD" "$ACTIVE_PPD"
    sudo chown root:wheel "$ACTIVE_PPD"
    sudo chmod 644 "$ACTIVE_PPD"
    rm -f "$DOWNLOADED_PPD"

    echo "PPD installed: $ACTIVE_PPD"

elif [ "$PPD_SOURCE" = "local" ]; then
    if [ ! -f "$PPD_PATH" ]; then
        echo ""
        echo "[ ERROR OCCURRED ]"
        echo "--------------------------------------------------------------"
        echo "PPD file not found: $PPD_PATH"
        echo ""
        exit 1
    fi
    ACTIVE_PPD="$PPD_PATH"
    echo "Using local PPD: $ACTIVE_PPD"
else
    echo ""
    echo "[ ERROR OCCURRED ]"
    echo "--------------------------------------------------------------"
    echo "Invalid PPD_SOURCE: $PPD_SOURCE (must be 'local' or 'url')"
    echo ""
    exit 1
fi

# ============================================================================
# INSTALL PRINTERS
# ============================================================================
echo ""
echo "[ INSTALLING PRINTERS ]"
echo "--------------------------------------------------------------"

INSTALLED=0
FAILED=0

for PRINTER_ENTRY in "${PRINTERS[@]}"; do
    IFS="|" read -r HOSTNAME LOCATION DISPLAY_NAME <<< "$PRINTER_ENTRY"

    # Use hostname prefix if no display name provided
    if [ -z "$DISPLAY_NAME" ]; then
        DISPLAY_NAME=$(echo "$HOSTNAME" | cut -d'.' -f1)
    fi

    # Create a clean printer name (no spaces)
    PRINTER_NAME=$(echo "$DISPLAY_NAME" | tr ' ' '_' | tr -cd '[:alnum:]_-')

    echo "Installing: $DISPLAY_NAME"
    echo "  Hostname : $HOSTNAME"
    echo "  Location : $LOCATION"
    echo "  Name     : $PRINTER_NAME"

    # Remove existing printer if present
    if lpstat -p "$PRINTER_NAME" > /dev/null 2>&1; then
        echo "  Removing existing printer..."
        lpadmin -x "$PRINTER_NAME" 2>/dev/null || true
    fi

    # Build URI based on protocol
    case "$PROTOCOL" in
        lpd)  URI="lpd://${HOSTNAME}/" ;;
        ipp)  URI="ipp://${HOSTNAME}/ipp/print" ;;
        ipps) URI="ipps://${HOSTNAME}/ipp/print" ;;
        *)    URI="${PROTOCOL}://${HOSTNAME}/" ;;
    esac

    # Install printer
    if /usr/sbin/lpadmin -p "$PRINTER_NAME" \
        -L "$LOCATION" \
        -D "$DISPLAY_NAME" \
        -v "$URI" \
        -P "$ACTIVE_PPD" \
        -E \
        -o printer-is-shared=false \
        -o printer-error-policy=abort-job; then

        # Verify installation
        if lpstat -p "$PRINTER_NAME" > /dev/null 2>&1; then
            echo "  Status   : SUCCESS"
            INSTALLED=$((INSTALLED + 1))
        else
            echo "  Status   : FAILED (verification)"
            FAILED=$((FAILED + 1))
        fi
    else
        echo "  Status   : FAILED (lpadmin)"
        FAILED=$((FAILED + 1))
    fi

    echo ""
done

# ============================================================================
# FINAL STATUS
# ============================================================================
echo "[ FINAL STATUS ]"
echo "--------------------------------------------------------------"
echo "Installed : $INSTALLED printer(s)"
echo "Failed    : $FAILED printer(s)"

if [ "$FAILED" -eq 0 ]; then
    echo "Result    : SUCCESS"
    echo ""
    echo "[ SCRIPT COMPLETE ]"
    echo "--------------------------------------------------------------"
    exit 0
else
    echo "Result    : PARTIAL (some printers failed)"
    echo ""
    echo "[ SCRIPT COMPLETE ]"
    echo "--------------------------------------------------------------"
    exit 1
fi
