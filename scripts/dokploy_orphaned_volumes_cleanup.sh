#!/bin/bash
#
# ============================================================================
#                   DOKPLOY ORPHANED VOLUMES CLEANUP SCRIPT
# ============================================================================
#  Script Name: dokploy_orphaned_volumes_cleanup.sh
#  Description: Identifies and removes orphaned Docker volumes by scanning
#               all containers and Docker Swarm services for volume usage.
#               Provides detailed volume information and optional automatic
#               cleanup with configurable safe mode operation.
#  Author:      Limehawk LLC
#  Version:     1.0.0
#  Date:        November 2024
#  Usage:       sudo ./dokploy_orphaned_volumes_cleanup.sh
# ============================================================================
#
# ============================================================================
# CONFIGURATION SETTINGS - Modify these as needed
# ============================================================================
AUTO_REMOVE=true                      # Set to true to automatically remove orphaned volumes
                                      # Set to false to only list them (safe mode)
# ============================================================================

echo "==================================="
echo "Dokploy Orphaned Volumes Finder"
echo "==================================="
echo ""

echo "Step 1: Scanning containers for volume usage..."
# Get all volumes that are attached to any container (running or stopped)
used_volumes=$(docker ps -aq | xargs -r docker inspect --format '{{range .Mounts}}{{if eq .Type "volume"}}{{.Name}}{{"\n"}}{{end}}{{end}}' 2>/dev/null | sort -u)
container_count=$(docker ps -aq | wc -l)
echo "  ✓ Scanned $container_count containers"

echo ""
echo "Step 2: Scanning Docker Swarm services for volume usage..."
# Also check Docker Swarm services for volumes
swarm_volumes=$(docker service ls -q 2>/dev/null | xargs -r docker service inspect --format '{{range .Spec.TaskTemplate.ContainerSpec.Mounts}}{{if eq .Type "volume"}}{{.Source}}{{"\n"}}{{end}}{{end}}' 2>/dev/null | sort -u)
service_count=$(docker service ls -q 2>/dev/null | wc -l)
echo "  ✓ Scanned $service_count Swarm services"

# Combine both lists
all_used_volumes=$(echo -e "$used_volumes\n$swarm_volumes" | grep -v '^$' | sort -u)
used_count=$(echo "$all_used_volumes" | grep -v '^$' | wc -l)

echo ""
echo "Step 3: Getting all volumes on system..."
# Get all volumes
all_volumes=$(docker volume ls -q)
total_volume_count=$(echo "$all_volumes" | wc -l)
echo "  ✓ Found $total_volume_count total volumes"
echo "  ✓ Found $used_count volumes in use"

echo ""
echo "Step 4: Identifying orphaned volumes..."
echo ""

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
    echo "✓ No orphaned volumes found!"
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

        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Volume: $volume"
        echo "  Created: $created"
        echo "  Driver: $driver"
        echo "  Size: $size"
        echo "  Path: $mountpoint"
        echo "  Status: ⚠️  NOT USED by any container or service"
    done

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    if [ "$AUTO_REMOVE" = false ]; then
        echo "To remove these orphaned volumes:"
        echo "  1. Set AUTO_REMOVE=true at the top of this script"
        echo "  2. Or manually remove: docker volume rm <volume_name>"
        echo ""
        echo "⚠️  WARNING: Verify you don't need these volumes before removing!"
    fi
fi

echo ""
echo "==================================="

# ===================================================================
# AUTOMATIC REMOVAL SECTION
# ===================================================================

if [ "$AUTO_REMOVE" = true ] && [ ${#orphaned_volumes[@]} -gt 0 ]; then
    echo ""
    echo "Removing ${#orphaned_volumes[@]} orphaned volumes..."

    # Just remove them all at once
    for volume in "${orphaned_volumes[@]}"; do
        docker volume rm "$volume" 2>&1 | head -1
    done

    echo "Done!"
elif [ "$AUTO_REMOVE" = true ] && [ ${#orphaned_volumes[@]} -eq 0 ]; then
    echo ""
    echo "No orphaned volumes to remove."
fi
