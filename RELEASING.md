# Releasing

The plugin version lives in **three** files that must always agree:

| File | Field | Why it matters |
|------|-------|----------------|
| `VERSION` | whole file | The canonical version; what the README and git tags track |
| `.claude-plugin/plugin.json` | `.version` | **The field Claude Code reads on install** — drift here ships the wrong version to users |
| `.claude-plugin/marketplace.json` | `.plugins[0].version` | What the marketplace catalog advertises |

## Bump the version

Never edit those files by hand. Run:

```bash
bin/bump-version 1.7.0
```

It updates all three at once. Review the diff, then commit with the usual
`Bump to 1.7.0 — <summary>` message.

## The guard

`bin/check-version` asserts the three agree. It runs automatically as a
pre-commit hook (`.githooks/pre-commit`) and blocks any commit that would
leave them inconsistent. On a **fresh clone**, activate the hooks once:

```bash
git config core.hooksPath .githooks
```

You can also run the check by hand any time: `bin/check-version`.

## Why this exists

Through v1.6.0 the "Bump to X" ritual only touched `VERSION`. `plugin.json`
drifted five releases behind (stuck at 1.1.0) and `marketplace.json` four
(stuck at 1.0.0) — so a fresh `claude plugin install dokime` reported 1.1.0
while everything else said 1.6.0. Three sources of truth, one updated by the
ritual.

`bin/bump-version` makes the bump atomic; `bin/check-version` makes drift
un-committable. The class of failure is `unwired_*` — a contract declared in
one place and not wired through to the others.

> Requires `jq` (already a dependency of the `/dokime:triage` skill).
