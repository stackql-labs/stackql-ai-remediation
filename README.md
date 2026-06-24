# stackql-ai-remediation

Close cloud findings the same way you ship code: one pull request per finding, a live-state check before anything mutates, applied on merge. The loop runs entirely in GitHub Actions, authenticates with OIDC, and uses [StackQL](https://stackql.io) to read and act on cloud control planes. The example checks here are FinOps waste (unattached disks, idle IPs, zero-VM projects), but the shape is the same for security posture and access.

There are no agents running in your estate, no long-lived cloud keys, and no external scanner. The data path is GitHub Actions -> StackQL -> cloud control-plane APIs, and the audit trail is the pull request history.

## What it does

1. A scheduled or dispatched audit runs against the cloud control plane and writes findings as structured data.
2. For each finding, the loop opens one pull request carrying the exact proposed change.
3. A preflight status check queries live reality before the PR can merge.
4. On merge, the change is applied through the vendor CLI.
5. A post-apply check confirms the resource is actually gone.

## How it works

The audit emits findings as JSON. A deterministic generator turns each finding into a proposal directory and opens a PR. The mutation is gated by a required preflight check, not by a human sign-off, so safety is a machine-enforced property rather than a review bottleneck. There is no LLM in the SQL path: the remediation comes from the audit's own per-check `suggested_remediation` block, already substituted with concrete values, so every proposal is reproducible and reviewable.

A model is used in one optional, separate step: an agent reads the batch and flags the captain's-call risks so reviewers know where to look. Judgment and mutation are kept apart on purpose.

## Repo layout

```
.github/workflows/
  oidc-audit-workflow-finops.yml            # audit only
  agent-remediation-oidc-audit-workflow-finops.yml  # audit -> proposals -> PRs
  pr-preflight-finops.yml                   # required preflight check on each PR
  pr-merge-apply-finops.yml                 # apply on merge + post-check
cicd/
  onboarding/aws/template.yaml              # CloudFormation: OIDC role
  onboarding/gcp/setup.sh                   # gcloud: workload identity federation
  onboarding/azure/template.json            # ARM: federated credential
  scripts/generate_proposals.py             # deterministic proposal generator
remediations/proposed/<run-id>/<finding>/   # generated proposals (one dir per finding)
```

## Anatomy of a proposal

`generate_proposals.py` writes one directory per finding:

```
remediations/proposed/<run-id>/<n>-<check-id>-<resource-id>/
  finding.json      # verbatim copy of the finding
  preflight.sql     # live-state check, pass = >=1 row
  remediation.sql   # canonical fix, applied via CLI on merge
  rationale.md      # deterministic explanation from the finding fields
```

The preflight is the part that matters most. It is a live query against the cloud API, run as a required status check on the PR:

```sql
-- pass criterion: returns >= 1 row
SELECT volumeId
FROM aws.ec2_native.volumes
WHERE region = 'ap-southeast-2'
  AND volumeId = 'vol-0a1b2c3d4e5f'
  AND status = 'available';
```

It asserts that the resource is still in the state the finding assumed at the moment of merge, not at the moment of audit. Findings go stale between the audit run and someone clicking merge; a state file would not know, the API does. If the preflight returns zero rows, the check fails and nothing lands.

The fix is a SQL statement against the control plane, idempotent by shape:

```sql
DELETE FROM aws.ec2.volumes
WHERE region = 'ap-southeast-2'
  AND VolumeId = 'vol-0a1b2c3d4e5f';
```

## Prerequisites

- A GitHub repository with Actions enabled.
- At least one cloud account (AWS, GCP, or Azure) you can grant a read-and-act role in.
- Permission to set branch protection on `main`.

## Setup

### 1. Branch protection

The remediation flow opens one PR per finding under `github-actions`. The preflight check must be allowed to run, and merge is gated on that check rather than on a manual approver.

Under **Settings -> Branches -> rule for `main`**:

- **Required approvals:** `0`
- **Require status checks to pass before merging:** on (so the preflight is enforced)

Without this, every auto-raised remediation PR sits blocked waiting for a reviewer. To keep a human in the loop for higher-severity classes, raise the required-approvals count for those and let low-severity waste auto-merge once the preflight is green.

### 2. Onboarding (OIDC, no static keys)

Authentication is OIDC and federated identity only. Bootstrap stays inside your own cloud console session: the admin clicks, authenticates, and the only thing returned to the pipeline is a role ARN or workload-identity provider. Nothing long-lived crosses a boundary.

- **AWS:** deploy `cicd/onboarding/aws/template.yaml` (CloudFormation "Launch Stack") -> returns a role ARN for `AssumeRoleWithWebIdentity`.
- **GCP:** run `cicd/onboarding/gcp/setup.sh` -> creates a Workload Identity Federation provider and service account binding.
- **Azure:** deploy `cicd/onboarding/azure/template.json` (ARM "Deploy to Azure") -> creates a federated credential.

### 3. Secrets

Store the resulting identifiers as repository secrets (role ARN, WIF provider and service account email, Azure tenant/client/subscription ids). See the workflow files for the exact secret names.

## Running it

Dispatch the audit-and-remediate workflow manually, or let the schedule run it:

```
Actions -> Agent Action post Cloud FinOps Audit (OIDC) -> Run workflow
```

Findings upload as workflow artifacts, proposals generate, and one PR opens per finding. Merge a green PR and the apply and post-check complete on the merge.

## Branch cleanup

Remediation branches accumulate. To clear merged or stale ones:

```bash
# 1. see what matches (verify before deleting)
git ls-remote --heads origin 'remediation*' | sed -E 's#^.*refs/heads/##'

# 2. delete them all (single push, multiple refs)
git push origin --delete $(git ls-remote --heads origin 'remediation*' | sed -E 's#^.*refs/heads/##')
```

## Why this shape

Every property here follows from one decision: reach the control plane as data. Findings are data, the safety check is a query, the fix is a statement, and the record is the pull request. No new dashboard, no new vendor, no agent footprint in the estate. Boring and inspectable, which is what you want from something allowed to change production.

Powered by [StackQL](https://stackql.io).
