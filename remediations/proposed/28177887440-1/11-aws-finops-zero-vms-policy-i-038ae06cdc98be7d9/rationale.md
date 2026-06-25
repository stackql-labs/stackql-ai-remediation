# Rationale — Active EC2 instance (zero-VMs policy) (i-038ae06cdc98be7d9)

(a) **What/where:** This finding flags an active EC2 instance `i-038ae06cdc98be7d9` (`t3a.xlarge`) in region `ap-southeast-2` under the zero-VMs policy; the intended action is to terminate the instance.

(b) **Confidence: low (for automated action)** — upstream `suggested_remediation.type` is `manual` and both `preflight_query` and `sql_query` are `null`, so there is NO machine-substituted SQL to apply. `preflight.sql` and `remediation.sql` have been written as empty files to faithfully reflect the null upstream values; this remediation cannot be executed deterministically and requires a human.

(c) **Captain's call:** `instanceState` is empty in the source data, so we cannot confirm whether the instance is running or stopped; the instance type is `t3a.xlarge`, a comparatively large/expensive instance that may indicate a real production workload rather than pure waste. Termination is destructive and irreversible — a human must confirm this is not a live production workload before any action is taken.

(d) **Estimated monthly saving:** not present in `.fields.estimated_monthly_usd`.
