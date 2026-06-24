#!/usr/bin/env bash
# StackQL audit — read-only OIDC bootstrap for GCP.
# Run from Cloud Shell (or any gcloud-authed shell) as a project owner.
# Creates a Workload Identity Pool + Provider trusted by GitHub Actions, plus
# a Service Account with read-only project access. No keys leave the shell.
#
# Usage:
#   PROJECT_ID=my-proj REPO=owner/repo bash setup.sh
# or just run it and you'll be prompted.

set -euo pipefail

PROJECT_ID="${PROJECT_ID:-${DEVSHELL_PROJECT_ID:-}}"
REPO="${REPO:-}"
POOL_ID="${POOL_ID:-github-actions}"
PROVIDER_ID="${PROVIDER_ID:-github}"
SA_NAME="${SA_NAME:-stackql-audit-sa}"

if [ -z "$PROJECT_ID" ]; then
  read -rp "GCP project ID: " PROJECT_ID
fi
if [ -z "$REPO" ]; then
  read -rp "GitHub repo (owner/repo): " REPO
fi

echo "→ project=$PROJECT_ID  repo=$REPO  pool=$POOL_ID  provider=$PROVIDER_ID  sa=$SA_NAME"
gcloud config set project "$PROJECT_ID" >/dev/null

# Required APIs (idempotent).
gcloud services enable \
  iam.googleapis.com \
  iamcredentials.googleapis.com \
  sts.googleapis.com \
  cloudresourcemanager.googleapis.com \
  --quiet

PROJECT_NUMBER="$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')"

# --- workload identity pool ------------------------------------------------
if ! gcloud iam workload-identity-pools describe "$POOL_ID" --location=global --quiet >/dev/null 2>&1; then
  gcloud iam workload-identity-pools create "$POOL_ID" \
    --location=global \
    --display-name="GitHub Actions" \
    --quiet
fi

# --- OIDC provider on the pool --------------------------------------------
# attribute-condition restricts assumption to this specific repo. Tighten the
# expression (e.g. assertion.ref == 'refs/heads/main') if you want to limit
# further.
if ! gcloud iam workload-identity-pools providers describe "$PROVIDER_ID" \
      --workload-identity-pool="$POOL_ID" --location=global --quiet >/dev/null 2>&1; then
  gcloud iam workload-identity-pools providers create-oidc "$PROVIDER_ID" \
    --workload-identity-pool="$POOL_ID" \
    --location=global \
    --issuer-uri="https://token.actions.githubusercontent.com" \
    --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository,attribute.ref=assertion.ref" \
    --attribute-condition="attribute.repository=='${REPO}'" \
    --quiet
fi

# --- service account -------------------------------------------------------
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
if ! gcloud iam service-accounts describe "$SA_EMAIL" --quiet >/dev/null 2>&1; then
  gcloud iam service-accounts create "$SA_NAME" \
    --display-name="StackQL audit (read-only)" \
    --quiet
fi

# Read-only project roles (SecurityAudit equivalent for GCP).
for role in roles/viewer roles/iam.securityReviewer; do
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="$role" \
    --condition=None \
    --quiet >/dev/null
done

# Allow the WIF principalSet (this repo) to impersonate the SA.
PRINCIPAL_SET="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_ID}/attribute.repository/${REPO}"
gcloud iam service-accounts add-iam-policy-binding "$SA_EMAIL" \
  --role="roles/iam.workloadIdentityUser" \
  --member="$PRINCIPAL_SET" \
  --quiet >/dev/null

WIF_PROVIDER="projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_ID}/providers/${PROVIDER_ID}"

cat <<EOF

✓ Done. Paste these into your GitHub repo (Settings → Secrets and variables → Actions → Variables):

  STACKQL_GCP_WIF_PROVIDER  =  ${WIF_PROVIDER}
  STACKQL_GCP_SA_EMAIL      =  ${SA_EMAIL}

or via gh CLI:
  gh variable set STACKQL_GCP_WIF_PROVIDER --body '${WIF_PROVIDER}'
  gh variable set STACKQL_GCP_SA_EMAIL     --body '${SA_EMAIL}'
EOF
