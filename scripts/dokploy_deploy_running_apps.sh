#!/bin/bash
#
# ============================================================================
#                  DOKPLOY DEPLOY RUNNING APPLICATIONS SCRIPT
# ============================================================================
#  Script Name: dokploy_deploy_running_apps.sh
#  Description: Automatically fetches all Dokploy applications and triggers
#               deployments for running applications while skipping idle ones.
#               Uses the Dokploy API to retrieve application status and
#               initiate deployments with proper error handling.
#  Author:      Limehawk.io
#  Version:     1.0.0
#  Date:        November 2024
#  Usage:       ./dokploy_deploy_running_apps.sh
# ============================================================================
#
# ============================================================================
#      ██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
#      ██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
#      ██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝
#      ██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗
#      ███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
#      ╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
# ============================================================================
#
#  PURPOSE
#  -----------------------------------------------------------------------
#  Automates the deployment process for all running Dokploy applications.
#  Fetches application metadata via the Dokploy API, checks each app's
#  status, and triggers deployments only for apps that are currently
#  running. Idle applications are skipped to prevent unnecessary resource
#  usage and deployment conflicts.
#
#  CONFIGURATION
#  -----------------------------------------------------------------------
#  - DOKPLOY_DOMAIN: Your Dokploy domain (e.g., "app.dokploy.com")
#  - API_TOKEN: API token from Dokploy profile settings
#
#  BEHAVIOR
#  -----------------------------------------------------------------------
#  1. Fetches all application IDs from Dokploy via API
#  2. Iterates through each application ID
#  3. Retrieves application info including status, name, and project
#  4. Skips applications with "idle" status
#  5. Triggers deployment for applications with "running" status
#  6. Displays progress and results for each application
#  7. Adds 2-second delay between deployments to avoid API rate limits
#
#  PREREQUISITES
#  -----------------------------------------------------------------------
#  - curl installed
#  - Network connectivity to Dokploy domain
#  - Valid Dokploy API token with deployment permissions
#  - Dokploy domain properly configured
#
#  SECURITY NOTES
#  -----------------------------------------------------------------------
#  - API token must be kept secure and not committed to version control
#  - Replace API_TOKEN placeholder before running
#  - API calls use HTTPS for encrypted communication
#  - No sensitive data logged to console
#
#  EXIT CODES
#  -----------------------------------------------------------------------
#  0 - Success (all deployments processed)
#  1 - Failure (error occurred during execution)
#
#  EXAMPLE OUTPUT
#  -----------------------------------------------------------------------
#  ➡️  Fetching all application IDs...
#  ✅ Found all applications. Starting status check...
#  ------------------------------------------------
#  Fetching info for app: abc123def456
#  🟡 Skipping 'idle' app: Project: MyProject, App: MyApp (ID: abc123def456)
#  ------------------------------------------------
#  Fetching info for app: xyz789ghi012
#  🚀 Triggering deployment for 'running' app (running): Project: WebApp, App: Frontend (ID: xyz789ghi012)
#  ✔️  Deployment triggered for WebApp - Frontend.
#  ------------------------------------------------
#  🎉 All deployments have been processed!
#
#  CHANGELOG
#  -----------------------------------------------------------------------
#  2024-11-18 v1.0.0 Initial release with Limehawk Style A formatting
#
# ============================================================================

# ============================================================================
# CONFIGURATION SETTINGS - Modify these as needed
# ============================================================================
# Replace with your Dokploy domain (e.g., "app.dokploy.com")
DOKPLOY_DOMAIN="YOUR_DOMAIN_HERE"
# Replace with your API token from Dokploy profile settings
API_TOKEN="API_TOKEN_HERE"
# ============================================================================

# Set to exit immediately if a command exits with a non-zero status.
set -e

echo "➡️  Fetching all application IDs..."

# 1. Get ALL application IDs
ALL_IDS=$(curl -s -X GET \
  "https://$DOKPLOY_DOMAIN/api/project.all" \
  -H "accept: application/json" \
  -H "x-api-key: $API_TOKEN" | \
  grep -o '"applicationId":"[^"]*"' | \
  cut -d '"' -f 4 | sort -u)

# Check if we got any IDs at all
if [ -z "$ALL_IDS" ]; then
  echo "✅ No applications found."
  exit 0
fi

echo "✅ Found all applications. Starting status check..."
echo "------------------------------------------------"

# 2. Loop through ALL IDs and check them one by one
for ID in $ALL_IDS
do
  echo "Fetching info for app: $ID"

  # Call application.one ONCE and store the response
  APP_INFO=$(curl -s -X GET \
    "https://$DOKPLOY_DOMAIN/api/application.one?applicationId=$ID" \
    -H "accept: application/json" \
    -H "x-api-key: $API_TOKEN")

  # Extract the status
  APP_STATUS=$(echo "$APP_INFO" | \
    grep -o '"applicationStatus":"[^"]*"' | \
    cut -d '"' -f 4)

  # Extract all "name" fields
  ALL_NAMES=$(echo "$APP_INFO" | \
    grep -o '"name":"[^"]*"' | \
    cut -d '"' -f 4)

  # The first name is the Application Name
  APP_NAME=$(echo "$ALL_NAMES" | head -n 1)
  # The last name is the Project Name
  PROJECT_NAME=$(echo "$ALL_NAMES" | tail -n 1)


  # 3. Check the status and decide to deploy or skip
  if [ "$APP_STATUS" == "idle" ]; then
    echo "🟡 Skipping 'idle' app: Project: $PROJECT_NAME, App: $APP_NAME (ID: $ID)"
  else
    echo "🚀 Triggering deployment for 'running' app ($APP_STATUS): Project: $PROJECT_NAME, App: $APP_NAME (ID: $ID)"

    curl --fail -s -X POST \
      "https://$DOKPLOY_DOMAIN/api/application.deploy" \
      -H "accept: application/json" \
      -H "Content-Type: application/json" \
      -H "x-api-key: $API_TOKEN" \
      -d "{\"applicationId\": \"$ID\"}"

    echo "✔️  Deployment triggered for $PROJECT_NAME - $APP_NAME."
    sleep 2
  fi
  echo "------------------------------------------------"
done

echo "🎉 All deployments have been processed!"
