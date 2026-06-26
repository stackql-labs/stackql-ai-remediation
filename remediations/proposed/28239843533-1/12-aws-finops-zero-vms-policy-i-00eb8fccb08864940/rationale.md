# Rationale — finding 12

**(a) What is being removed and where.** This finding flags EC2 instance `i-00eb8fccb08864940` (t3.micro) in region `ap-southeast-2` under the zero-VMs policy, with the intent to terminate it.

**(b) Confidence: low (for automation).** Upstream classified this as `suggested_remediation.type = "manual"` and provided **no** `preflight_query` and **no** `sql_query`. There is therefore no machine-verified, byte-for-byte remediation to run, and `preflight.sql` / `remediation.sql` in this directory are intentionally empty. The scan also reports a blank `instanceState`, so we cannot confirm whether the instance is currently running or stopped.

**(c) Captain's call.** Terminating an instance is destructive and irreversible — ephemeral instance-store data and the instance itself are lost. `i-00eb8fccb08864940` is a `t3.micro`; this needs explicit human confirmation before any action. The upstream description hints at `DELETE FROM aws.ec2_native.instances WHERE region = '<region>' AND data__Identifier = '<instanceId>'`, but the placeholders are unsubstituted and must not be run blind.

**(d) Estimated monthly saving:** not present in `.fields.estimated_monthly_usd` for this finding.
