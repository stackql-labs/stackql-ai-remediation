
Free and open-source cross-cloud FinOps review from GitHub Actions.

This run audited:

* 17 AWS regions
* 20 GCP projects
* Azure subscriptions

using OIDC / federated identity only.

No cloud keys.
No agents.
No billing exports.

In this case it identified 14 unattached EBS volumes and produced remediation guidance in about two minutes.

Sample workflow:

https://github.com/stackql/stackql-audit-action/blob/v0.9/docs/examples/oidc-audit-workflow-finops.yml

