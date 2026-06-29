# Remediation rationale — Active EC2 instance (zero-VMs policy)

- **Check:** `aws-finops-zero-vms-policy` (severity `HIGH`)
- **Resource:** `i-038ae06cdc98be7d9` (t3a.xlarge) in `ap-southeast-2`
- **Estimated saving:** not provided in the finding

**(a) What & where.** This finding flags an EC2 instance `i-038ae06cdc98be7d9` of type `t3a.xlarge` running in `ap-southeast-2`, which violates the zero-VMs policy for this target. The intended action is to **terminate** the instance. Upstream classified the remediation as `type: manual` and supplied **no** `preflight_query` or `sql_query`, so `preflight.sql` and `remediation.sql` in this directory are intentionally **empty** — there is no automated, byte-checkable statement to copy. The canonical manual statement recorded by the audit is `DELETE FROM aws.ec2_native.instances WHERE region = '<region>' AND data__Identifier = '<instanceId>'`.

**(b) Confidence: low.** The policy violation itself is `HIGH` severity and clear-cut, but the action is destructive and the upstream remediation is explicitly manual (no preflight gate). The reported `instanceState` is '' (empty in the finding), so we cannot confirm from the data whether the instance is currently running or already stopped.

**(c) Captain's call.** `t3a.xlarge` is a comparatively large/expensive instance type — terminating it has real blast radius if it is live. There is no `Name`/tag in the finding to confirm purpose or owner, and termination is irreversible (instance store data and the instance itself are lost). A human must confirm this is not a live production workload before terminating, and should prefer stop-then-terminate after verifying with the owner. This is why no auto-executable SQL is emitted here.

**(d) Estimated monthly saving:** not present in `fields.estimated_monthly_usd` for this finding.
