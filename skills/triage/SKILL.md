---
name: triage
description: Triage the Dokime evolution feed — fetch pending entries from launchtest.app, walk through each, mark as promoted / reviewed / dismissed. Single-user (maintainer only). Requires DOKIME_MAINTAINER_KEY.
---

# Dokime Triage

You are triaging the Dokime evolution feed. This skill is maintainer-only: it reads from and writes to launchtest.app/api/dokime/evolution, which is gated by a Bearer token only Virgil holds.

User request: "$ARGUMENTS"

## Step 1: Locate the Maintainer Key

The skill needs `DOKIME_MAINTAINER_KEY` to authenticate. Check sources in order:

1. **Environment variable** — `echo $DOKIME_MAINTAINER_KEY`. If set, use it.
2. **Credentials file** — `~/.claude/dokime-credentials.json`, expected shape:
   ```json
   { "maintainer_key": "<hex string>" }
   ```
   Read with `jq -r .maintainer_key ~/.claude/dokime-credentials.json` if present.

If neither resolves, stop and tell the user:

> Maintainer key not found. Either export `DOKIME_MAINTAINER_KEY` in your shell, or create `~/.claude/dokime-credentials.json` with `{"maintainer_key": "<key>"}` (file mode 0600). The key is also present in the launchtest `.env` file if you've forgotten it.

Do not proceed without the key.

## Step 2: Parse the Request

Default behavior with no arguments: triage all pending entries, oldest first.

Recognized argument shapes:
- `(empty)` → triage pending
- `pending` / `reviewed` / `promoted` / `dismissed` / `all` → triage that status
- `failure-class <name>` → triage pending entries with that failure_class
- `count` → show summary counts only, no triage walk
- `<id>` (numeric) → triage just that entry

## Step 3: Fetch the Queue

Build the URL from the args. Default: `https://launchtest.app/api/dokime/evolution?status=pending&limit=200`.

```bash
curl -sS "https://launchtest.app/api/dokime/evolution?status=pending&limit=200" \
  -H "Authorization: Bearer $KEY" \
  -H "Accept: application/json"
```

If the response is `401`, the key is wrong or the server isn't configured — surface the error and stop. If `503`, the server has no `DOKIME_MAINTAINER_KEY` in its `.env` — surface and stop. If `200`, parse the JSON.

## Step 4: Show the Overview

Before walking entries, show a summary so the user can decide whether to triage all or focus:

```
─── Evolution feed: pending ───
Total: N entries
Oldest: <date> (id=X)
Newest: <date> (id=Y)

By failure_class:
  <class>      N entries
  <class>      M entries
  (no class)   K entries

By workflow_gap_type:
  structural   N entries
  discipline   M entries
  (unset)      K entries
```

Then ask: *"Walk through all N entries one at a time, group by failure_class, or focus on something specific?"*

## Step 5: Walk Through Entries

For each entry, display a single-screen view:

```
─── Entry id=42 (1 of N) ───
Submitted: 2026-05-11 at 14:23 UTC (3 days ago)
Plugin version: 1.5.0
Failure class: tautological_test
Detection method: code_review
Gap type: structural
Steps: R4-C, R5
Project type: brownfield Laravel

OBSERVATION:
<full observation text, word-wrapped to terminal width>

ACTION TAKEN OR PROPOSED:
<full action_taken text, word-wrapped>
```

Then ask: *"[P]romote, [R]eviewed (acknowledged, not promoted), [D]ismiss, [S]kip, [Q]uit"*

Handle each:

- **P (Promote)**: This means the action will be folded into the workflow text. Two sub-options:
  - Auto-draft: read the relevant workflow file (`~/Documents/Dokime/dokime-plugin/agents/dokime.md` or `agents/dokime-review.md` based on which Steps the entry references), draft the text edit, show it for review, but do NOT apply it — Virgil applies edits manually in his own time. After showing the draft, PATCH the entry to `status=promoted`.
  - Skip draft: just PATCH to `promoted`.
  Ask the user which sub-option.
- **R (Reviewed)**: Acknowledged but won't be folded in. Examples: duplicate of an already-promoted entry; valid but out of scope; useful context that doesn't change workflow text. PATCH to `status=reviewed`.
- **D (Dismiss)**: Not valid, not actionable, or noise. PATCH to `status=dismissed`. Always ask for a one-line dismissal reason (will be appended to local triage log; the API doesn't store it).
- **S (Skip)**: Leave as pending, move to next. Useful when an entry needs more thought.
- **Q (Quit)**: Stop walking, show summary, exit.

For each PATCH:

```bash
curl -sS -X PATCH "https://launchtest.app/api/dokime/evolution/$ID" \
  -H "Authorization: Bearer $KEY" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"status":"<status>"}'
```

Surface the response. If non-200, do NOT advance — let the user retry or skip.

## Step 6: Maintain a Local Triage Log

Append every decision to `~/Documents/Dokime/data/triage-log.md` (create if absent). Format:

```markdown
## 2026-05-12

- id=42 → promoted (auto-drafted edit for agents/dokime.md Pass 3)
- id=43 → reviewed (duplicate of id=18, already promoted)
- id=44 → dismissed (spam: empty observation)
- id=45 → skipped (need to check whether Rule 12 already covers this)
```

This complements the API status — the API stores *what* happened; the log stores *why*. The why is the part future-Virgil needs when looking back at "why did we dismiss this?"

## Step 7: Final Summary

At end (whether full walk or quit), show:

```
─── Triage session summary ───
Walked: 12 entries
Promoted: 3
Reviewed: 4
Dismissed: 2
Skipped: 3
Remaining pending: 34 (skipped + not yet walked)

Promoted entries for follow-up:
- id=42 — tautological_test (R4-C, R5) — draft staged at <path>
- id=51 — bureaucratic_nudge (R5) — draft staged at <path>
- id=58 — specialist_agent_discovery_scope (R4-E) — no draft (manual edit needed)

Triage log appended: ~/Documents/Dokime/data/triage-log.md
```

## Discipline

- **Do not auto-apply workflow edits.** Drafts are shown for review; Virgil applies them by hand in his own time. The skill is for triage, not for committing to the workflow file.
- **Do not retry PATCH on failure without user direction.** If a PATCH fails, surface the error and ask. Do not silently re-attempt — a real failure is signal.
- **Single-user discipline.** This skill is for Virgil's maintainer triage only. Do not invoke it from a project session where the key isn't already configured; surface the missing-key message and stop.
- **Read-by-spirit on dismiss reasons.** When the user gives a dismissal reason, write it verbatim to the log. Don't paraphrase to "improve" it.
