#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-oidc}"
REQUESTED_TARGETS="${REQUESTED_TARGETS:-finops-aws finops-gcp finops-azure}"
PROVIDER_ROWS=""

write_output() {
  local key="$1" value="$2"
  if [ -n "${GITHUB_OUTPUT:-}" ]; then
    printf '%s=%s\n' "$key" "$value" >> "$GITHUB_OUTPUT"
  else
    printf '%s=%s\n' "$key" "$value"
  fi
}

join_by() {
  local delim="$1"
  shift || true
  local first=1
  local out=""
  local item
  for item in "$@"; do
    if [ "$first" -eq 1 ]; then
      out="$item"
      first=0
    else
      out="${out}${delim}${item}"
    fi
  done
  printf '%s' "$out"
}

has_target() {
  local needle="$1"
  case " ${REQUESTED_TARGETS} " in
    *" ${needle} "*) return 0 ;;
    *) return 1 ;;
  esac
}

is_missing() {
  local var="$1"
  [ -z "${!var:-}" ]
}

check_provider() {
  local provider="$1"
  shift
  local required=("$@")
  local missing=()
  local var
  for var in "${required[@]}"; do
    if is_missing "$var"; then
      missing+=("$var")
    fi
  done

  local requested="false"
  if has_target "finops-${provider}"; then
    requested="true"
  fi

  local enabled="false"
  if [ "$requested" = "true" ] && [ "${#missing[@]}" -eq 0 ]; then
    enabled="true"
  fi

  local missing_csv required_csv
  missing_csv="$(join_by ',' "${missing[@]:-}")"
  required_csv="$(join_by ',' "${required[@]}")"

  printf -v "${provider}_enabled_local" '%s' "$enabled"

  write_output "${provider}_requested" "$requested"
  write_output "${provider}_enabled" "$enabled"
  write_output "${provider}_missing" "$missing_csv"
  write_output "${provider}_restore" "$required_csv"

  PROVIDER_ROWS+="| ${provider} | ${requested} | ${enabled} | ${missing_csv:-none} | ${required_csv} |\n"

  if [ "$requested" = "true" ] && [ "$enabled" != "true" ]; then
    echo "::warning title=Provider skipped::${provider} skipped: missing ${missing_csv}. To restore, set: ${required_csv}"
  fi
}

case "$MODE" in
  oidc)
    check_provider aws STACKQL_ID_FED_AWS_ROLE_ARN
    check_provider gcp STACKQL_ID_FED_GCP_WORKLOAD_IDENTITY_PROVIDER STACKQL_ID_FED_GCP_SERVICE_ACCOUNT
    check_provider azure STACKQL_ID_FED_AZURE_TENANT_ID STACKQL_ID_FED_AZURE_CLIENT_ID AZURE_SUB_ID
    ;;
  oidc-mutate)
    check_provider aws STACKQL_ID_FED_AWS_MUTATE_ROLE_ARN
    check_provider gcp STACKQL_ID_FED_GCP_WORKLOAD_IDENTITY_PROVIDER STACKQL_ID_FED_GCP_MUTATE_SERVICE_ACCOUNT
    check_provider azure STACKQL_ID_FED_AZURE_TENANT_ID STACKQL_ID_FED_AZURE_MUTATE_CLIENT_ID AZURE_SUB_ID
    ;;
  sandbox)
    check_provider aws SANDBOX_AWS_ACCESS_KEY_ID SANDBOX_AWS_SECRET_ACCESS_KEY
    check_provider gcp SANDBOX_GOOGLE_CREDENTIALS
    check_provider azure SANDBOX_AZURE_TENANT_ID SANDBOX_AZURE_CLIENT_ID SANDBOX_AZURE_CLIENT_SECRET SANDBOX_AZURE_SUBSCRIPTION_ID
    ;;
  *)
    echo "error: unsupported mode '$MODE' (use 'oidc', 'oidc-mutate', or 'sandbox')" >&2
    exit 1
    ;;
esac

# Build effective target list by dropping requested providers that are disabled.
effective_targets=()
for token in $REQUESTED_TARGETS; do
  case "$token" in
    finops-aws)
      if [ "${aws_enabled_local:-false}" = "true" ]; then effective_targets+=("$token"); fi
      ;;
    finops-gcp)
      if [ "${gcp_enabled_local:-false}" = "true" ]; then effective_targets+=("$token"); fi
      ;;
    finops-azure)
      if [ "${azure_enabled_local:-false}" = "true" ]; then effective_targets+=("$token"); fi
      ;;
    *)
      effective_targets+=("$token")
      ;;
  esac
done

effective_joined="$(join_by ' ' "${effective_targets[@]:-}")"
if [ -n "$effective_joined" ]; then
  write_output has_effective_targets true
else
  write_output has_effective_targets false
  echo "::warning title=All requested providers skipped::No runnable providers remain after prerequisite checks."
fi
write_output effective_targets "$effective_joined"

if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  {
    echo "## Provider Prerequisite Check (${MODE})"
    echo
    echo "Requested targets: ${REQUESTED_TARGETS}"
    echo
    echo "Effective targets: ${effective_joined:-none}"
    echo
    echo "| provider | requested | enabled | missing | restore by setting |"
    echo "| --- | --- | --- | --- | --- |"
    printf '%b' "$PROVIDER_ROWS"
  } >> "$GITHUB_STEP_SUMMARY"
fi
