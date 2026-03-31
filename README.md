# Dokime

A structured development workflow for AI-assisted software engineering with human checkpoints at every phase.

**Author:** Virgil Anderson
**License:** All rights reserved

## What It Does

Dokime is a 15-step TDD workflow that surfaces silent assumptions before they become code. AI coding tools make reasonable decisions invisibly — the right architecture, the right edge case handling, the right business logic interpretation. The code works. But nobody knows *why* it was built that way.

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

## Usage

```
/dokime:workflow Implement TICKET-1234: Add user notification preferences
```

Or in conversation:

```
I want to implement this task using the Dokime workflow. Here's the task:
[paste ticket or describe the task]
```

## Updating

```bash
claude plugin marketplace update dokime
claude plugin update dokime
```

## The 15 Steps

```
Step 1:  Capture Specs        → Write spec file, decisions log
Step 2:  Understand           → Central problem, ambiguities
Step 3:  Surface Ambiguities  → Classify, resolve, log
Step 4:  Evaluate Tradeoffs   → Gains, costs, alternatives
Step 5:  Analyze Codebase     → Patterns, reuse, blast radius
Step 6:  Propose Approach     → Scale assessment, plan, scope
Step 7:  Establish Baseline   → Fresh branch, run tests, log state
Step 8:  Write Failing Tests  → Red (parallelize if independent)
Step 9:  Implement            → Green (parallelize if independent)
Step 10: Code Quality Review  → Spec + quality + specialized agents
Step 11: Regression Tests     → Full suite, compare to baseline
Step 12: Verify               → Human tests 1-by-1, composition
Step 13: Document             → READMEs, docblocks, conventions
Step 14: Completion Check     → Spec vs. implementation
Step 15: Ship                 → PR, final spec check, QA guide
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
  "base_branch": "develop",
  "stakeholders": ["Product Owner", "Tech Lead", "QA"],
  "specialized_agents": []
}
```

The plugin reads this file to customize paths, commands, and team-specific settings without modifying the core workflow.

## When to Use

**Full workflow (all 15 steps):**
- Ambiguous specs
- Business logic with multiple valid interpretations
- Financial transactions, money movement
- Architecture decisions that are hard to reverse

**Abbreviated (Steps 1-7, then skip to Step 9):**
- CSS / cosmetic changes
- Config changes
- Copy / text updates
- Clear specs with no ambiguity

**Steps 1-7 always apply.** The question is whether you write tests first (Step 8) or skip straight to implementation (Step 9).

## Evidence

Tested in controlled experiments (4 peiraí, Feb 2026) and production brownfield tickets (Feb-Mar 2026):

- Ambiguity surfacing catches 12-16 silent assumptions per ticket vs 0 for freestyle
- Scale heuristic correctly triages complexity every time
- Composition check catches integration bugs that unit tests miss
- Production-tested daily on Laravel tickets with team stakeholders

## Philosophy

*Dokime* (Greek: "proven character through trial"). The workflow forces contact with reality at every step — the same principle that makes TDD work, that makes sparring work, that makes the scientific method work. Systems that survive contact with reality are worth trusting. Systems that avoid it are not.

---

*"Working code" and "correct code" are not the same thing. This workflow closes the gap.*
