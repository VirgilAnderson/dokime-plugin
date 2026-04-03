---
name: version
description: Show the currently installed Dokime plugin version.
---

# Dokime Version

Check the installed version by reading the VERSION file from the marketplace copy:

```bash
cat ~/.claude/plugins/marketplaces/dokime/VERSION
```

Also check if the remote is ahead:

```bash
cd ~/.claude/plugins/marketplaces/dokime && git fetch --quiet && git log HEAD..origin/main --oneline
```

Report the version to the user. If the remote has commits ahead, tell them to run `/dokime:update`.
