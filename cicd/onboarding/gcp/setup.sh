#!/usr/bin/env bash
# StackQL audit — OIDC bootstrap for GCP, org-wide.
# Creates a Workload Identity Pool + Provider in PROJECT_ID, plus two service
# accounts (audit read-only, mutate read+write) bound at ORG scope. WIF trust:
#   - audit  → any event from REPO
#   - mutate → only main-branch context from REPO
# No keys leave the shell.
#
# Run from Cloud Shell (or any gcloud-authed shell) as Organization Admin.
#
# Usage:
#   PROJECT_ID=my-proj REPO=owner/repo bash setup.sh
#   ORG_ID=123456 PROJECT_ID=my-proj REPO=owner/repo bash setup.sh   # if auto-detect fails

set -euo pipefail

PROJECT_ID="${PROJECT_ID:-${DEVSHELL_PROJECT_ID:-$(gcloud config get-value project 2>/dev/null)}}"
REPO="${REPO:-}"
ORG_ID="${ORG_ID:-}"
POOL_ID="${POOL_ID:-github-actions}"
PROVIDER_ID="${PROVIDER_ID:-github}"
AUDIT_SA_NAME="${AUDIT_SA_NAME:-stackql-audit-sa}"
MUTATE_SA_NAME="${MUTATE_SA_NAME:-stackql-mutate-sa}"

# --- input validation ------------------------------------------------------
if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "(unset)" ]; then
  echo "error: no GCP project. Set one with:  gcloud config set project <id>" >&2
  echo "       or pass inline:  PROJECT_ID=<id> REPO=owner/repo bash /tmp/s.sh" >&2
  exit 1
fi
if [ -z "$REPO" ]; then
  echo "error: REPO not set. Pass inline:  PROJECT_ID=$PROJECT_ID REPO=owner/repo bash /tmp/s.sh" >&2
  exit 1
fi

ACTIVE_ACCOUNT="$(gcloud config get-value account 2>/dev/null)"
if ! gcloud projects describe "$PROJECT_ID" >/dev/null 2>&1; then
  echo "error: account '$ACTIVE_ACCOUNT' cannot access project '$PROJECT_ID'." >&2
  echo "       Fix:  gcloud auth login  then re-run." >&2
  exit 1
fi
gcloud config set project "$PROJECT_ID" >/dev/null

# --- org id ----------------------------------------------------------------
if [ -z "$ORG_ID" ]; then
  ORG_ID="$(gcloud projects get-ancestors "$PROJECT_ID" --format='value(id)' 2>/dev/null \
             | tail -n 1)"
fi
if [ -z "$ORG_ID" ]; then
  echo "error: could not auto-detect ORG_ID for project '$PROJECT_ID'." >&2
  echo "       List orgs:  gcloud organizations list" >&2
  echo "       Then re-run: ORG_ID=<id> PROJECT_ID=$PROJECT_ID REPO=$REPO bash /tmp/s.sh" >&2
  exit 1
fi
if ! gcloud organizations describe "$ORG_ID" >/dev/null 2>&1; then
  echo "error: account '$ACTIVE_ACCOUNT' cannot describe org '$ORG_ID'." >&2
  echo "       You need Organization Admin to grant org-wide IAM bindings." >&2
  exit 1
fi

PROJECT_NUMBER="$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')"
echo "→ project=$PROJECT_ID  project_number=$PROJECT_NUMBER  org=$ORG_ID  account=$ACTIVE_ACCOUNT  repo=$REPO"

# --- required APIs ---------------------------------------------------------
gcloud services enable \
  iam.googleapis.com \
  iamcredentials.googleapis.com \
  sts.googleapis.com \
  cloudresourcemanager.googleapis.com \
  --quiet

# --- workload identity pool ------------------------------------------------
if ! gcloud iam workload-identity-pools describe "$POOL_ID" --location=global --quiet >/dev/null 2>&1; then
  gcloud iam workload-identity-pools create "$POOL_ID" \
    --location=global --display-name="GitHub Actions" --quiet
