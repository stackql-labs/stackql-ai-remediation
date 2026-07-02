# Rationale — i-00eb8fccb08864940

**What & where:** This finding flags the running EC2 instance `i-00eb8fccb08864940` (`t3.micro`) in region `ap-southeast-2` under the zero-VMs policy, which mandates that no EC2 instances run in this account/region. Remediation would terminate the instance (`DELETE FROM aws.ec2_native.instances ... data__Identifier = 'i-00eb8fccb08864940'`).

**No automated query provided:** The upstream `suggested_remediation.type` is `manual`, so `preflight_query` and `sql_query` are `null`. `preflight.sql` and `remediation.sql` in this directory are therefore intentionally empty — there is nothing to execute automatically and any termination must be performed by a human operator using the templated command in the finding's `description`.

**Confidence:** Low-to-medium as an automated action. The policy match is clear, but `instanceState` is (empty / not reported), so the finding does not confirm the instance is actually running vs. stopped, and terminating is irreversible.

**Captain's call:** `t3.micro` is a comparatively large/expensive instance type; combined with placement `ap-southeast-2b apse2-az1 default`, this could well be a real workload rather than stray waste, so terminating blindly is risky. HIGH severity here reflects a policy violation, not a safe-to-delete signal — a human must confirm ownership, tags, and that no service depends on it before termination.

**Estimated monthly saving:** not provided in `fields.estimated_monthly_usd`.
