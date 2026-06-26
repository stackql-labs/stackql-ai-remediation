# Remediation rationale — finding 7: vol-08ba9f209b2b8a11b

This change deletes the unattached EBS volume `vol-08ba9f209b2b8a11b` (gp2, 1 GiB) in region `ap-southeast-2`. The preflight re-confirms the volume still exists and is in `available` (unattached) state before the `DELETE` is issued against `aws.ec2.volumes`.

Confidence: **high** — the volume is detached (`status = available`) and the preflight gates the delete on that same condition, so an idle, unused resource is being removed with a guarded check.

Captain's call: the volume is tiny (1 GiB) and was created on 2026-01-09T02:52:39.739Z; every volume in this batch was created within a narrow window on 2026-01-09, which suggests they may all belong to a single job or test workload that could still be pending re-attachment — confirm none are awaiting reuse, and snapshot first if the data may be needed. `AvailabilityZone` is reported as `null`, so verify the resource resolves as expected.

Estimated monthly saving: **$0.1** (from `fields.estimated_monthly_usd`).
