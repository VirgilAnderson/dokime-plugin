---
name: evolution-signal
description: Maintainer-only — print a recurrence report over the Dokime evolution feed (per failure_class total, distinct cross-dev submitters, per-version breakdown, first→last version). Read-only; informs a triage walk. Requires DOKIME_MAINTAINER_KEY.
---

# Dokime Evolution Signal

You are printing the evolution-feed **recurrence report** — the read side of Component C. It tells the maintainer which failure classes recur, across how many plugin versions, and across how many distinct developers (`submitter_hash`). It is **read-only** and produces a *report, not an action*: the promote/kill decision stays with the maintainer (and, later, the T16 policy).

User request: "$ARGUMENTS"

## Step 1: Run the aggregator

```bash
"${CLAUDE_PLUGIN_ROOT}/bin/dokime-evolution-signal"
```

The bin resolves the maintainer key itself (`DOKIME_MAINTAINER_KEY` env, else `~/.claude/dokime-credentials.json`) and unions the feed's four statuses. Show its Markdown output to the user verbatim.

## Step 2: Read the output by spirit

- **High total + many versions** = a class that keeps recurring → candidate for "rule isn't sticking" or "no rule yet."
- **Devs ≥ 2** = a *workflow-wide* gap, not one developer's blind spot (the cross-dev signal). Devs = 1 with a high total points at an individual knowledge gap, not a shared-workflow rule.
- **"No records returned — feed empty OR rate-limited"** is a *hedge*, not a clean bill of health. The API throttles request bursts to empty responses; if you see this, re-run after a moment rather than concluding the rules are all quiet.

## Discipline

- **Read-only.** This skill never writes to the feed and never edits the workflow. It informs the manual triage walk (`/dokime:triage`); it does not replace it.
- **The "since-rule-added" verdict is not here.** v1 reports all-time recurrence. Tying recurrence to the version a rule shipped in (the true "are the rules sticking?" delta) is a sibling ticket (T15 + T16).
- **Maintainer-only.** Needs the maintainer key; surfaces a clear error and stops if it's absent.
