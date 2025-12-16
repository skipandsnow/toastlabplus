#!/bin/bash
# Toastlabplus - Workload Identity Federation 設定腳本
# 用於設定 GitHub Actions ↔ GCP 無 Key 驗證
#
# 使用前請：
# 1. 確認已登入 gcloud: gcloud auth login
# 2. 修改下方變數為你的 GitHub repo 資訊

set -e

# ============================================
# 配置區 - 請修改這些變數
# ============================================
PROJECT_ID="toastlabplus"
PROJECT_NUMBER="96030530148"
GITHUB_ORG="skipandsnow"        # ⚠️ 改成你的 GitHub 組織或用戶名稱
GITHUB_REPO="toastlabplus"          # ⚠️ 改成你的 repo 名稱
REGION="asia-east1"

# Workload Identity 資源名稱
POOL_NAME="github-pool"
PROVIDER_NAME="github-provider"
SERVICE_ACCOUNT_NAME="github-actions"

# ============================================
# 開始設定
# ============================================
echo "=== Workload Identity Federation 設定 ==="
echo "Project: $PROJECT_ID"
echo "GitHub: $GITHUB_ORG/$GITHUB_REPO"
echo ""

# 設定專案
gcloud config set project $PROJECT_ID

# 啟用必要 API
echo "📦 啟用 IAM Credentials API..."
gcloud services enable iamcredentials.googleapis.com

# ============================================
# 1. 建立 Workload Identity Pool
# ============================================
echo ""
echo "🔐 建立 Workload Identity Pool..."
gcloud iam workload-identity-pools create "$POOL_NAME" \
  --location="global" \
  --display-name="GitHub Actions Pool" \
  --description="Pool for GitHub Actions OIDC authentication" \
  2>/dev/null || echo "   Pool 已存在，跳過"

POOL_ID=$(gcloud iam workload-identity-pools describe "$POOL_NAME" \
  --location="global" \
  --format="value(name)")

echo "   Pool ID: $POOL_ID"

# ============================================
# 2. 建立 OIDC Provider (信任 GitHub)
# ============================================
echo ""
echo "🔗 建立 OIDC Provider..."
gcloud iam workload-identity-pools providers create-oidc "$PROVIDER_NAME" \
  --location="global" \
  --workload-identity-pool="$POOL_NAME" \
  --display-name="GitHub Provider" \
  --issuer-uri="https://token.actions.githubusercontent.com" \
  --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository,attribute.actor=assertion.actor,attribute.ref=assertion.ref" \
  --attribute-condition="assertion.repository=='$GITHUB_ORG/$GITHUB_REPO'" \
  2>/dev/null || echo "   Provider 已存在，跳過"

echo "   Provider: $PROVIDER_NAME"

# ============================================
# 3. 建立 Service Account
# ============================================
echo ""
echo "👤 建立 Service Account..."
gcloud iam service-accounts create "$SERVICE_ACCOUNT_NAME" \
  --display-name="GitHub Actions Service Account" \
  --description="Used by GitHub Actions for CI/CD" \
  2>/dev/null || echo "   Service Account 已存在，跳過"

SA_EMAIL="${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
echo "   Service Account: $SA_EMAIL"

# ============================================
# 4. 賦予 Service Account 必要權限
# ============================================
echo ""
echo "🔑 設定 IAM 權限..."

# Cloud Run Admin
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/run.admin" \
  --quiet

# Artifact Registry Writer
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/artifactregistry.writer" \
  --quiet

# Service Account User (for Cloud Run)
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/iam.serviceAccountUser" \
  --quiet

# Secret Manager Accessor
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/secretmanager.secretAccessor" \
  --quiet

echo "   ✅ 已賦予 Cloud Run, Artifact Registry, Secret Manager 權限"

# ============================================
# 5. 綁定 Workload Identity → Service Account
# ============================================
echo ""
echo "🔗 綁定 Workload Identity..."

MEMBER="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_NAME}/attribute.repository/${GITHUB_ORG}/${GITHUB_REPO}"

gcloud iam service-accounts add-iam-policy-binding "$SA_EMAIL" \
  --role="roles/iam.workloadIdentityUser" \
  --member="$MEMBER" \
  --quiet

echo "   ✅ 已綁定 $GITHUB_ORG/$GITHUB_REPO"

# ============================================
# 輸出 GitHub Actions 設定
# ============================================
PROVIDER_FULL="projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_NAME}/providers/${PROVIDER_NAME}"

echo ""
echo "============================================"
echo "✅ Workload Identity 設定完成！"
echo "============================================"
echo ""
echo "📋 請在 GitHub Actions workflow 加入以下設定："
echo ""
echo "---"
echo "permissions:"
echo "  contents: read"
echo "  id-token: write"
echo ""
echo "steps:"
echo "  - uses: google-github-actions/auth@v2"
echo "    with:"
echo "      workload_identity_provider: '$PROVIDER_FULL'"
echo "      service_account: '$SA_EMAIL'"
echo "---"
echo ""
echo "🔧 Provider:        $PROVIDER_FULL"
echo "🔧 Service Account: $SA_EMAIL"