fi

# --- OIDC provider on the pool (repo-scoped) -------------------------------
if ! gcloud iam workload-identity-pools providers describe "$PROVIDER_ID" \
      --workload-identity-pool="$POOL_ID" --location=global --quiet >/dev/null 2>&1; then
  gcloud iam workload-identity-pools providers create-oidc "$PROVIDER_ID" \
    --workload-identity-pool="$POOL_ID" --location=global \
    --issuer-uri="https://token.actions.githubusercontent.com" \
    --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository,attribute.ref=assertion.ref" \
    --attribute-condition="attribute.repository=='${REPO}'" \
    --quiet
fi

WIF_PROVIDER="projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_ID}/providers/${PROVIDER_ID}"
PRINCIPAL_REPO="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_ID}/attribute.repository/${REPO}"
PRINCIPAL_MAIN="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_ID}/attribute.ref/refs/heads/main"

ensure_sa() {
  local name="$1" desc="$2"
  local email="${name}@${PROJECT_ID}.iam.gserviceaccount.com"
  if ! gcloud iam service-accounts describe "$email" --quiet >/dev/null 2>&1; then
    gcloud iam service-accounts create "$name" --display-name="$desc" --quiet
  fi
  echo "$email"
}

bind_org_role() {
  local sa="$1" role="$2"
  gcloud organizations add-iam-policy-binding "$ORG_ID" \
    --member="serviceAccount:${sa}" --role="$role" --condition=None --quiet >/dev/null
}

bind_wif() {
  local sa="$1" principal="$2"
  gcloud iam service-accounts add-iam-policy-binding "$sa" \
    --role="roles/iam.workloadIdentityUser" --member="$principal" --quiet >/dev/null
}

# --- audit SA (read-only, all repo events) ---------------------------------
AUDIT_SA="$(ensure_sa "$AUDIT_SA_NAME" "StackQL audit (read-only, org-wide)")"
bind_org_role "$AUDIT_SA" "roles/viewer"
bind_org_role "$AUDIT_SA" "roles/iam.securityReviewer"
bind_wif      "$AUDIT_SA" "$PRINCIPAL_REPO"

# --- mutate SA (read + delete on finops targets, main-branch only) ---------
MUTATE_SA="$(ensure_sa "$MUTATE_SA_NAME" "StackQL mutate (org-wide; main-only trust)")"
bind_org_role "$MUTATE_SA" "roles/viewer"
bind_org_role "$MUTATE_SA" "roles/iam.securityReviewer"
bind_org_role "$MUTATE_SA" "roles/compute.instanceAdmin.v1"   # GCE delete (zero-vms, disks)
bind_org_role "$MUTATE_SA" "roles/compute.networkAdmin"       # GCE addresses delete
bind_wif      "$MUTATE_SA" "$PRINCIPAL_MAIN"

cat <<EOF

✓ Done. Paste these into your GitHub repo (Settings → Secrets and variables → Actions → Variables):

  STACKQL_ID_FED_GCP_WORKLOAD_IDENTITY_PROVIDER  =  ${WIF_PROVIDER}
  STACKQL_ID_FED_GCP_SERVICE_ACCOUNT             =  ${AUDIT_SA}
  STACKQL_ID_FED_GCP_MUTATE_SERVICE_ACCOUNT      =  ${MUTATE_SA}

or via gh CLI:
  gh variable set STACKQL_ID_FED_GCP_WORKLOAD_IDENTITY_PROVIDER --body '${WIF_PROVIDER}'
  gh variable set STACKQL_ID_FED_GCP_SERVICE_ACCOUNT            --body '${AUDIT_SA}'
  gh variable set STACKQL_ID_FED_GCP_MUTATE_SERVICE_ACCOUNT     --body '${MUTATE_SA}'
EOF
