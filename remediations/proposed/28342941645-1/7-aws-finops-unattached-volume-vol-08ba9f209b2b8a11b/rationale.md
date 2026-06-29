# Remediation rationale — Unattached EBS volumes

- **Check:** `aws-finops-unattached-volume` (severity `LOW`, category `waste`)
- **Resource:** `vol-08ba9f209b2b8a11b` in `ap-southeast-2`
- **Estimated saving:** ~$0.1/mo

**(a) What & where.** This removes a single unattached EBS volume `vol-08ba9f209b2b8a11b` (1 GiB, `gp2`) in region `ap-southeast-2`. The volume is in `status = available` (detached from any instance) with a null `AvailabilityZone`, so it is serving no workload — it is pure waste. The `DELETE` targets exactly that one `VolumeId`.

**(b) Confidence: high.** The audit observed the volume as `available`, and `preflight.sql` re-asserts `status = 'available'` for this exact `volumeId` immediately before the mutation — if the volume has since been re-attached the preflight returns zero rows and the delete is gated off. The blast radius is tiny (1 GiB).

**(c) Captain's call.** No `Name`/tag is present in the finding, so there is no signal that this belongs to a named or production workload — but equally there is nothing proving it does not. This volume was created `2026-01-09T02:52:39.739Z`, part of a cluster of identical 1 GiB `gp2` volumes all created on 2026-01-09 within a ~1.6h window, which strongly suggests an automated/test batch left behind rather than hand-provisioned prod storage. Deletion is irreversible and the data is **not** snapshotted by this step — if the contents could conceivably be needed, snapshot first.

**(d) Estimated monthly saving:** $0.1.
