# Rationale — Unattached EBS volumes (vol-0e620fc9c3b6d55db)

(a) **What/where:** This removes the unattached EBS volume `vol-0e620fc9c3b6d55db` (1 GiB, `gp2`) in region `ap-southeast-2`. The `DELETE` targets `aws.ec2.volumes` and is gated by a preflight query that re-confirms the volume still exists and is `status = 'available'` (i.e. detached) immediately before deletion.

(b) **Confidence: high** — the volume reports `status = available`, meaning it is not attached to any instance, and the preflight aborts the action if that state changes between detection and remediation.

(c) **Captain's call:** The volume is only 1 GiB (very small / low-reward) and its `AvailabilityZone` is reported as the literal string "null", a source-data anomaly worth a glance. There are no name tags here to reveal whether it backs a restore workflow or a soon-to-be-attached instance, and deletion is irreversible — snapshot first if the data may be needed. Created 2026-01-09T03:01:34.970Z, so it has sat idle for roughly five months as of 2026-06-25.

(d) **Estimated monthly saving:** $0.1.
