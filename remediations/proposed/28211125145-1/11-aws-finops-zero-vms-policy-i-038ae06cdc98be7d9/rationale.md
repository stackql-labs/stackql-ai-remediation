# Remediation rationale — finding 11: i-038ae06cdc98be7d9

This finding flags the running EC2 instance `i-038ae06cdc98be7d9` (t3a.xlarge) in region `ap-southeast-2` under the zero-VMs policy; the intended action is to terminate the instance. No automated `preflight_query`/`sql_query` was supplied upstream (remediation `type` is `manual`), so `preflight.sql` and `remediation.sql` are intentionally empty and a human must run the documented `DELETE FROM aws.ec2_native.instances` step.

Confidence: **low** — terminating a compute instance is destructive and irreversible, the reported `instanceState` is empty (`''`) rather than confirmed stopped, and there is no automated guardrail, so this needs manual verification before action.

Captain's call: `t3a.xlarge` is a sizeable instance type that likely backs a real workload — a deterministic check cannot see whether this VM is serving traffic, holds ephemeral state, or belongs to a shared/prod environment. Confirm ownership and capture any needed data before terminating.

Estimated monthly saving: not provided in `fields.estimated_monthly_usd`.
