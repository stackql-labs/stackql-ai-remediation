# Rationale — finding 8

**(a) What is being removed and where.** This proposes deleting the unattached EBS volume `vol-077beae6eaa6dfe77` (1 GiB, `gp2`) in region `ap-southeast-2`. The remediation issues a `DELETE FROM aws.ec2.volumes` keyed on `VolumeId`, and the preflight re-selects the volume requiring `status = 'available'` before anything is removed.

**(b) Confidence: high.** The volume's reported `status` is `available` (i.e. not attached to any instance), and the preflight independently re-confirms `status = 'available'` at execution time, so a volume that has since been attached cannot be deleted by accident.

**(c) Captain's call.** All eleven flagged volumes are 1 GiB `gp2` volumes created within roughly a 1.5-hour window on 2026-01-09 in `ap-southeast-2` — that uniform pattern looks like residue from an automated or batch process (test harness / CI). If that automation is still live it may simply recreate these, and deletion is irreversible with no snapshot taken, so confirm the data is genuinely disposable first. Note also that `AvailabilityZone` is reported as `"null"` in the scan, which is worth a quick sanity check.

**(d) Estimated monthly saving:** $0.1.
