
# Low Touch auth onboarding

## Brief

The real low-friction bootstrap pattern is vendor consoles, not Terraform:

AWS: a one-click "Launch Stack" CloudFormation URL — user clicks, signs in to their own console as admin, accepts, gets a role ARN back. Their browser session IS the credential; nothing for us to handle.
GCP: a gcloud script (or cloud-shell Open-in-Cloud-Shell URL) they paste-run from their own workstation.
Azure: ARM template "Deploy to Azure" button, same pattern as AWS.
Bootstrap stays inside the cloud admin's existing session — never crosses our boundary. Same model SaaS integrations (Datadog, Snyk, Wiz) use.

So the honest setup story: one click in your cloud console, not "install Terraform, configure credentials, run apply".


## Actual implementation

Three artefacts to author + one README. Each artefact is a per-cloud template
hosted on a public URL; the user clicks a button, deploys it in their own
console as admin, and we get back identifiers (no secrets).

### AWS — CloudFormation Launch Stack

- `cicd/onboarding/aws/template.yaml`
  - `AWS::IAM::OIDCProvider` for `token.actions.githubusercontent.com`
    (`CreateOnlyIfNotExists` — most accounts already have it).
  - `AWS::IAM::Role` with trust policy conditioned on
    `token.actions.githubusercontent.com:sub` matching the user's repo, and
    `:aud == sts.amazonaws.com`.
  - Managed policy `arn:aws:iam::aws:policy/SecurityAudit` + inline
    `cloudformation:ListResources/GetResource` for stackql Cloud Control.
  - `Parameters`: `RepoFullName` (string).
  - `Outputs`: `RoleArn`.
- Host the template at a public URL — e.g. a GitHub-Pages-served raw file or
  a public S3 bucket. CloudFormation accepts an `https://` `templateURL`.
- README "Launch Stack" link:
  ```
  https://console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks/create/review?templateURL=https://<host>/stackql-audit.yaml&stackName=stackql-audit
  ```
- User fills `RepoFullName`, clicks Create. Copies `RoleArn` from Outputs.

### GCP — Cloud Shell paste-run

- `cicd/onboarding/gcp/setup.sh`
  - `gcloud iam workload-identity-pools create …`
  - `gcloud iam workload-identity-pools providers create-oidc …` with
    attribute condition on the GitHub repo claim.
  - `gcloud iam service-accounts create stackql-audit-sa …`
  - `gcloud iam service-accounts add-iam-policy-binding …` (SecurityAudit
    equivalent set: roles/viewer + roles/iam.securityReviewer).
  - `gcloud iam service-accounts add-iam-policy-binding …` for
    `roles/iam.workloadIdentityUser` allowing the WIF principal.
  - Prints `workload-identity-provider` resource name + SA email at the end.
- README "Open in Cloud Shell" link:
  ```
  https://shell.cloud.google.com/cloudshell/open?cloudshell_git_repo=https://github.com/<owner>/stackql-actions-sandbox&cloudshell_workspace=cicd/onboarding/gcp&cloudshell_open_in_editor=setup.sh
  ```
- User reviews the script in Cloud Shell, hits run, copies the two output
  strings.

### Azure — Deploy to Azure (ARM / Bicep)

- `cicd/onboarding/azure/template.json` (or Bicep compiled to JSON)
  - `Microsoft.Graph/applications` (app registration)
  - `Microsoft.Graph/applications/federatedIdentityCredentials` with
    `subject = repo:<owner>/<repo>:ref:refs/heads/main` (and PR variant
    if you want PR checks).
  - `Microsoft.Authorization/roleAssignments` for `Reader` + `Security Reader`
    at the subscription scope.
  - `outputs`: `tenantId`, `clientId`, `subscriptionId`.
- README "Deploy to Azure" link:
  ```
  https://portal.azure.com/#create/Microsoft.Template/uri/<urlencoded-https-url-to-template.json>
  ```
- User fills the form, deploys, copies the three IDs from the Outputs blade.

### GitHub side — pasting the identifiers back

OIDC has no secret values, only identifiers. Repo **variables** are enough
(not secrets). Either of:

