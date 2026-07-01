**What & where:** This finding flags a running EC2 instance `i-038ae06cdc98be7d9` (`t3a.xlarge`, placement `ap-southeast-2a apse2-az3 default`) in region `ap-southeast-2` against a zero-VMs policy. The suggested remediation is **manual** — the upstream provided no substituted `preflight_query` or `sql_query`, so `preflight.sql` and `remediation.sql` are intentionally empty and no automated deletion is proposed here.

**Confidence: low (for automated action).** The policy match is clear, but termination of a live instance is destructive and the reported `instanceState` is `(unreported)`, so the true running state is not verifiable from the finding alone.

**Captain's call:** A human must decide. `t3a.xlarge` is a comparatively large/expensive instance type, which strongly suggests a real workload rather than stray waste — terminating it could cause an outage. Verify ownership, running state, attached volumes, and any dependent services before terminating; a deterministic check cannot see whether this VM backs a production service.

**Estimated monthly saving:** not provided in the finding.
