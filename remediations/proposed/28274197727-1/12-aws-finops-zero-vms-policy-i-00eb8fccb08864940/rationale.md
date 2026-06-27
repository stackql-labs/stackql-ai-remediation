# Remediation rationale — active EC2 instance `i-00eb8fccb08864940` (zero-VMs policy)

**(a) What is being removed and where.** This finding flags EC2 instance `i-00eb8fccb08864940` (type `t3.micro`, AZ `ap-southeast-2b`) in region `ap-southeast-2` as a violation of the zero-VMs policy, with the intended action being to **terminate the instance**. Note the upstream `suggested_remediation.type` is `manual`: **no `preflight_query` or `sql_query` was provided**, so `preflight.sql` and `remediation.sql` in this directory are intentionally empty. The upstream description supplies only a templated, un-substituted stackql hint (`DELETE FROM aws.ec2_native.instances WHERE ... data__Identifier = '<instanceId>'`).

**(b) Confidence: low.** Severity is HIGH and there is no automated, substituted remediation query to execute or guardrail-verify. Terminating a compute instance is destructive and irreversible, and the reported `instanceState` is (empty/unknown), so the instance's live status cannot be confirmed from this finding alone.

**(c) Captain's call.** This requires explicit human action and judgement — do **not** auto-apply. A `t3.micro` is a non-trivial instance and may be hosting a live or shared workload; terminating it could cause an outage and loss of instance-store/ephemeral data. Confirm ownership, check for attached volumes/EIPs and in-flight traffic, and stop (rather than terminate) first if there is any doubt. The empty SQL files reflect that this is a manual remediation, not a divergence from upstream.

**(d) Estimated monthly saving:** not provided in this finding's `fields` (`estimated_monthly_usd` absent).
