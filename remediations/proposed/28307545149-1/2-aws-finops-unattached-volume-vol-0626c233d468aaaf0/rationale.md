## Remediation rationale

**(a) What is being removed and where.** Deletes the unattached EBS volume `vol-0626c233d468aaaf0` (1 GiB, `gp2`) in region `ap-southeast-2`. The volume's status is `available`, i.e. it is not attached to any EC2 instance.

**(b) Confidence: high.** The preflight query re-confirms the volume is still `available` immediately before the delete runs, and an unattached gp2 volume backs no live workload.

**(c) Captain's call.** This volume is only 1 GiB and was created at 2026-01-09T02:43:48.426Z — it sits inside a tight cluster of identically-sized 1 GiB volumes all created on 2026-01-09, which points to an automated batch or test harness rather than human-provisioned storage. The reported AvailabilityZone is `null`, which is unusual and worth a glance. Snapshot first if the data might still be needed, and confirm no restore/backup job depends on it.

**(d) Estimated monthly saving.** $0.1 / month.
