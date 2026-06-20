#!/usr/bin/env python3
"""Generate per-finding remediation proposal directories from a findings.json.

For each entry .findings[i] this writes:
  remediations/proposed/<RUN_ID>-<RUN_ATTEMPT>/<i>-<check_id>-<resource_id>/
    finding.json     — verbatim copy of .findings[i]
    preflight.sql    — verbatim from finding.suggested_remediation.preflight_query
                       (fully substituted by the audit upstream; pass = >=1 row)
    remediation.sql  — verbatim from finding.suggested_remediation.sql_query
                       (documentation only; the live mutation runs via the
                       vendor CLI in the merge-apply workflow)
    remediation.cmd  — present when finding.suggested_remediation.command is set
                       (CLI command form, also documentation only)
    rationale.md     — short, deterministic explanation built from the
                       finding fields

No LLM in this path. SQL/CLI come from the audit's own per-check
suggested_remediation block, already substituted with concrete values
(region, resource id, etc.).

Usage:
  FINDINGS_JSON=path/to/findings.json \\
  RUN_ID=<github_run_id> \\
  RUN_ATTEMPT=<github_run_attempt> \\
  python3 cicd/scripts/generate_proposals.py
"""

from __future__ import annotations

import json
import os
import re
import sys
from pathlib import Path


_SLUG_RE = re.compile(r"[^a-zA-Z0-9._-]+")


def _slug(s: str) -> str:
    return _SLUG_RE.sub("-", str(s or "").strip("-")) or "unknown"


def _resource_id(check_id: str, fields: dict) -> str:
    """Most-specific identifier for this resource type, used in the dir slug."""
    by_check = {
        "aws-finops-unattached-volume":   ["volumeId"],
        "aws-finops-unassociated-eip":    ["allocationId", "AllocationId", "publicIp"],
        "aws-finops-zero-vms-policy":     ["instanceId"],
        "gcp-finops-unattached-disk":     ["name"],
        "gcp-finops-unattached-disks":    ["name"],
        "gcp-finops-unused-ips":          ["name", "address"],
        "gcp-finops-unused-address":      ["name", "address"],
        "gcp-finops-zero-vms-policy":     ["name"],
        "azure-finops-unattached-disk":   ["name"],
        "azure-finops-unattached-disks":  ["name"],
        "azure-finops-unassociated-ip":   ["name"],
        "azure-finops-unassociated-ips":  ["name"],
        "azure-finops-zero-vms-policy":   ["name"],
    }
    fallback = ["volumeId", "instanceId", "publicIp", "address", "name", "id"]
    for k in by_check.get(check_id, []) + fallback:
        v = fields.get(k)
        if v:
            return str(v)
    return "unknown"


def _rationale(finding: dict, resource_id: str, sr: dict | None) -> str:
    cid = finding.get("check_id", "?")
    name = finding.get("check_name", finding.get("name", cid))
    sev = finding.get("severity", "?")
    fields = finding.get("fields") or {}
    region = finding.get("region") or fields.get("region") or "(no region)"
    cost = fields.get("estimated_monthly_usd")
    cost_line = f"- **Estimated saving:** ~${cost:.2f}/mo\n" if isinstance(cost, (int, float)) else ""
    desc = (sr or {}).get("description") or ""
    desc_line = f"\n> {desc}\n" if desc else ""
    return (
        f"# Remediation rationale — {name}\n\n"
        f"- **Check:** `{cid}` (severity `{sev}`)\n"
        f"- **Resource:** `{resource_id}` in `{region}`\n"
        f"{cost_line}"
        f"{desc_line}"
        f"\n"
        f"**Preflight** is the audit's own per-finding `suggested_remediation.preflight_query`. "
        f"Pass criterion: returns >=1 row. Per-resource live state (e.g. \"is THIS volume still "
        f"available?\") is enforced by the vendor CLI at mutation time.\n\n"
        f"**Remediation** runs via the vendor CLI on PR merge. `remediation.sql` "
        f"(and `remediation.cmd` if present) record the canonical statements for "
        f"traceability; they are not executed by this pipeline.\n"
    )


def main() -> int:
    findings_path = Path(os.environ.get("FINDINGS_JSON") or "")
    if not findings_path.is_file():
        print(f"::error::FINDINGS_JSON not set or not a file: {findings_path}", file=sys.stderr)
        return 2

    run_id = os.environ.get("RUN_ID") or "norunid"
    run_attempt = os.environ.get("RUN_ATTEMPT") or "0"
    root = Path("remediations/proposed") / f"{run_id}-{run_attempt}"

    data = json.loads(findings_path.read_text())
    findings = data.get("findings") or []
    if not findings:
        print("::notice::no findings; nothing to generate")
        return 0

    written = 0
    skipped = 0
    for i, finding in enumerate(findings):
        check_id = finding.get("check_id") or "unknown-check"
        sr = finding.get("suggested_remediation") or {}
        preflight = (sr.get("preflight_query") or "").rstrip()
        kill_sql  = (sr.get("sql_query") or "").rstrip()
        kill_cmd  = (sr.get("command") or "").rstrip()

        if not preflight:
            print(f"::warning::no suggested_remediation.preflight_query on finding {i} ({check_id}); skipping")
            skipped += 1
            continue

        fields = finding.get("fields") or {}
        rid = _resource_id(check_id, fields)
        slug = f"{i}-{_slug(check_id)}-{_slug(rid)}"
        dir_ = root / slug
        dir_.mkdir(parents=True, exist_ok=True)

        (dir_ / "finding.json").write_text(json.dumps(finding, indent=2) + "\n")

        (dir_ / "preflight.sql").write_text(
            "-- preflight = suggested_remediation.preflight_query (verbatim, fully substituted upstream).\n"
            "-- pass criterion: returns >=1 row.\n"
            f"{preflight};\n"
        )

        if kill_sql:
            (dir_ / "remediation.sql").write_text(
                "-- canonical kill SQL (documentation only; vendor CLI does the work at merge).\n"
                f"{kill_sql};\n"
            )
        else:
            (dir_ / "remediation.sql").write_text(
                "-- no canonical kill SQL on this finding; vendor CLI dispatches by check_id.\n"
            )

        if kill_cmd:
            (dir_ / "remediation.cmd").write_text(kill_cmd + "\n")

        (dir_ / "rationale.md").write_text(_rationale(finding, rid, sr))

        written += 1
        print(f"::notice::wrote {dir_}")

    print(f"::notice::generated {written} proposal(s), skipped {skipped}")
    return 0 if written else (1 if skipped else 0)


if __name__ == "__main__":
    sys.exit(main())