```bash
gh variable set STACKQL_AWS_ROLE_ARN             --body 'arn:aws:iam::123:role/stackql-audit'
gh variable set STACKQL_GCP_WIF_PROVIDER         --body 'projects/123/locations/global/workloadIdentityPools/gh/providers/gh'
gh variable set STACKQL_GCP_SA_EMAIL             --body 'stackql-audit-sa@project.iam.gserviceaccount.com'
gh variable set STACKQL_AZURE_TENANT_ID          --body '<guid>'
gh variable set STACKQL_AZURE_CLIENT_ID          --body '<guid>'
gh variable set STACKQL_AZURE_SUBSCRIPTION_ID    --body '<guid>'
```

…or set them in the repo UI: Settings → Secrets and variables → Actions →
Variables tab.

Change the workflow file references from `${{ secrets.X }}` to
`${{ vars.X }}` for the identifier inputs (the existing `STACKQL_ID_FED_*`
secrets can be renamed and moved to vars in one pass).

### Mutation tier (optional, opt-in later)

Same model, but a second CloudFormation/gcloud/ARM template that creates a
**static-credential** principal with narrow write perms (delete-only on the
finops resource types). Output an access key / SA key / client secret, user
pastes into `gh secret set SANDBOX_*`. Only needed when the user enables
auto-apply.

### README copy

Three buttons under "Get started":

> 1. Click **Launch Stack** (AWS) / **Open in Cloud Shell** (GCP) / **Deploy to Azure**.
> 2. Approve in your cloud console.
> 3. Paste the resulting IDs into your repo's Variables tab.
> 4. Push a tag. Watch the dashboard fill in.

Setup time target: under 5 minutes per cloud, no Terraform, no creds shipped.


## Walkthrough

End-to-end. Plan for ~10 minutes total if you wire up all three clouds, ~3 minutes if just one.

### 1. Fork the repo

Click **Fork** in the top right of `stackql-labs/stackql-actions-sandbox`. Use your own GitHub username or org.

Below, replace `<owner>/<repo>` with your fork (e.g. `acme/stackql-actions-sandbox`).

### 2. Anthropic API key (mandatory)

