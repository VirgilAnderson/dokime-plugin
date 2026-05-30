# Dokime

A structured development workflow for AI-assisted software engineering with human checkpoints at every phase.

**Author:** Virgil Anderson
**License:** All rights reserved

## What It Does

Dokime is a TDD workflow that surfaces silent assumptions before they become code. AI coding tools make reasonable decisions invisibly — the right architecture, the right edge case handling, the right business logic interpretation. The code works. But nobody knows *why* it was built that way.

Dokime forces every decision into the open where a human can approve, correct, or learn from it. The result is a codebase that humans can actually maintain.

**The workflow also measures itself and teaches its operator.** As of plugin **1.12.0**, every checkpoint produces a machine-readable record (a measurement spine), and at decision points the dev's prior knowledge is surfaced and reviewed via just-in-time discriminating questions (a per-dev knowledge model). The first makes the workflow itself auditable; the second makes the human running it less likely to ship code they don't understand. See *How It Records and Teaches* below.

## How It Records and Teaches (since plugin 1.12.0)

Two complementary layers carry alongside the step-by-step prose.

### Measurement — the audit trail

Every checkpoint produces a JSONL record. Three record types accumulate in a per-user measurement store (`~/.dokime/measurements/` by default; configurable via `$DOKIME_MEASUREMENT_STORE` or a `measurement_store_path` key in `./.claude/dokime-config.json`):

| File | Holds | Written at |
|------|-------|-----------|
| `checkpoint-outcomes.jsonl` | one per checkpoint resolved (`approved-clean` · `approved-with-changes` · `reopened`) | every CHECKPOINT |
| `escaped-ambiguity.jsonl` | one per bug whose root cause was an ambiguity an earlier Step 4 / B5 should have surfaced — attributed to the originating ticket | B4 |
| `comprehension-checks.jsonl` | one per discriminating question; carries pass/fail + AI's self-tagged Bloom + (since 1.12.0) the recommended Bloom target | Step 3 + Step 7 reviews |

These records make the workflow evaluable against its own claims. They never contain a developer identifier — privacy by construction.

### Comprehension — just-in-time teaching + retention

A private, out-of-repo per-dev knowledge model (`~/.dokime/knowledge/cards.json`, never committed) accumulates **cards** — one per concept the dev has been checked or taught on. Each card has a Leitner box (1–5), a pass/fail history, and an *anchored* concept slug (Failure Class Registry class for skill cards; `<project>:<file-or-symbol>` for codebase cards — never a fuzzy free-text name).

The teaching loop runs at two places:

- **Step 3 (Understand the Ticket)** — *learning new things.* An optional UI walkthrough (default-on for tickets touching user-visible surfaces) walks the dev through how the affected feature works. Then a universal-but-gentle comprehension check: one discriminating question, generated at the right Bloom level for the dev's prior familiarity with the concept (computed by `bin/target-bloom`). Pass/fail recorded; card created or updated.
- **Step 7 (Propose Approach)** — *reviewing relevant prior knowledge before the architectural decision.* Cards relevant to *this* ticket are surfaced — narrow (codebase cards anchored to files Step 6 named) + broad (AI-proposes-dev-curates from the skill deck) — capped at 3, sorted by Leitner box ascending. Each is reviewed via a discriminating question at its target Bloom. The dev demonstrates understanding *before* proposing the approach.

The whole thing is **non-gating** — a failed comprehension check or review never blocks the workflow. It records, surfaces, and helps; it does not police.

### How they wire together

The workflow agent invokes a single advance-helper at every checkpoint — `bin/dokime-checkpoint` — which internally dispatches to the right record/capture helpers based on which flags are passed. One call site, deterministic plumbing. A Step-15 audit (`bin/dokime-cross-check`) compares the spec's `✓ PASSED` markers to the recorded checkpoint count and surfaces any silent miss.

