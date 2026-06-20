
# stackql-actions-sandbox


## Branch protection requirement

The remediation flow opens one PR per finding under `github-actions`. Status
checks (preflight) must be allowed to run, but a manual approver is not
required — you merge once checks are green.

Set under **Settings → Branches → rule for `main`**:

- **Required approvals:** `0`
- **Require status checks to pass before merging:** on (so the preflight check
  is enforced)
- Everything else: as you like.

Without this, every auto-raised remediation PR will sit blocked waiting for a
reviewer.


## Branch cleanup


```bash

# 1. see what matches (verify before nuking)
git ls-remote --heads origin 'remediation*' | sed -E 's#^.*refs/heads/##'

# 2. delete them all (single push, multiple refs)
git push origin --delete $(git ls-remote --heads origin 'remediation*' | sed -E 's#^.*refs/heads/##')


```
