# Rationale — delete unattached EBS volume `vol-003cc7ab19db52a16`

**(a) What & where.** This removes a single unattached EBS volume `vol-003cc7ab19db52a16` (1 GiB, `gp2`) in region `ap-southeast-2`. The `remediation.sql` issues a `DELETE` against `aws.ec2.volumes` scoped to the exact `region` + `VolumeId`, and `preflight.sql` re-confirms the volume still exists and is `status = 'available'` (i.e. not attached) immediately before deletion. Deleting an unattached volume reclaims its provisioned storage; it does not touch any running instance.

**(b) Confidence: HIGH.** The check found the volume in `available` state (genuinely detached), the preflight gates deletion on that same condition, and the scope is a single explicit volume id — so the blast radius is tightly bounded and self-verifying.

**(c) Captain's call.** All eleven volumes in this batch are uniformly 1 GiB `gp2` and were created within a ~90-minute window on 2026-01-09 (this one at `2026-01-09T03:07:48.480Z`), with `AvailabilityZone` reported as `null`. That pattern looks like automated test/CI or detach-and-orphan leftovers rather than a deliberately provisioned prod disk — but there are **no tags in the finding**, so a human cannot rule out that it is a detached root/data volume awaiting re-attach or restore. A deletion is irreversible (no snapshot is taken by this remediation); confirm no snapshot is needed before approving.

**(d) Estimated monthly saving:** ~$0.1/month.
