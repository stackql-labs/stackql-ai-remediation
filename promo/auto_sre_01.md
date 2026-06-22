
Cloud audits tell you what's wrong.

SRE work starts when you have to fix it.

This demo shows an automated remediation workflow:

• Run a cloud audit on demand or on a schedule
• Findings are published as structured data
• Per-finding remediation pull requests are opened automatically
• A human reviews and approves the change
• The fix is merged and applied
• A post-apply check verifies the resource is gone

The interesting part isn't the audit.

The interesting part is the auto-generated remediation PR.

Instead of leaving engineers with a list of findings, the system proposes a concrete change that can be reviewed, discussed and merged through normal GitHub workflows.

The automation doesn't get production access.

Humans stay in control.

Powered by StackQL
https://stackql.io

auto@stackql.io

#sre #devops #platformengineering #finops #cloud #githubactions #opensource
