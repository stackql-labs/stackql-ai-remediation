# Rationale — Active EC2 instance (zero-VMs policy) (i-00eb8fccb08864940)

(a) **What/where:** This concerns the running EC2 instance `i-00eb8fccb08864940` (t3.micro) in region `ap-southeast-2`, flagged HIGH by the zero-VMs policy (no EC2 instances are expected in this account/region). The intended action is to terminate the instance, e.g. `DELETE FROM aws.ec2_native.instances WHERE region = 'ap-southeast-2' AND data__Identifier = 'i-00eb8fccb08864940'`.

(b) **Confidence: low** — the upstream remediation is `type: manual` with no `preflight_query` or `sql_query` supplied, so no deterministic guardrail exists. The reported `instanceState` is (empty / unreported), leaving the live status unconfirmed; this needs human verification before any termination.

(c) **Captain's call:** Termination is irreversible and a deterministic check cannot see what this VM does. Confirm it is not a production, bastion, or shared workload, check for instance-store data that would be lost, and prefer stop-then-terminate after a snapshot. Because preflight/SQL were null upstream, the accompanying `preflight.sql` and `remediation.sql` files are intentionally empty.

(d) **Estimated monthly saving:** not provided in the finding fields.