The `bin/` directory holds the deterministic implementation (10 helpers, 85 test cases). The `agents/dokime.md` workflow prose tells the agent *when* to call them. You don't invoke `bin/` helpers directly; the workflow agent does.

## Installation

**Step 1: Add the marketplace**
```bash
claude plugin marketplace add VirgilAnderson/dokime-plugin
```

**Step 2: Install the plugin**
```bash
claude plugin install dokime
```

**Step 3 (optional): Scope to a project**
```bash
claude plugin install dokime --scope project
```

### Staying current

A `SessionStart` hook checks whether your installed version is behind the latest and, if so, surfaces a one-line nudge at session start (e.g. *"Dokime: 1.20.0 installed, 1.22.0 available — run /dokime:update"*). It's inform-only and never blocks: the network check has a 2-second timeout and fails silent (offline or up-to-date → nothing shown). Staying current also keeps the evolution loop's signal clean — submissions tagged with a current version make the per-rule recurrence measurement accurate.

## Skills

| Skill | Description |
|-------|-------------|
| `/dokime:workflow` | Run the full Dokime development workflow on a task or ticket |
| `/dokime:review` | Run a Dokime code review on a PR branch — verdicts each acceptance criterion, runs Pass 3 (Rule 11, Rule 12, specialized agents), filters issues by confidence, produces Bitbucket-flavored inline-comment blocks |
| `/dokime:evolve` | Submit a workflow lesson learned for review — captures what the workflow caught or missed in a session so the maintainer can promote it across all users |
| `/dokime:triage` | Maintainer-only — walk through the evolution feed (pending entries from `/dokime:evolve`), mark each as promoted / reviewed / dismissed. Requires `DOKIME_MAINTAINER_KEY` in env or `~/.claude/dokime-credentials.json` |
| `/dokime:evolution-signal` | Maintainer-only — read-only recurrence report over the evolution feed: per failure_class total, distinct cross-dev submitters, per-version breakdown, first→last version. Informs a triage walk; doesn't act. Requires `DOKIME_MAINTAINER_KEY` |
| `/dokime:update` | Pull the latest version and reinstall the plugin |
| `/dokime:version` | Show installed version and check for updates |

## Usage

### Start a workflow

```
/dokime:workflow Implement TICKET-1234: Add user notification preferences
```

Or in conversation:

```
I want to implement this task using the Dokime workflow. Here's the task:
[paste ticket or describe the task]
```

### Update the plugin

```
/dokime:update
```

Pulls the latest from the remote repo and reinstalls. Start a fresh session after updating.

## Feature Workflow (16 Steps)

```
Step 1:  Capture Specs        → Write spec file, decisions log     → Spec saved
Step 2:  Classify             → Feature or Bug?                    → Route to workflow
Step 3:  Understand           → Central problem, ambiguities       → CHECKPOINT
Step 4:  Surface Ambiguities  → Classify, resolve, log             → CHECKPOINT
Step 5:  Evaluate Tradeoffs   → Gains, costs, alternatives         → CHECKPOINT
Step 6:  Analyze Codebase     → Patterns, reuse, blast radius      → Document findings
Step 7:  Propose Approach     → Scale assessment, plan, scope      → CHECKPOINT
Step 8:  Establish Baseline   → Fresh branch, run tests, log state → CHECKPOINT
Step 9:  Write Failing Tests  → Red (parallelize if independent)   → CHECKPOINT
Step 10: Implement            → Green (parallelize if independent) → Tests pass
Step 11: Code Quality Review  → Spec + quality + specialized agents→ CHECKPOINT
Step 12: Regression Tests     → Full suite, compare to baseline    → No new regressions
Step 13: Verify               → Human tests 1-by-1, composition    → CHECKPOINT
Step 14: Document             → READMEs, docblocks, conventions    → Docs updated
Step 15: Completion Check     → Spec vs. implementation            → CHECKPOINT
Step 16: Ship                 → PR packaging, desc, spec, QA guide → CHECKPOINT
```

