
# stackql-ai-remediation

This is a template repository for low touch, lean AI Cloud Estate Remediation, powered by [stackql](https://githbb.com/stackql/stackql).  The core premise is detection of Cloud Estate anomales and then automated remediation submissions, actioned upon human approval.

> What you get is AI-generated correction suggestions for perceived harmful Cloud infra.  You decide whether or not to action the suggestions.

The targets systems are the 3 major hyperscalars:

- `google`.
- `aws`.
- `azure`.

OIDC based, keyless authentication is used. Light touch bootstraps are provided for auth against all 3 systems.  If you are working in a larger biz / Enterprise, then you can ask your IAM team for the privileges detailed in [the onboarding guide](/cicd/onboarding/onboarding.md).

## Requirements and setup

Prior to running this, you will need:

- Access to `github`, with the ability to set secrets in the instantiated template repository.
- An `anthropic` API key.
- Either:
    - Admin privileges on whichever of [ `google`, `aws`, `azure` ] you wish to remediate.  Please see [the onboarding guide](/cicd/onboarding/onboarding.md) for further detail.
    - Alternatively, you can use any locally available mechanism to provision OIDC within your orgs, please see [the onboarding guide](/cicd/onboarding/onboarding.md) for further detail.

Once you have your `anthropic` API key and whichever OIDC principals you choose to use, then go ahead and set the GH actions secrets available to your instance repository per Table S-1.

**Table S-1**: Secrets to be available to your repository instance.

| Secret Name | Source | Requirement details | Comments |
| ---- | ---- | ---- | ---- | ---- |
| `ANTHROPIC_API_KEY` | Your Anthropic account.  |  | **Always required** |  |
| `STACKQL_ID_FED_GCP_WORKLOAD_IDENTITY_PROVIDER` | Either [the google auth walkthrough](/cicd/onboarding/onboarding.md), or your business process. |  | Required if you want to include `google`. |  |
| `STACKQL_ID_FED_GCP_SERVICE_ACCOUNT` | Either [the google auth walkthrough](/cicd/onboarding/onboarding.md), or your business process. |  | Required if you want to include `google`. |  |
| `STACKQL_ID_FED_GCP_MUTATE_SERVICE_ACCOUNT` | Either [the google auth walkthrough](/cicd/onboarding/onboarding.md), or your business process. |  | Required if you want to include `google`. |  |
| `STACKQL_ID_FED_AWS_ROLE_ARN` | Either [the aws auth walkthrough](/cicd/onboarding/onboarding.md), or your business process. |  | Required if you want to include `aws`. |  |
| `STACKQL_ID_FED_AWS_MUTATE_ROLE_ARN` | Either [the aws auth walkthrough](/cicd/onboarding/onboarding.md), or your business process. |  | Required if you want to include `aws`. |  |
| `STACKQL_ID_FED_AZURE_CLIENT_ID` | Either [the azure auth walkthrough](/cicd/onboarding/onboarding.md), or your business process. |  | Required if you want to include `azure`. |  |
| `STACKQL_ID_FED_AZURE_TENANT_ID` | Either [the azure auth walkthrough](/cicd/onboarding/onboarding.md), or your business process. |  | Required if you want to include `azure`. |  |
| `STACKQL_ID_FED_AZURE_MUTATE_CLIENT_ID` | Either [the azure auth walkthrough](/cicd/onboarding/onboarding.md), or your business process. |  | Required if you want to include `azure`. |  |
| `STACKQL_ID_FED_AZURE_MUTATE_TENANT_ID` | Either [the azure auth walkthrough](/cicd/onboarding/onboarding.md), or your business process. |  | Required if you want to include `azure`. |  |



## Branch protection requirement

The remediation flow opens one PR per finding under `github-actions`. Status
checks (preflight) must be allowed to run, but a manual approver is not
required — you merge once checks are green.

Set under **Settings → Branches → rule for `main`**:

- **Required approvals:** `0`
- **Require status checks to pass before merging:** on (so the preflight check
  is enforced)
- Everything else: as you like.

Without this, every auto-raised remediation PR will sit blocked waiting for a
reviewer.


## Branch cleanup


```bash

# 1. see what matches (verify before nuking)
git ls-remote --heads origin 'remediation*' | sed -E 's#^.*refs/heads/##'

# 2. delete them all (single push, multiple refs)
git push origin --delete $(git ls-remote --heads origin 'remediation*' | sed -E 's#^.*refs/heads/##')


```
