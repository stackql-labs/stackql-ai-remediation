

Cloud posture audits directly in GitHub Actions using stackql (https://stackql.io).

This workflow runs a control-plane security audit against GCP and emits a markdown report directly into the Actions logs.

Checks currently include:

- public SSH / RDP exposure
- public VM IPs
- Cloud SQL public IPs
- default VPC detection
- default service account usage
- storage bucket IAM posture

In this example, the workflow detects publicly exposed SSH/RDP firewall rules and buckets without uniform bucket-level access, along with remediation guidance.

What I find interesting here is not just the findings, but the operational model:

- no agents
- no log pipeline
- no inventory sync
- no external scanner appliance

Just:
GitHub Actions → StackQL → cloud control plane APIs.

Action repo:
https://github.com/stackql/stackql-audit-action

#cloudsecurity #devsecops #githubactions #gcp #stackql #platformengineering