**Since plugin 1.12.0:** Step 3 includes the optional UI walkthrough (default-on for user-visible-surface tickets) and the calibrated comprehension check (one discriminating question at the dev's target Bloom level — computed per-card). Step 7 includes a just-in-time review of relevant cards from the per-dev knowledge model (narrow + broad relevance, capped at 3, lowest-box first), with each review feeding back into the card via `capture-card`. Step 15 includes a `dokime-cross-check` audit — passed-checkpoint count vs. recorded count, so any silent miss of `dokime-checkpoint` becomes visible.

## Bug Fix Workflow (B1-B15)

Branches from Step 2 when the ticket is a bug. Diagnosis-first — the ambiguity isn't "what should we build?" but "why is this broken?"

```
Step 1:  Capture Specs        → Write spec file                    → Spec saved
Step 2:  Classify             → Bug → route here                   → Route to bug workflow
Step B1: Capture the Bug      → Repro steps, expected, actual      → Bug documented
Step B2: Understand           → Central problem, initial hypotheses→ CHECKPOINT
Step B3: Reproduce            → Trigger bug on local               → CHECKPOINT
Step B4: Root Cause           → Trace execution, diagnose          → CHECKPOINT (critical)
Step B5: Desired Behavior     → What should happen? Ambiguities?   → CHECKPOINT
Step B6: Blast Radius & Fix   → What could break? Propose fix      → CHECKPOINT
Step B7: Establish Baseline   → Fresh branch, run tests, log state → CHECKPOINT
Step B8: Red                  → Test that reproduces the bug        → CHECKPOINT
Step B9: Green                → Fix the bug                        → Test passes
Step B10: Code Quality Review → Fix correctness + code quality     → CHECKPOINT
Step B11: Regression Tests    → Full suite, compare to baseline    → No new regressions
Step B12: Verify              → Bug gone, nothing else broke       → CHECKPOINT
Step B13: Document            → Docs if behavior changed           → Docs updated
Step B14: Completion Check    → Spec vs. fix                       → CHECKPOINT
Step B15: Ship                → PR, repro test, QA guide           → CHECKPOINT
```

**Since plugin 1.7.0:** Step B4 includes an escaped-ambiguity check — when a bug's root cause is an ambiguity an earlier Step 4 / B5 *should have* surfaced (not an implementation error, not an unforeseeable interaction), the workflow records it (`record-escaped-ambiguity`) attributed back to the originating ticket. This is the workflow's slow signal: which tickets let which ambiguities through.

Every step with a CHECKPOINT requires human confirmation before proceeding.

## Project Configuration

Create `.claude/dokime-config.json` in your project root:

```json
{
  "spec_path": "~/.claude-specs/myproject",
  "test_command": "php artisan test",
  "test_filter_flag": "--filter",
  "lint_command": "pint",
  "static_analysis_command": "phpstan analyse",
  "codesniffer_command": "phpcs",
  "base_branch": "develop",
  "stakeholders": ["Product Owner", "Tech Lead", "QA"],
  "specialized_agents": [],
  "style_guides": [
    "~/.claude/dokime/style-guides/conditionals.md",
    "~/.claude/dokime/style-guides/self-documenting-code.md"
  ]
}
```

The plugin reads this file to customize paths, commands, and team-specific settings without modifying the core workflow.

### Style guides

`style_guides` is an optional array of file paths pointing at house-style documents the workflow should apply to this codebase. It works exactly like `specialized_agents` — you store the documents somewhere and list them in the config; the plugin reads whatever you point at and ships no rules, no content, and no default location of its own. dokime stays an abstract tool; every codebase supplies its own rules.

**Where to store the documents.** Keep them outside the repo, in an untracked, user-global library so multiple codebases can share canonical files and a client repo gains no new tracked files:

```
~/.claude/dokime/style-guides/
├── conditionals.md
├── self-documenting-code.md
└── …add topics as you write them
```

Paths may be absolute or use a leading `~`. Topic-per-file is the intended granularity — one document per concern (conditionals, comments, error handling, …).

**How it's applied.** The dev workflow reads every declared guide at **Step 6** (feature) and **Step B10** (bug fix) as a first-class project style source. The review skill (`/dokime:review`) reads them too, but — per Bacchelli — flags only clear, material violations of an explicitly stated rule, never nits. On a direct conflict between a declared guide and an inline `CLAUDE.md` style section, the inline source wins (it's more specific to the repo) and the conflict is surfaced rather than silently resolved.

