#!/usr/bin/env bash
# StackQL audit — OIDC bootstrap for Azure.
# Creates two App Registrations + federated credentials trusted by GitHub
# Actions: 'audit' (read-only, federated for main + pull_request) and
# 'mutate' (read+write, federated for main only). Role assignments default
# to the current subscription; set MGMT_GROUP_ID for org-wide coverage.
# No client secrets.
#
# Run from Azure Cloud Shell as a tenant user with permission to:
#   - register applications (Application Developer or higher)
#   - assign roles at the chosen scope (Owner or User Access Administrator)
#
# Usage:
#   REPO=owner/repo bash setup.sh
#   REPO=owner/repo MGMT_GROUP_ID=<mg-id> bash setup.sh     # org-wide

set -euo pipefail

REPO="${REPO:-}"
MGMT_GROUP_ID="${MGMT_GROUP_ID:-}"
AUDIT_APP_NAME="${AUDIT_APP_NAME:-stackql-audit-oidc}"
MUTATE_APP_NAME="${MUTATE_APP_NAME:-stackql-mutate-oidc}"

if [ -z "$REPO" ]; then
  echo "error: REPO not set. Run:  REPO=owner/repo bash /tmp/s.sh" >&2
  exit 1
fi

TENANT_ID="$(az account show --query tenantId -o tsv)"
SUBSCRIPTION_ID="$(az account show --query id -o tsv)"
ACTIVE_ACCOUNT="$(az account show --query user.name -o tsv)"

if [ -n "$MGMT_GROUP_ID" ]; then
  SCOPE="/providers/Microsoft.Management/managementGroups/${MGMT_GROUP_ID}"
  echo "→ scope=management-group/${MGMT_GROUP_ID}  tenant=${TENANT_ID}  account=${ACTIVE_ACCOUNT}  repo=${REPO}"
else
  SCOPE="/subscriptions/${SUBSCRIPTION_ID}"
  echo "→ scope=subscription/${SUBSCRIPTION_ID}  tenant=${TENANT_ID}  account=${ACTIVE_ACCOUNT}  repo=${REPO}"
  echo "  (set MGMT_GROUP_ID=<id> for org-wide coverage)"
fi

ensure_app() {
  local name="$1"
  local app_id
  app_id="$(az ad app list --display-name "$name" --query '[0].appId' -o tsv 2>/dev/null)"
  if [ -z "$app_id" ]; then
    app_id="$(az ad app create --display-name "$name" --query appId -o tsv)"
  fi
  # Ensure a service principal exists for the app (so roles can be assigned).
  if ! az ad sp show --id "$app_id" >/dev/null 2>&1; then
    az ad sp create --id "$app_id" >/dev/null
  fi
  echo "$app_id"
}

add_fic() {
  local app_id="$1" name="$2" subject="$3"
  if az ad app federated-credential list --id "$app_id" --query "[?name=='${name}']" -o tsv 2>/dev/null | grep -q .; then
    return 0
  fi
  az ad app federated-credential create --id "$app_id" --parameters "$(jq -nc \
    --arg name "$name" --arg subject "$subject" \
    '{name:$name, issuer:"https://token.actions.githubusercontent.com", subject:$subject, audiences:["api://AzureADTokenExchange"]}')" >/dev/null
}

assign_role() {
  local app_id="$1" role="$2"
  local sp_id
  sp_id="$(az ad sp show --id "$app_id" --query id -o tsv)"
  az role assignment create --assignee-object-id "$sp_id" \
    --assignee-principal-type ServicePrincipal \
    --role "$role" --scope "$SCOPE" --only-show-errors >/dev/null || true
}

# --- audit app (read-only, federated for main + pull_request) -------------
AUDIT_APP_ID="$(ensure_app "$AUDIT_APP_NAME")"
add_fic "$AUDIT_APP_ID" "github-main"  "repo:${REPO}:ref:refs/heads/main"
add_fic "$AUDIT_APP_ID" "github-pr"    "repo:${REPO}:pull_request"
assign_role "$AUDIT_APP_ID" "Reader"
assign_role "$AUDIT_APP_ID" "Security Reader"

# --- mutate app (read + delete, federated for main only) ------------------
MUTATE_APP_ID="$(ensure_app "$MUTATE_APP_NAME")"
add_fic "$MUTATE_APP_ID" "github-main" "repo:${REPO}:ref:refs/heads/main"
assign_role "$MUTATE_APP_ID" "Reader"
assign_role "$MUTATE_APP_ID" "Security Reader"
assign_role "$MUTATE_APP_ID" "Virtual Machine Contributor"
assign_role "$MUTATE_APP_ID" "Network Contributor"

cat <<EOF

✓ Done. Paste these into your GitHub repo (Settings → Secrets and variables → Actions → Variables):

  STACKQL_ID_FED_AZURE_TENANT_ID          =  ${TENANT_ID}
  AZURE_SUB_ID                            =  ${SUBSCRIPTION_ID}
  STACKQL_ID_FED_AZURE_CLIENT_ID          =  ${AUDIT_APP_ID}
  STACKQL_ID_FED_AZURE_MUTATE_CLIENT_ID   =  ${MUTATE_APP_ID}

or via gh CLI:
  gh variable set STACKQL_ID_FED_AZURE_TENANT_ID        --body '${TENANT_ID}'
  gh variable set AZURE_SUB_ID                          --body '${SUBSCRIPTION_ID}'
  gh variable set STACKQL_ID_FED_AZURE_CLIENT_ID        --body '${AUDIT_APP_ID}'
  gh variable set STACKQL_ID_FED_AZURE_MUTATE_CLIENT_ID --body '${MUTATE_APP_ID}'
EOF
