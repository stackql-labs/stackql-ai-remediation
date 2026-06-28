## Remediation rationale

**(a) What is being removed and where.** Terminates EC2 instance `i-038ae06cdc98be7d9` (type `t3a.xlarge`) in region `ap-southeast-2`, flagged by the zero-VMs policy which mandates that no EC2 instances run in this account/region.

**(b) Confidence: medium.** The policy violation itself is unambiguous, but no automated SQL remediation was generated (`suggested_remediation.type` is `manual`), so termination must be carried out and verified by hand; `instanceState` is reported empty, so the live running state should be re-checked first. The suggested manual stackql is `DELETE FROM aws.ec2_native.instances WHERE region = '<region>' AND data__Identifier = '<instanceId>';`.

**(c) Captain's call.** This is a `t3a.xlarge` — a comparatively large and expensive instance type, so the saving is material, but its size also suggests it may be a genuine workload rather than forgotten waste; treat with extra caution. Terminating an instance is destructive and irreversible — verify there is no attached data, Elastic IP, or dependent service, and that this host is not a deliberately exempt workload, before acting.

**(d) Estimated monthly saving.** Not provided in `.fields`.
