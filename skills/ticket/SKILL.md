---
name: ticket
description: Turn a free-form work description into a paste-ready Jira-format ticket — Connextra story + falsifiable ACs (features) or repro + expected/actual + ACs (bugs). Title encodes the failure shape. Description fits a 3x5 index card; extras go in Jira comments. Tickets describe, never diagnose.
---

# Dokime Ticket

User request: "$ARGUMENTS"

You are drafting a Jira-format ticket. The output is **paste-ready text only** — the dev pastes it into Jira themselves; this skill does not call the Jira API.

The discipline this skill enforces is dokime's ticket-shape pattern:

- **Title encodes the failure shape** (for bugs) or the user-visible change (for features). A reader skimming the backlog should know *what's happening* from the title alone.
- **Description fits a 3×5 index card.** Connextra story + AC bullets and *nothing else*. Anything beyond — investigation notes, screenshots, related history, fix hypotheses — goes in Jira **comments**, not the description.
- **Tickets describe, never diagnose.** Bug ticket bodies stay at *observable evidence* (repro, expected vs actual, stack/breadcrumb references). Root-cause hypotheses, fix prescriptions, and "recommended sibling ticket" notes belong to the dev working the ticket, not the ticket itself.
- **AC bullets are falsifiable.** Each AC must be a thing a reviewer can answer yes/no on. Wish-statements ("system should be fast") get rewritten to discriminating statements ("response time < 200ms p95").

## Step 1: Determine ticket type

If `$ARGUMENTS` clearly indicates type, skip to Step 2. Otherwise ask:

> "Is this a **feature** (adds or changes capability) or a **bug** (existing capability is broken)?"

The two have different body shapes; the rest of the skill branches on this.

## Step 2: Gather inputs conversationally

Ask only for fields not already present in `$ARGUMENTS`. Don't repeat back what the user already gave; just fill the gaps.

**For features**, you need:
- **Who** the user is (role / persona / system).
- **What** they want (the user-visible change — not the implementation).
- **Why** it matters (the value; what changes for the user when this lands).
- **Acceptance criteria** (1–4 bullets; each falsifiable).

**For bugs**, you need:
- **Reproduction steps** (exact, minimal, environment-named — what URL, what role, what input).
- **Expected behavior** (what *should* happen).
- **Actual behavior** (what *does* happen — observable; no inferred mechanism).
- **Evidence** (Sentry link / breadcrumb / stack / screenshot reference — pointers only, no quoting).
- **Acceptance criteria** (typically "repro produces expected behavior; no regression in related areas X/Y"; falsifiable).

If the user supplies a fix hypothesis or a root-cause guess, **do not include it in the ticket body**. Acknowledge it as context for the eventual dev, but the body stays evidence-only. Tagged class anchor: `feedback_ticket_describe_dont_diagnose`.

## Step 3: Draft the title with self-check

Generate one candidate title. Then self-check it before showing the user:

**For features:**
- ✗ Generic: "Update dashboard"
- ✗ Implementation-named: "Add VueDashboardWidget component"
- ✓ User-visible-change-named: "Show per-account revenue tile on the dashboard"

**For bugs:**
- ✗ Generic: "Fix bug"
- ✗ Error-class-named: "TypeError in DashboardController"
- ✗ Inferred-cause-named: "Eager-load missing on revenue query"
- ✓ Failure-shape-named: "Dashboard revenue tile shows zero when account has data"

If your candidate fails the check, regenerate. Show the user the candidate and ask for adjustment if needed. **The title is the line that determines whether someone reading the backlog stops or scrolls past** — it must encode the failure shape, not the error class. Tagged class anchor: `feedback_udo_title_skim`.

## Step 4: Draft the body per type-specific shape

**Feature body shape** (Markdown):

```markdown
**As** <user>
**I want** <what>
**So that** <why>

**Acceptance criteria:**
- <AC bullet 1>
- <AC bullet 2>
- ...
```

**Bug body shape** (Markdown):

```markdown
**Repro:**
1. <minimal steps>
2. <to reproduce>

**Expected:** <observable expected behavior>
**Actual:** <observable actual behavior>

**Evidence:** <Sentry link / breadcrumb id / screenshot ref>

**Acceptance criteria:**
- Repro above produces expected behavior in <environment>.
- <regression-check AC, if applicable>
```

Keep the body to roughly what fits a 3×5 index card. If the inputs you gathered overflow that, **move overflow content into a "first comment" block** that the dev pastes as the ticket's first comment, not into the description.

## Step 5: Self-check ACs for falsifiability

For each AC bullet, ask: *"Can a reviewer answer yes/no on this without ambiguity?"*

- ✗ "System should be fast" → ✓ "p95 response time on /dashboard endpoint < 200ms in staging."
- ✗ "Better error handling" → ✓ "When upstream returns 500, frontend shows toast 'Try again in a moment' and logs to Sentry with tag `upstream_5xx`."
- ✗ "Doesn't break anything" → ✓ "All existing tests in `tests/Feature/Dashboard/` pass on the branch."

Rewrite any wish-statement AC. If a wish-statement can't be made falsifiable, it doesn't belong in the AC — it belongs in the broader spec/discussion.

## Step 6: Emit paste-ready output

Print:

1. **Title** (single line; no markdown decoration).
2. **Description** block (the body from Step 4, raw Markdown).
3. **(If overflow exists)** A clearly-labeled `## Paste as first Jira comment:` block with the overflow content.

That's it. No "next steps," no "should I file this?" — the dev pastes and goes.

## Discipline

- **Conversational only in v1** — do not accept structured input (JSON / YAML). Skill-to-skill structured-input mode is v2+.
- **No Jira API integration** — output is text; the dev pastes.
- **No metadata fields** (Component / Sprint / Fix Version / Labels) in v1 — those are project-specific Jira config; the dev sets them in the UI.
- **Read by spirit, not by checklist** — the index-card threshold is a discipline against bloat, not a literal 3×5 inch measurement. A 6-line bug body with sharp ACs is better than a 3-line one with vague ones.
- **If the dev pushes back** on a self-check rewrite (title, AC), accept their version *with* the original captured as a one-line note in the spec where the dev can see what the discipline would have produced. Their override is recorded; the discipline isn't silently overridden.
