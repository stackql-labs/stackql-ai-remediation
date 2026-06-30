(a) This finding flags the active EC2 instance `i-00eb8fccb08864940` (type `t3.micro`, placement `ap-southeast-2b apse2-az1 default`) in region `ap-southeast-2` under the zero-VMs policy; the intended action is to terminate the instance.

(b) Confidence: LOW — upstream marked this as a MANUAL remediation (`type: manual`) and supplied no automated preflight or SQL query, so no deterministic delete is staged here; a human must terminate it. preflight.sql and remediation.sql are intentionally empty for this reason.

(c) Captain's call: terminating an EC2 instance is destructive and irreversible (instance store data is lost). The captured `instanceState` is empty, so confirm the real running state, check for attached EBS volumes/EIPs and any dependent services, and take a snapshot/AMI if needed before acting.

(d) Estimated monthly saving: not provided in fields.
