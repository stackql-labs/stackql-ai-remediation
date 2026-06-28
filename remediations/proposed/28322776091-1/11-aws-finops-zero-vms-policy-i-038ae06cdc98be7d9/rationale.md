# Rationale — terminate EC2 instance `i-038ae06cdc98be7d9` (zero-VMs policy)

**(a) What & where.** This finding flags a live EC2 instance `i-038ae06cdc98be7d9` (`t3a.xlarge`) in region `ap-southeast-2` under a **zero-VMs policy** that asserts no EC2 instances should exist in this account/region. The intended remediation is to terminate the instance. Note the upstream remediation `type` is `manual` — `preflight.sql` and `remediation.sql` are therefore intentionally **empty**; the suggested action (`DELETE FROM aws.ec2_native.instances ... data__Identifier = 'i-038ae06cdc98be7d9'`) is recorded in `finding.json` for a human to run deliberately, not auto-applied.

**(b) Confidence: LOW.** No automated preflight/SQL was generated, and `instanceState` is empty (`""`) in the finding, so we cannot confirm from this data alone whether the instance is running, stopped, or its current workload — hence this should not be auto-remediated.

**(c) Captain's call.** Terminating a VM is destructive and not reversible. `t3a.xlarge` is a comparatively large/expensive instance type, which raises the stakes: it is more likely to be a deliberate workload than incidental waste, and termination is irreversible (root/instance-store data is lost). Placement is `ap-southeast-2a apse2-az3 default`. With no tags or owner metadata in the finding, a reviewer must independently confirm this instance is not a production or shared workload (e.g. a bastion, build host, or someone's active environment) before terminating; the zero-VMs policy may itself be the thing in error if this VM is legitimately needed.

**(d) Estimated monthly saving:** not provided in `.fields` (no `estimated_monthly_usd` on this finding).
