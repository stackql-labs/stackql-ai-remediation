# Rationale — Unattached EBS volumes (vol-0ca8412179b80723c)

(a) **What/where:** This removes the unattached EBS volume `vol-0ca8412179b80723c` (1 GiB, `gp2`) in region `ap-southeast-2`. The `DELETE` targets `aws.ec2.volumes` and is gated by a preflight query that re-confirms the volume still exists and reports `status = 'available'` (i.e. detached) immediately before deletion.

(b) **Confidence: high** — the volume reports `status = available`, meaning it is not attached to any instance, and the preflight aborts the action if that state changes between detection and remediation.

(c) **Captain's call:** The volume is only 1 GiB (very small, low-reward deletion) and its `AvailabilityZone` is reported as the literal string "null" — a source-data anomaly worth a glance. All eleven volumes in this run were created within a tight window on 2026-01-09, which can be the signature of an automated test or scratch harness; if that harness is still active these could be re-created or, conversely, be safe leftovers. There are no name tags to reveal whether the volume backs a restore workflow, so deletion is irreversible — snapshot first if the data may be needed. Created 2026-01-09T03:02:40.240Z, so it has sat idle for roughly five and a half months as of 2026-06-27.

(d) **Estimated monthly saving:** $0.1.