**Per-codebase independence.** Config resolves by working directory, so each codebase applies its own list. A backend and its SPA — or several services in a monorepo-of-repos — each keep their own `.claude/dokime-config.json` with their own `style_guides`. They can share files (point at the same `conditionals.md`), select different subsets, or use language-specific variants (`conditionals.php.md` vs `conditionals.ts.md`); the choice is per config file. Omit the field entirely and behavior is unchanged.

## When to Use

**Full workflow:**
- Ambiguous specs
- Business logic with multiple valid interpretations
- Financial transactions, money movement
- Architecture decisions that are hard to reverse

**Abbreviated (Steps 1-8, then skip to Step 10):**
- CSS / cosmetic changes
- Config changes
- Copy / text updates
- Clear specs with no ambiguity

**Bug fix workflow:**
- Something that should work but doesn't
- Unclear symptoms (treat as bug until root cause says otherwise)

**Steps 1-8 always apply.** The question is whether you write tests first (Step 9) or skip straight to implementation (Step 10).

## Evidence

Tested in controlled experiments (4 peiraí, Feb 2026) and production brownfield tickets (Feb 2026 onward):

- Ambiguity surfacing catches 12-16 silent assumptions per ticket vs 0 for freestyle
- Scale heuristic correctly triages complexity every time
- Composition check catches integration bugs that unit tests miss
- Verify step catches bugs that automated tests can't (label collisions, UI placement errors)
- "Trace before you log" saves significant debugging time on bug fixes
- Production-tested daily on Laravel tickets with team stakeholders
- **v2 v1 build (May 2026):** the workflow was used to specify and implement its own re-founding — 8 tickets + 1 backlog item shipped via `dokime:workflow`, surfacing 14 evolution observations from dogfooding (subsequently triaged). The measurement spine and per-dev knowledge model added in this build mean the workflow now sees its own effects, teaches its operator at decision points, and audits whether instrumentation actually fired

## Philosophy

*Dokime* (Greek: "proven character through trial"). The workflow forces contact with reality at every step — the same principle that makes TDD work, that makes sparring work, that makes the scientific method work. Systems that survive contact with reality are worth trusting. Systems that avoid it are not.

### Why Checkpoints — The 2026 Argument

Lawrence Paulson (co-architect of the Isabelle theorem prover) gave a talk in early 2026 that articulates this plugin's thesis in its strongest form. After Josef Urban demonstrated that Claude + ChatGPT could formalize an entire topology textbook overnight — 130,000 lines of machine-checked proof for ~$150 — Paulson argued that **a kernel's acceptance of LLM output is one bit of information.** It tells you the symbols type-check. It does not tell you the theorem matches intent, the construction is clean, or that any human understands it.

His prescription is exactly what this workflow enforces: **interactive, not batch. Continuous human contact. Read every line you retain.** Dokime's CHECKPOINTs are the programming-workflow analogue of Paulson's "don't walk away from the LLM while it writes 130k lines you'll never read."

- Full case study: `~/Documents/Dokime/docs/case-studies/paulson-ai-formalization-2026.md`
- Paulson's line worth carrying: *"I don't think LLMs do worry."* Your job is to do the worrying the LLM can't.

---

*"Working code" and "correct code" are not the same thing. This workflow closes the gap.*
