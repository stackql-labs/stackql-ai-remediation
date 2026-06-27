# Rationale — Active EC2 instance (zero-VMs policy) (i-038ae06cdc98be7d9)

(a) **What/where:** This concerns EC2 instance `i-038ae06cdc98be7d9` (`t3a.xlarge`) in region `ap-southeast-2`, flagged because the account is under a zero-VMs policy (no running instances permitted). The intended action is to terminate the instance; upstream classified this as a **manual** remediation and supplied no `preflight_query` or `sql_query`, so `preflight.sql` and `remediation.sql` are intentionally empty. The upstream description suggests `DELETE FROM aws.ec2_native.instances WHERE region = 'ap-southeast-2' AND data__Identifier = 'i-038ae06cdc98be7d9'` as the manual stackql equivalent.

(b) **Confidence: low** — the remediation is manual with no automated guardrail SQL, and the reported `instanceState` is empty/unknown, so this proposal cannot deterministically confirm the instance is safe to terminate. A human must verify state and ownership before acting.

(c) **Captain's call:** Terminating a running EC2 instance is destructive and irreversible — instance store data is lost and any attached service goes down. `t3a.xlarge` is a sizeable (4 vCPU / 16 GiB class) instance, which makes it more likely to be a real workload rather than stray test capacity — treat the zero-VMs flag with extra suspicion here and confirm it is not a shared or production host before terminating. The blank `instanceState` means the audit could not read whether it is running, stopped, or already terminating — resolve that ambiguity first.

(d) **Estimated monthly saving:** not provided in source fields (no `estimated_monthly_usd`); savings depend on the instance's running hours.