The agent step (per-finding rationale + captain's-call flags) calls Claude. Without this the workflow can run but the PR rationale will be empty.

- Go to https://console.anthropic.com/ → API Keys → Create key.
- Copy the key (`sk-ant-…`).
- In your fork: **Settings → Secrets and variables → Actions → Secrets** → New repository secret:
  - Name: `ANTHROPIC_API_KEY`
  - Value: paste

### 3. AWS — optional, skip if you don't run on AWS

Open **AWS CloudShell** in the account you want to audit (top-right console icon) — it's already authed, nothing to ship. Paste:


```bash
curl -sL https://raw.githubusercontent.com/<owner>/<repo>/main/cicd/onboarding/aws/template.yaml -o /tmp/t.yaml \
&& aws cloudformation deploy \
     --stack-name stackql-audit \
     --template-file /tmp/t.yaml \
     --parameter-overrides RepoFullName=<owner>/<repo> \
     --capabilities CAPABILITY_NAMED_IAM \
&& aws cloudformation describe-stacks --stack-name stackql-audit \
     --query 'Stacks[0].Outputs[?OutputKey==`RoleArn`].OutputValue' --output text
```

eg:

```bash
curl -sL https://raw.githubusercontent.com/stackql-labs/stackql-ai-remediation/main/cicd/onboarding/aws/template.yaml -o /tmp/t.yaml \
&& aws cloudformation deploy \
     --stack-name stackql-audit \
     --template-file /tmp/t.yaml \
     --parameter-overrides RepoFullName=stackql-labs/stackql-ai-remediation \
     --capabilities CAPABILITY_NAMED_IAM \
&& aws cloudformation describe-stacks --stack-name stackql-audit \
     --query 'Stacks[0].Outputs[?OutputKey==`RoleArn`].OutputValue' --output text
```

Or, if OIDC provider already exists

```bash

aws cloudformation delete-stack --stack-name stackql-audit \
&& aws cloudformation wait stack-delete-complete --stack-name stackql-audit \
&& aws cloudformation deploy \
     --stack-name stackql-audit \
     --template-file /tmp/t.yaml \
     --parameter-overrides RepoFullName=stackql-labs/stackql-ai-remediation CreateOIDCProvider=false \
     --capabilities CAPABILITY_NAMED_IAM \
&& aws cloudformation describe-stacks --stack-name stackql-audit \
     --query 'Stacks[0].Outputs[?OutputKey==`RoleArn`].OutputValue' --output text


Waiting for changeset to be created..
Waiting for stack create/update to complete
Successfully created/updated stack - stackql-audit
arn:aws:iam::824532806693:role/stackql-audit

```

The last line prints the role ARN. If your account already has the GitHub OIDC provider, add `CreateOIDCProvider=false` to `--parameter-overrides`.

In your fork: **Settings → Secrets and variables → Actions → Variables** → New repository variable:
- Name: `STACKQL_ID_FED_AWS_ROLE_ARN`
- Value: paste the ARN

### 4. GCP — optional, skip if you don't run on GCP

- Open this URL (it boots Cloud Shell with the script open):
  ```
  https://shell.cloud.google.com/cloudshell/open?cloudshell_git_repo=https://github.com/<owner>/<repo>&cloudshell_workspace=cicd/onboarding/gcp&cloudshell_open_in_editor=setup.sh
  ```
- Cloud Shell will prompt for trust the first time. Accept.
- In the Cloud Shell terminal:
  ```
  PROJECT_ID=<your-gcp-project> REPO=<owner>/<repo> bash setup.sh
  ```
  (or run `bash setup.sh` and answer the two prompts).
- Script prints two values at the end. In your fork → Variables, add:
  - `STACKQL_ID_FED_GCP_WORKLOAD_IDENTITY_PROVIDER` = the WIF provider resource name
  - `STACKQL_ID_FED_GCP_SERVICE_ACCOUNT` = the service account email

### 5. Azure — optional, skip if you don't run on Azure

- Click the **Deploy to Azure** button:
  ```
  https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2F<owner>%2F<repo>%2Fmain%2Fcicd%2Fonboarding%2Fazure%2Ftemplate.json
  ```
- Sign in to Azure as someone with **Owner** at subscription scope (the template assigns subscription-level Reader + Security Reader to the new identity).
- Fill `repoFullName` = `<owner>/<repo>`. Leave the rest default. Choose the subscription you want to audit.
- Click **Review + create**, then **Create**. Wait ~1 minute.
- On the deployment's **Outputs** blade, copy `tenantId`, `clientId`, `subscriptionId`.
- In your fork → Variables, add:
  - `STACKQL_ID_FED_AZURE_TENANT_ID`         = the tenantId
  - `STACKQL_ID_FED_AZURE_CLIENT_ID`         = the clientId
  - `AZURE_INTEGRATION_TESTING_SUB_ID`       = the subscriptionId
- Note: the default subject in the template is `ref:refs/heads/main`. If you also want PR checks / tag-triggered runs to authenticate, add additional federated credentials on the identity for `pull_request` and `ref:refs/tags/*` subjects.

### 6. Trigger the first run

Two options:

- **Tag push**: `git tag audit-finops-oidc-test1 && git push origin audit-finops-oidc-test1`
- **Manual**: Actions tab → **Cloud FinOps Audit (OIDC)** → **Run workflow**.

The audit runs against whichever clouds you wired up (it skips the ones with missing variables). When it finishes:

- The findings dashboard publishes to `https://<owner>.github.io/<repo>/finops/` (enable GitHub Pages on the `gh-pages` branch, Settings → Pages, if you haven't already).
- Per-finding PRs open under the bot account.
- Reviewing + merging a PR triggers the apply workflow.

### What you don't need

- No Terraform, no creds stored locally, no third-party SaaS account.
- No mutation creds at this tier — you can review the PRs and run the SQL yourself if you don't want auto-apply.

### Adding auto-apply later (mutation tier)

This is opt-in. When you're ready, a second set of templates creates write-scoped principals; the outputs paste into **Secrets** (not Variables) named `SANDBOX_AWS_ACCESS_KEY_ID` / `SANDBOX_AWS_SECRET_ACCESS_KEY` / `SANDBOX_GOOGLE_CREDENTIALS` / `SANDBOX_AZURE_*`. The apply workflow only runs when those exist.


