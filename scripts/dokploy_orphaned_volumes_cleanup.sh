#!/bin/bash
#
# ██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
# ██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
# ██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
# ██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
# ███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
# ╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
# ================================================================================
#  SCRIPT   : Dokploy Orphaned Volumes Cleanup                             v1.1.1
#  AUTHOR   : Limehawk.io
#  DATE     : January 2026
#  USAGE    : sudo ./dokploy_orphaned_volumes_cleanup.sh
# ================================================================================
#  FILE     : dokploy_orphaned_volumes_cleanup.sh
#  DESCRIPTION : Identifies and removes orphaned Docker volumes to free space
# --------------------------------------------------------------------------------
#  README
# --------------------------------------------------------------------------------
#  PURPOSE
#
#    Scans Docker containers and Swarm services to identify volumes that are
#  not currently mounted or in use. Provides detailed information about
#  orphaned volumes including size, creation date, and mount point. Can
#  optionally remove orphaned volumes automatically to free up disk space.
#
#  CONFIGURATION
#  -----------------------------------------------------------------------
#  - AUTO_REMOVE: Set to true to automatically remove orphaned volumes,
#    false for safe mode (list only)
#
#  BEHAVIOR
#  -----------------------------------------------------------------------
#  1. Scans all Docker containers (running and stopped) for volume mounts
#  2. Scans all Docker Swarm services for volume usage
#  3. Compares all system volumes against used volumes
#  4. Displays detailed information for each orphaned volume
#  5. Optionally removes orphaned volumes if AUTO_REMOVE is true
#
#  PREREQUISITES
#  -----------------------------------------------------------------------
#  - Docker installed and running
#  - Root/sudo access for volume inspection and removal
#  - Docker Swarm (optional, script works without it)
#
#  SECURITY NOTES
#  -----------------------------------------------------------------------
#  - No secrets exposed in output
#  - Requires privileged access to Docker daemon
#  - Volume data is permanently deleted when removed
#
#  EXIT CODES
#  -----------------------------------------------------------------------
#  0 - Success
#  1 - Failure (error occurred)
#
#  EXAMPLE OUTPUT
#  -----------------------------------------------------------------------
#
#    [RUN] SCANNING CONTAINERS
#    ==============================================================
#    Scanning containers for volume usage...
#    Scanned 15 containers
#
#    [RUN] SCANNING SWARM SERVICES
#    ==============================================================
#    Scanning Docker Swarm services for volume usage...
#    Scanned 3 Swarm services
#
#    [RUN] ANALYZING VOLUMES
#    ==============================================================
#    Getting all volumes on system...
#    Found 20 total volumes
#    Found 18 volumes in use
#
#    [INFO] ORPHANED VOLUMES FOUND
#    ==============================================================
#    Found 2 orphaned volume(s):
#
#    Volume: old_app_data
#      Created: 2024-10-15 14:23:45
#      Driver: local
#      Size: 2.3G
#      Path: /var/lib/docker/volumes/old_app_data/_data
#      Status: NOT USED by any container or service
#
#    [RUN] REMOVING VOLUMES
#    ==============================================================
#    Removing 2 orphaned volumes...
#    Done!
#
#    [OK] SCRIPT COMPLETED
#    ==============================================================
#
# --------------------------------------------------------------------------------
#  CHANGELOG
# --------------------------------------------------------------------------------
#  2026-01-19 v1.1.1 Updated to two-line ASCII console output style
#  2025-12-23 v1.1.0 Updated to Limehawk Script Framework
#  2024-11-18 v1.0.0 Initial release
# ================================================================================

# ============================================================================
# CONFIGURATION SETTINGS - Modify these as needed
# ============================================================================
AUTO_REMOVE=true                      # Set to true to automatically remove orphaned volumes
                                      # Set to false to only list them (safe mode)
# ============================================================================

echo ""
echo "[RUN] SCANNING CONTAINERS"
echo "=============================================================="
echo "Scanning containers for volume usage..."
# Get all volumes that are attached to any container (running or stopped)
used_volumes=$(docker ps -aq | xargs -r docker inspect --format '{{range .Mounts}}{{if eq .Type "volume"}}{{.Name}}{{"\n"}}{{end}}{{end}}' 2>/dev/null | sort -u)
container_count=$(docker ps -aq | wc -l)
echo "Scanned $container_count containers"

