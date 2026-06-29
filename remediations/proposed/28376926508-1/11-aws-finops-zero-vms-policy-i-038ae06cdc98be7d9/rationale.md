(a) This targets EC2 instance `i-038ae06cdc98be7d9` (t3a.xlarge) in region `ap-southeast-2` for termination under the zero-VMs policy.

(b) Confidence: low — the upstream remediation `type` is `manual` and supplied no `preflight_query` or `sql_query` (both null), so `preflight.sql` and `remediation.sql` are intentionally empty; there is no automated, byte-verifiable SQL to run. `instanceState` is also empty in the finding, so the live state could not be confirmed.

(c) Captain's call: HIGH severity and destructive. This instance type — a comparatively large instance type likely backs a real workload; with no tags, name, or confirmed state available this must be reviewed and actioned by a human (the StackQL command in the finding's description is a manual template only). Do not auto-execute.

(d) No `estimated_monthly_usd` provided in the finding.
