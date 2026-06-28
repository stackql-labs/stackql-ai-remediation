# Rationale — terminate EC2 instance `i-00eb8fccb08864940` (zero-VMs policy)

**(a) What & where.** This finding flags a live EC2 instance `i-00eb8fccb08864940` (`t3.micro`) in region `ap-southeast-2` under a **zero-VMs policy** that asserts no EC2 instances should exist in this account/region. The intended remediation is to terminate the instance. Note the upstream remediation `type` is `manual` — `preflight.sql` and `remediation.sql` are therefore intentionally **empty**; the suggested action (`DELETE FROM aws.ec2_native.instances ... data__Identifier = 'i-00eb8fccb08864940'`) is recorded in `finding.json` for a human to run deliberately, not auto-applied.

**(b) Confidence: MEDIUM.** No automated preflight/SQL was generated, and `instanceState` is empty (`""`) in the finding, so we cannot confirm from this data alone whether the instance is running, stopped, or its current workload — hence this should not be auto-remediated.

**(c) Captain's call.** Terminating a VM is destructive and not reversible. `t3.micro` is a small instance type, but termination is still irreversible. Placement is `ap-southeast-2b apse2-az1 default`. With no tags or owner metadata in the finding, a reviewer must independently confirm this instance is not a production or shared workload (e.g. a bastion, build host, or someone's active environment) before terminating; the zero-VMs policy may itself be the thing in error if this VM is legitimately needed.

**(d) Estimated monthly saving:** not provided in `.fields` (no `estimated_monthly_usd` on this finding).