echo ""
echo "[RUN] SCANNING SWARM SERVICES"
echo "=============================================================="
echo "Scanning Docker Swarm services for volume usage..."
# Also check Docker Swarm services for volumes
swarm_volumes=$(docker service ls -q 2>/dev/null | xargs -r docker service inspect --format '{{range .Spec.TaskTemplate.ContainerSpec.Mounts}}{{if eq .Type "volume"}}{{.Source}}{{"\n"}}{{end}}{{end}}' 2>/dev/null | sort -u)
service_count=$(docker service ls -q 2>/dev/null | wc -l)
echo "Scanned $service_count Swarm services"

# Combine both lists
all_used_volumes=$(echo -e "$used_volumes\n$swarm_volumes" | grep -v '^$' | sort -u)
used_count=$(echo "$all_used_volumes" | grep -v '^$' | wc -l)

echo ""
echo "[RUN] ANALYZING VOLUMES"
echo "=============================================================="
echo "Getting all volumes on system..."
# Get all volumes
all_volumes=$(docker volume ls -q)
total_volume_count=$(echo "$all_volumes" | wc -l)
echo "Found $total_volume_count total volumes"
echo "Found $used_count volumes in use"

echo ""
echo "[INFO] IDENTIFYING ORPHANED VOLUMES"
echo "=============================================================="

# Find orphaned volumes (volumes that exist but aren't in the used list)
orphaned_volumes=()

for volume in $all_volumes; do
    # Check if this volume is in the all_used_volumes list
    if ! echo "$all_used_volumes" | grep -q "^${volume}$"; then
        orphaned_volumes+=("$volume")
    fi
done

# Display results
if [ ${#orphaned_volumes[@]} -eq 0 ]; then
    echo "No orphaned volumes found!"
    echo "All $total_volume_count volumes are attached to containers or services."
else
    echo "Found ${#orphaned_volumes[@]} orphaned volume(s):"
    echo ""

    for volume in "${orphaned_volumes[@]}"; do
        created=$(docker volume inspect "$volume" --format '{{.CreatedAt}}' 2>/dev/null || echo "Unknown")
        mountpoint=$(docker volume inspect "$volume" --format '{{.Mountpoint}}' 2>/dev/null || echo "Unknown")
        driver=$(docker volume inspect "$volume" --format '{{.Driver}}' 2>/dev/null || echo "local")

        # Try to get size
        if [ "$mountpoint" != "Unknown" ] && [ -d "$mountpoint" ]; then
            size=$(du -sh "$mountpoint" 2>/dev/null | cut -f1 || echo "Unknown")
        else
            size="Unknown"
        fi

        echo "Volume: $volume"
        echo "  Created: $created"
        echo "  Driver: $driver"
        echo "  Size: $size"
        echo "  Path: $mountpoint"
        echo "  Status: NOT USED by any container or service"
        echo ""
    done

    if [ "$AUTO_REMOVE" = false ]; then
        echo ""
        echo "[WARN] MANUAL REMOVAL REQUIRED"
        echo "=============================================================="
        echo "To remove these orphaned volumes:"
        echo "  1. Set AUTO_REMOVE=true at the top of this script"
        echo "  2. Or manually remove: docker volume rm <volume_name>"
        echo ""
        echo "WARNING: Verify you don't need these volumes before removing!"
    fi
fi

# ===================================================================
# AUTOMATIC REMOVAL SECTION
# ===================================================================

if [ "$AUTO_REMOVE" = true ] && [ ${#orphaned_volumes[@]} -gt 0 ]; then
    echo ""
    echo "[RUN] REMOVING VOLUMES"
    echo "=============================================================="
    echo "Removing ${#orphaned_volumes[@]} orphaned volumes..."

    # Just remove them all at once
    for volume in "${orphaned_volumes[@]}"; do
        docker volume rm "$volume" 2>&1 | head -1
    done

    echo "Done!"
elif [ "$AUTO_REMOVE" = true ] && [ ${#orphaned_volumes[@]} -eq 0 ]; then
    echo "No orphaned volumes to remove."
fi

echo ""
echo "[OK] SCRIPT COMPLETED"
echo "=============================================================="
