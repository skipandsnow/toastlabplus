#!/bin/bash
# Toastlabplus GCP Setup Script
# 執行前請確認已登入 gcloud: gcloud auth login

set -e

PROJECT_ID="toastlabplus"
REGION="asia-east1"
DB_INSTANCE="toastlabplus-db"
REPO_NAME="toastlabplus-repo"

echo "=== Toastlabplus GCP Setup ==="

# 設定專案
gcloud config set project $PROJECT_ID
echo "✅ 專案設定為: $PROJECT_ID"

# 啟用必要 API
echo "啟用 GCP API..."
gcloud services enable \
  run.googleapis.com \
  sqladmin.googleapis.com \
  secretmanager.googleapis.com \
  artifactregistry.googleapis.com \
  vpcaccess.googleapis.com \
  cloudbuild.googleapis.com

echo "✅ API 已啟用"

# 建立 Artifact Registry
echo "建立 Artifact Registry..."
gcloud artifacts repositories create $REPO_NAME \
  --repository-format=docker \
  --location=$REGION \
  --description="Toastlabplus container images" \
  2>/dev/null || echo "Repository 已存在"

echo "✅ Artifact Registry: $REPO_NAME"

# 建立 Cloud SQL (PostgreSQL)
echo "建立 Cloud SQL..."
gcloud sql instances create $DB_INSTANCE \
  --database-version=POSTGRES_15 \
  --tier=db-f1-micro \
  --region=$REGION \
  --root-password="CHANGE_ME_BEFORE_PRODUCTION" \
  --storage-type=SSD \
  --storage-size=10GB \
  --no-assign-ip \
  --network=default \
  2>/dev/null || echo "Cloud SQL 已存在"

echo "✅ Cloud SQL: $DB_INSTANCE"

# 建立資料庫
gcloud sql databases create toastlabplus \
  --instance=$DB_INSTANCE \
  2>/dev/null || echo "Database 已存在"

echo "✅ Database: toastlabplus"

# 建立 VPC Connector
echo "建立 VPC Connector..."
gcloud compute networks vpc-access connectors create serverless-connector \
  --region=$REGION \
  --range=10.8.0.0/28 \
  2>/dev/null || echo "VPC Connector 已存在"

echo "✅ VPC Connector: serverless-connector"

echo ""
echo "=== GCP Setup 完成 ==="
echo "下一步:"
echo "1. 更新 Cloud SQL root 密碼"
echo "2. 取得 Gemini API Key 並存入 Secret Manager"
echo "3. 部署服務至 Cloud Run"
