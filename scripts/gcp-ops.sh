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

function stop_run() {
  echo "🛑 Stopping Cloud Run services..."
  all_services=("${SERVICES_STAGING[@]}" "${SERVICES_PROD[@]}")
  for service in "${all_services[@]}"; do
    echo "   - Scaling down $service..."
    gcloud run services update $service --region $REGION --min-instances 0 --max-instances 1 --project $PROJECT_ID --quiet
  done
  echo "   (Note: Services scaled to min=0. They will still respond to requests but with cold start.)"
  echo "✅ Cloud Run services stopped."
}

function stop_sql() {
  echo "🛑 Stopping Cloud SQL instance $SQL_INSTANCE..."
  gcloud sql instances patch $SQL_INSTANCE --activation-policy NEVER --project $PROJECT_ID --quiet
  echo "✅ Cloud SQL stopped."
}

function stop_all() {
  echo "� Stopping all services to save cost..."
  stop_run
  stop_sql
  echo "✅ All services stopped/paused."
}

function start_run() {
  echo "🚀 Starting Cloud Run services..."
  
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

  echo "✅ Cloud Run services restored."
}

function start_sql() {
  echo "🚀 Starting Cloud SQL instance $SQL_INSTANCE..."
  gcloud sql instances patch $SQL_INSTANCE --activation-policy ALWAYS --project $PROJECT_ID --quiet
  echo "✅ Cloud SQL started. (May take 1-2 minutes to be fully ready)"
}

function start_all() {
  echo "🚀 Starting all services..."
  start_sql
  start_run
  echo "✅ All services restored."
}

# Firebase Hosting
# Hosting is static and cheap, no need to stop usually. 
# If needed, can use `firebase hosting:disable` but that removes the site.

case "$1" in
  stop)
    stop_all
    ;;
  stop-run)
    stop_run
    ;;
  stop-sql)
    stop_sql
    ;;
  start)
    start_all
    ;;
  start-run)
    start_run
    ;;
  start-sql)
    start_sql
    ;;
  *)
    echo "Usage: ./gcp-ops.sh [command]"
    echo ""
    echo "Commands:"
    echo "  stop      : Stop all (Cloud Run + Cloud SQL)"
    echo "  stop-run  : Stop Cloud Run only (scale to min=0)"
    echo "  stop-sql  : Stop Cloud SQL only"
    echo "  start     : Start all (Cloud SQL + Cloud Run)"
    echo "  start-run : Start Cloud Run only (restore scaling)"
    echo "  start-sql : Start Cloud SQL only"
    ;;
esac
