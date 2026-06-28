## Remediation rationale

**(a) What is being removed and where.** Terminates EC2 instance `i-00eb8fccb08864940` (type `t3.micro`) in region `ap-southeast-2`, flagged by the zero-VMs policy which mandates that no EC2 instances run in this account/region.

**(b) Confidence: medium.** The policy violation itself is unambiguous, but no automated SQL remediation was generated (`suggested_remediation.type` is `manual`), so termination must be carried out and verified by hand; `instanceState` is reported empty, so the live running state should be re-checked first. The suggested manual stackql is `DELETE FROM aws.ec2_native.instances WHERE region = '<region>' AND data__Identifier = '<instanceId>';`.

**(c) Captain's call.** This is a `t3.micro` — a small, low-cost instance type, so the blast radius is limited, but still confirm it is not a bastion, agent, or other shared host. Terminating an instance is destructive and irreversible — verify there is no attached data, Elastic IP, or dependent service, and that this host is not a deliberately exempt workload, before acting.

**(d) Estimated monthly saving.** Not provided in `.fields`.
