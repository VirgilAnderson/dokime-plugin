---
name: update
description: Update the Dokime plugin to the latest version from the remote repository.
---

# Update Dokime Plugin

Pull the latest changes from the remote repository and reinstall the plugin.

Run these commands in order:

1. Pull the latest from the marketplace:
```bash
cd ~/.claude/plugins/marketplaces/dokime && git pull
```

2. Reinstall the plugin:
```bash
claude plugin uninstall dokime && claude plugin install dokime@dokime
```

Report the result to the user. If the pull shows "Already up to date," say so. If it pulled new changes, list the files that changed. Tell the user to start a fresh session for the update to take effect.
