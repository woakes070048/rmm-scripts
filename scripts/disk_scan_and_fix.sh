#!/bin/bash

# Get the list of all mounted disks using diskutil
DISKS=$(diskutil list | grep 'disk[0-9]' | awk '{print $1}')

echo "Starting comprehensive disk and volume health check..."

# Loop through each disk
for disk in $DISKS; do
    echo "Checking partition map health for $disk..."
    
    # Using diskutil to verify the partition map
    diskutil verifyDisk $disk
    
    # Check if the verifyDisk command was successful
    if [ $? -eq 0 ]; then
        echo "Partition map of $disk appears to be OK."
    else
        echo "An error occurred with the partition map of $disk. Check the disk using Disk Utility."
    fi

    # Get the list of volumes on the disk
    VOLUMES=$(diskutil list $disk | grep 'Apple_HFS\|Apple_APFS' | awk '{print $3}')
    
    # Loop through each volume on the disk
    for volume in $VOLUMES; do
        echo "Checking file system health for $volume on $disk..."
        
        # Using diskutil to verify the volume
        diskutil verifyVolume "$volume"
        
        # Check if the verifyVolume command was successful
        if [ $? -eq 0 ]; then
            echo "File system of $volume on $disk appears to be OK."
        else
            echo "An error occurred with the file system of $volume on $disk. Check the volume using Disk Utility."
        fi
    done

    # Check if the disk supports SMART status
    SMART_STATUS=$(diskutil info $disk | grep "SMART Status" | awk '{print $3}')
    if [ "$SMART_STATUS" == "Supported" ]; then
        echo "Checking SMART status for $disk..."
        diskutil smartStatus $disk

        if [ $? -eq 0 ]; then
            echo "SMART status of $disk indicates it is OK."
        else
            echo "SMART status check failed or indicates an issue with $disk. Consider further diagnostics."
        fi
    else
        echo "SMART status not supported for $disk."
    fi
done

echo "Comprehensive health check completed."
