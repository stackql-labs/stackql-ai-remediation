# Auto SRE — cost per run

Estimated marginal cost of running the flow described in `auto_sre_01.md` end-to-end (audit → propose → PR check → apply → verify), in GitHub Actions on a private repo.

## Per-minute base

- `ubuntu-latest` runner on a private repo: **$0.008 / minute** (GitHub Actions pricing).
- Public / OSS repo: **$0** — runners are free.
- Cloud read/write API calls (AWS, GCP, Azure) used by stackql / the vendor CLIs: well inside free-tier on a sandbox account; treated as $0.
- LLM tokens: $0 — proposal generation is deterministic Python (`cicd/scripts/generate_proposals.py`); no Claude calls in the current flow.

## Per-run breakdown

A "run" = one audit cycle + N per-finding PR + apply cycles.

| Stage | Where | Time | Cost @ $0.008/min |
|---|---|---|---|
| Audit + pages publish | `oidc-audit-workflow-finops-pages.yml` | ~4 min | $0.032 |
| Proposal generation (1 batch, N findings) | `agent-remediation-oidc-audit-workflow-finops.yml` | ~2 min | $0.016 |
| **Per finding** — PR preflight check | `pr-preflight-finops.yml` | ~2 min | $0.016 |
| **Per finding** — apply + post-apply check | `pr-merge-apply-finops.yml` | ~3 min | $0.024 |

Formula: `total_minutes ≈ 6 + 5 × N`  →  `total_cost ≈ $0.05 + $0.04 × N`

## Worked examples

| Findings (N) | Total minutes | Cost (private) | Cost (public/OSS) |
|---|---|---|---|
| 1 | 11 | **$0.09** | $0 |
| 5 | 31 | **$0.25** | $0 |
| 14 | 76 | **$0.61** | $0 |
| 50 | 256 | **$2.05** | $0 |

## What changes the number

- **Cloud account size.** The audit's S3/EC2 enumeration time scales with resource count. A large estate can push the audit job from 4 min to 10+ min.
- **Throttling retries.** Per-finding apply + check do exponential backoff on Cloud Control throttles — adds 10-20s per throttled call.
- **Re-runs from drift.** A failed post-apply check forces an investigation cycle, not a charge in itself.
- **Reintroducing the LLM.** If `rationale.md` ever moves back to Claude, add ~$0.10 per finding (Sonnet pricing, ~20K input + 3K output tokens) on top of the per-minute number.

## Claude expenses (if reintroduced)

Today the proposal generator is deterministic Python — **$0 in Claude tokens.** The `auto_sre_01.md` blurb describes an AI-assisted variant; if you put Claude back in the loop, the cost depends on where:

- **One batched call per audit (all findings together).** Typical Claude Code Action context: ~50K input + ~30K output tokens. Sonnet 4.5 at $3 / 1M input + $15 / 1M output → ~**$0.15 + $0.45 = $0.60 per audit**, roughly flat regardless of N.
- **One call per finding (richer per-finding reasoning).** ~15K input + ~3K output per finding → ~**$0.09 per finding**. At 14 findings ≈ $1.26.
- **Plain-language PR comment (small summariser).** ~3K input + ~0.5K output → **<$0.02 per PR.**

Token counts above include tool-use overhead from the Claude Code Action's Read/Write/Bash loop. Switching to Haiku 4.5 cuts those costs by ~10×; Opus multiplies by ~5×.

## Headline

- **Today (deterministic, no LLM):** ~$0.25 – $0.65 per full run on private repo, 5–15 findings. Free on public/OSS.
- **With Claude reintroduced for proposals:** add ~$0.60 (batched) or ~$1.30 (per-finding × 14) on top of the GH Actions number.
