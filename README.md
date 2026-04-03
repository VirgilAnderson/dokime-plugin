# Dokime

A structured development workflow for AI-assisted software engineering with human checkpoints at every phase.

**Author:** Virgil Anderson
**License:** All rights reserved

## What It Does

Dokime is a TDD workflow that surfaces silent assumptions before they become code. AI coding tools make reasonable decisions invisibly — the right architecture, the right edge case handling, the right business logic interpretation. The code works. But nobody knows *why* it was built that way.

Dokime forces every decision into the open where a human can approve, correct, or learn from it. The result is a codebase that humans can actually maintain.

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

## Skills

| Skill | Description |
|-------|-------------|
| `/dokime:workflow` | Run the full Dokime development workflow on a task or ticket |
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
Step 16: Ship                 → PR, final spec check, QA guide     → CHECKPOINT
```

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
  "specialized_agents": []
}
```

The plugin reads this file to customize paths, commands, and team-specific settings without modifying the core workflow.

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

Tested in controlled experiments (4 peiraí, Feb 2026) and production brownfield tickets (Feb-Apr 2026):

- Ambiguity surfacing catches 12-16 silent assumptions per ticket vs 0 for freestyle
- Scale heuristic correctly triages complexity every time
- Composition check catches integration bugs that unit tests miss
- Verify step catches bugs that automated tests can't (label collisions, UI placement errors)
- "Trace before you log" saves significant debugging time on bug fixes
- Production-tested daily on Laravel tickets with team stakeholders

## Philosophy

*Dokime* (Greek: "proven character through trial"). The workflow forces contact with reality at every step — the same principle that makes TDD work, that makes sparring work, that makes the scientific method work. Systems that survive contact with reality are worth trusting. Systems that avoid it are not.

---

*"Working code" and "correct code" are not the same thing. This workflow closes the gap.*
