
## Elevator Pitch

Whether you're one engineer or a hundred, your cloud bill carries waste nobody owns. We turn each line item into a PR. You click merge. It's gone. GitHub is the audit trail — no new dashboard, no new vendor.



## Low Touch auth onboarding


The real low-friction bootstrap pattern is vendor consoles, not Terraform:

AWS: a one-click "Launch Stack" CloudFormation URL — user clicks, signs in to their own console as admin, accepts, gets a role ARN back. Their browser session IS the credential; nothing for us to handle.
GCP: a gcloud script (or cloud-shell Open-in-Cloud-Shell URL) they paste-run from their own workstation.
Azure: ARM template "Deploy to Azure" button, same pattern as AWS.
Bootstrap stays inside the cloud admin's existing session — never crosses our boundary. Same model SaaS integrations (Datadog, Snyk, Wiz) use.

So the honest setup story: one click in your cloud console, not "install Terraform, configure credentials, run apply".

