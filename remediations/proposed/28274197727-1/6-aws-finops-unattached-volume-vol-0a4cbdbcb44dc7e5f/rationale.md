# Remediation rationale — unattached EBS volume `vol-0a4cbdbcb44dc7e5f`

**(a) What is being removed and where.** This deletes the EBS volume `vol-0a4cbdbcb44dc7e5f` (type `gp2`, size 1 GiB) in region `ap-southeast-2`. The volume is reported as `status = available`, i.e. detached from any instance, so it incurs storage cost while serving no workload. The `remediation.sql` issues a `DELETE` against `aws.ec2.volumes`; the `preflight.sql` re-confirms the volume still exists and is still `available` immediately before deletion.

**(b) Confidence: high.** The volume is unattached (no attachment / null AvailabilityZone), its status is `available`, and the preflight guard re-checks availability at execution time, so the delete will no-op if the volume has since been attached or removed.

**(c) Captain's call.** This is a small (1 GiB) and relatively young volume — created 2026-01-09T02:58:38.135Z (~168 days old as of 2026-06-27). Recent, tiny volumes are sometimes deliberately staged (e.g. a freshly provisioned disk awaiting attachment, a test/standby artefact, or part of an automation run) rather than true waste. There is **no Name tag or other metadata** on this finding to confirm it is not part of an active or shared workload, so a human should sanity-check ownership before approving. As the upstream description notes, snapshot the volume first if its data may be needed — deletion is irreversible.

**(d) Estimated monthly saving:** $0.10 (per the finding's `estimated_monthly_usd`). The saving is negligible on its own; value here is primarily hygiene/sprawl reduction across the batch.
