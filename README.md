
# stackql-actions-sandbox


## Branch cleanup


```bash

# 1. see what matches (verify before nuking)
git ls-remote --heads origin 'remediation*' | sed -E 's#^.*refs/heads/##'

# 2. delete them all (single push, multiple refs)
git push origin --delete $(git ls-remote --heads origin 'remediation*' | sed -E 's#^.*refs/heads/##')


```
