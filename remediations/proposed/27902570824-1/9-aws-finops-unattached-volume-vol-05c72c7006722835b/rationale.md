# Remediation rationale — Unattached EBS volumes

- **Check:** `aws-finops-unattached-volume` (severity `LOW`)
- **Resource:** `vol-05c72c7006722835b` in `ap-southeast-2`
- **Estimated saving:** ~$0.10/mo

> Delete the unattached EBS volume (snapshot first if its data may be needed).

**Preflight** is the audit's own per-finding `suggested_remediation.preflight_query`. Pass criterion: returns >=1 row. Per-resource live state (e.g. "is THIS volume still available?") is enforced by the vendor CLI at mutation time.

**Remediation** runs via the vendor CLI on PR merge. `remediation.sql` (and `remediation.cmd` if present) record the canonical statements for traceability; they are not executed by this pipeline.
