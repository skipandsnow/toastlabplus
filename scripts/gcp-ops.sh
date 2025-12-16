#!/bin/bash

# ==========================================
# ToastLabPlus GCP Operations Script
# Usage: ./gcp-ops.sh [start|stop]
# ==========================================

PROJECT_ID="toastlabplus"
REGION="asia-east1"
SQL_INSTANCE="toastlabplus-db"

# Cloud Run Services
SERVICES_STAGING=("mcp-server-staging" "chat-backend-staging")
SERVICES_PROD=("mcp-server" "chat-backend")

function stop_all() {
  echo "🛑 Stopping all services to save cost..."
  
  # 1. Scale Cloud Run to 0 (This effectively "pauses" them)
  echo ">> Scaling Cloud Run services to 0..."
  all_services=("${SERVICES_STAGING[@]}" "${SERVICES_PROD[@]}")
  for service in "${all_services[@]}"; do
    echo "   - Scaling down $service..."
    # Set max-instances to 0 effectively disables the service
    # Warning: Setting max to 0 might not be allowed strictly, usually we set min=0. 
    # Actually, gcloud doesn't support max-instances=0 directly to stop. 
    # To 'stop', we can delete revisions or set ingress to internal. 
    # But usually setting min=0 is enough for cost saving (pay per use).
    # To force stop cost for Prod (which has min=1), we set min=0.
    
    gcloud run services update $service --region $REGION --min-instances 0 --max-instances 1 --project $PROJECT_ID --quiet
  done
  echo "   (Note: Services scaled to min=0. They will still respond to requests but with cold start. To completely block, you'd need to change ingress to internal)"

  # 2. Stop Cloud SQL
  # Cloud SQL charges for storage even when stopped, but not for CPU/RAM.
  echo ">> Stopping Cloud SQL instance $SQL_INSTANCE..."
  gcloud sql instances patch $SQL_INSTANCE --activation-policy NEVER --project $PROJECT_ID --quiet
  
  echo "✅ All services stopped/paused."
}

function start_all() {
  echo "🚀 Starting all services..."

  # 1. Start Cloud SQL first (needs time)
  echo ">> Starting Cloud SQL instance $SQL_INSTANCE..."
  gcloud sql instances patch $SQL_INSTANCE --activation-policy ALWAYS --project $PROJECT_ID --quiet
  echo "   (Cloud SQL is starting...)"

  # 2. Restore Cloud Run scaling
  echo ">> Restoring Cloud Run services..."
  
  # Staging: min=0, max=3
  for service in "${SERVICES_STAGING[@]}"; do
    echo "   - Restoring Staging: $service (min=0, max=3)"
    gcloud run services update $service --region $REGION --min-instances 0 --max-instances 3 --project $PROJECT_ID --quiet
  done

  # Production: min=1, max=10 (Ensure hot standby)
  for service in "${SERVICES_PROD[@]}"; do
    echo "   - Restoring Production: $service (min=1, max=10)"
    gcloud run services update $service --region $REGION --min-instances 1 --max-instances 10 --project $PROJECT_ID --quiet
  done

  echo "✅ All services restored."
}

# Firebase Hosting
# Hosting is static and cheap, no need to stop usually. 
# If needed, can use `firebase hosting:disable` but that removes the site.

if [ "$1" == "stop" ]; then
  stop_all
elif [ "$1" == "start" ]; then
  start_all
else
  echo "Usage: ./gcp-ops.sh [start|stop]"
  echo "  stop  : Scale down Cloud Run (min=0) and stop Cloud SQL."
  echo "  start : Start Cloud SQL and restore Cloud Run scaling (Prod min=1)."
fi
