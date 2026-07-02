# Rationale — vol-003cc7ab19db52a16

**What & where:** This removes the unattached EBS volume `vol-003cc7ab19db52a16` (1 GiB, `gp2`) in region `ap-southeast-2`. The `DELETE` targets `aws.ec2.volumes` filtered by region and `VolumeId`, and the preflight re-confirms via `aws.ec2_native.volumes` that the volume still exists and its `status` is still `available` (i.e. attached to no instance) before anything is deleted.

**Confidence:** High. An EBS volume in `available` state carries no live attachment, so deleting it does not detach storage from a running instance; the preflight guard means the delete is a no-op if the volume was re-attached in the interim.

**Captain's call:** All eleven flagged volumes are identical 1 GiB `gp2` volumes created on 2026-01-09 within a ~90-minute window (this one at 2026-01-09T03:07:48.480Z), and `AvailabilityZone` comes back as `"null"` for every one. That pattern reads like the residue of an automated/batch process (a failed provisioning run, CI, or a test harness) rather than eleven independent orphans — so this finding should likely be reviewed and actioned as a set, not in isolation. The volumes are now ~6 months old (as of 2026-07-02) with no attachment, which supports deletion, but confirm no snapshot/AMI dependency and consider a snapshot first if the 1 GiB contents could matter. Blast radius is tiny given the size.

**Estimated monthly saving:** $0.1 USD.
