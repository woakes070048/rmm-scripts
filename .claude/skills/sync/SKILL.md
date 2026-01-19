---
name: sync
description: Sync scripts to SuperOps - commits changes and pushes to SuperOps platform
---

Sync all modified scripts to SuperOps.

## Steps

1. Check for uncommitted changes
2. If changes exist, commit them with a descriptive message
3. Run the sync script to push to SuperOps
4. Report results

## Execution

```bash
# Check status
git status --short

# If there are changes, commit them
git add -A
git commit -m "Update scripts"

# Run sync
python ~/dev/superops-script-sync/sync.py sync
```

Report the sync results to the user.
