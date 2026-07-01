**What & where:** This finding flags a running EC2 instance `i-00eb8fccb08864940` (`t3.micro`, placement `ap-southeast-2b apse2-az1 default`) in region `ap-southeast-2` against a zero-VMs policy. The suggested remediation is **manual** — the upstream provided no substituted `preflight_query` or `sql_query`, so `preflight.sql` and `remediation.sql` are intentionally empty and no automated deletion is proposed here.

**Confidence: low (for automated action).** The policy match is clear, but termination of a live instance is destructive and the reported `instanceState` is `(unreported)`, so the true running state is not verifiable from the finding alone.

**Captain's call:** A human must decide. Verify ownership, running state, attached volumes, and any dependent services before terminating; a deterministic check cannot see whether this VM backs a production service.

**Estimated monthly saving:** not provided in the finding.
