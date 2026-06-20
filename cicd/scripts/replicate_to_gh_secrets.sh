#!/usr/bin/env bash

## usage: source cicd/sec/sandbox_secrets.sh && cicd/scripts/replicate_to_gh_secrets.sh
## Replicate the following env vars to github repo secrets prefixed with
## "SANDBOX_", after first checking all are non empty and exit 1 if any are,
## listing empty required.
##   - AWS_ACCESS_KEY_ID
##   - AWS_SECRET_ACCESS_KEY
##   - AZURE_TENANT_ID
##   - AZURE_CLIENT_ID
##   - AZURE_CLIENT_SECRET
##   - AZURE_SUBSCRIPTION_ID
##   - GOOGLE_CREDENTIALS
##
## Overrides:
##   GH_SECRETS_REPO   target repo as OWNER/NAME (default: stackql-labs/stackql-actions-sandbox)

set -euo pipefail

REPO="${GH_SECRETS_REPO:-stackql-labs/stackql-actions-sandbox}"

required=(
  AWS_ACCESS_KEY_ID
  AWS_SECRET_ACCESS_KEY
  AZURE_TENANT_ID
  AZURE_CLIENT_ID
  AZURE_CLIENT_SECRET
  AZURE_SUBSCRIPTION_ID
  GOOGLE_CREDENTIALS
)

missing=()
for var in "${required[@]}"; do
  if [ -z "${!var:-}" ]; then
    missing+=("$var")
  fi
done

if [ "${#missing[@]}" -gt 0 ]; then
  echo "error: required env vars are empty or unset:" >&2
  printf '  - %s\n' "${missing[@]}" >&2
  echo >&2
  echo "hint: source cicd/sec/sandbox_secrets.sh before running this script." >&2
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "error: gh CLI not found in PATH." >&2
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "error: gh is not authenticated. Run 'gh auth login' first." >&2
  exit 1
fi

echo "replicating ${#required[@]} secret(s) to repo '${REPO}' with prefix 'SANDBOX_'"

for var in "${required[@]}"; do
  target="SANDBOX_${var}"
  printf '  → %s\n' "$target"
  printf '%s' "${!var}" | gh secret set "$target" --repo "$REPO" --body -
done

echo "done."
