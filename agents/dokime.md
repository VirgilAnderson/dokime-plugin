# Dokime Workflow

**Author:** Virgil Anderson
**Created:** February 2026
**Last Updated:** March 31, 2026
**License:** All rights reserved. This workflow is the intellectual property of Virgil Anderson.

---

A structured workflow for implementing software using Test-Driven Development with human checkpoints.

## What This Workflow Is

A **communication protocol** between an AI that makes good-but-silent decisions and a human who needs to see those decisions before they become code.

You already write good code. That's not the problem. The problem is that "working code" and "correct code" are not the same thing. Working code runs, passes tests, has no bugs. Correct code does what the user *intended*. The gap between the two is silent assumptions — architectural decisions, business logic interpretations, edge case handling — that you make reasonably but invisibly.

In controlled experiments (4 peiraí, Feb 2026), freestyle TDD and this workflow both produced working code every time. But on ambiguous specs, freestyle silently decided what "correct" means 12-16 times per problem. This workflow surfaces those decisions so the human can approve or correct them *before* code ships. That's the entire value proposition.

**Use this workflow when:**
- The spec is ambiguous (most real-world tickets)
- Business logic has multiple reasonable interpretations
- Architecture decisions are hard to reverse
- The human needs to audit decisions (team projects, context loss)

**Skip this workflow when:**
- The spec is fully defined with no ambiguity
- All sub-problems COLLAPSE (known patterns, known interactions)
- The solution is disposable (prototype, experiment, one-off)
- Speed matters more than decision auditability

## Cost

More time per ticket upfront compared to freestyle development. Less total time when you account for the rework, debugging, QA cycles, and incident response that undisciplined development creates downstream.

AI-assisted development creates a specific risk: working code that nobody understands. The AI makes reasonable architectural choices, business logic interpretations, and edge case decisions — silently. The code runs. The tests pass. But the humans who maintain it don't know why it was built that way, what assumptions it encodes, or what it intentionally doesn't do. That's a black box, and black boxes are technical debt that compounds invisibly.

This workflow forces every decision into the open where a human can approve, correct, or learn from it. The upfront cost is decision visibility. The return is a codebase that humans can actually maintain — and bugs caught before they ship instead of after.

---

## Spec File

Every task gets a spec file. This is the primary artifact — more important than the code for ambiguous problems.

```
~/.claude-specs/{project}/{ticket-or-task}-specs.md
```

The spec file captures **decisions**, not just requirements. "Chose X because Y." "Surfaced ambiguity Z — human decided W." "Killed approach A because B." This file survives context loss. The code doesn't tell you why it was built that way. The spec file does.

---

## Step 1: Capture Specs

- Parse the ticket/task requirements
- Create the spec file
- Write to the spec file:
  - Task ID and title
  - Full requirements/description
  - Acceptance criteria
  - Constraints (performance, backward compatibility, deployment)
  - Any linked resources, screenshots, or context
- Inform the human where the spec file is saved
- **This file will be referenced throughout the workflow and at final verification**

---

## Step 2: Understand the Ticket

- Read and summarize the ticket requirements
- Identify acceptance criteria
- Read the relevant code — don't guess what it does
- Identify which files, services, and models are involved
- **Name the central problem** — what is the ONE core tension this ticket is solving? The central problem constrains the approach. Name it before decomposing.
- List any ambiguities or questions (see Step 3 for what counts)

**CHECKPOINT: Get human confirmation before proceeding.**

---

## Step 3: Surface Ambiguities

**This is the most valuable step in the workflow. Do not rush it.**

Before touching code, answer: *Where could a reasonable engineer silently make the wrong choice?*

For each ambiguity:
1. **State the question** — what's unclear?
2. **State why it matters** — what breaks if the wrong choice is made?
3. **Label it**: Is this a **business decision** (stakeholder must decide) or a **technical decision** (engineer can make a reasonable choice and document it)?
4. **Propose a default** for technical decisions

**What counts as an ambiguity:**
- Multiple valid interpretations of the same requirement
- Boundary conditions not specified (e.g., "minimum" — before or after calculations?)
- Interaction semantics between features (does feature A affect feature B?)
- Error handling behavior not specified
- Data model choices with downstream consequences
- Application order affecting outcomes (e.g., discount stacking, rule priority)
- Anything where "reasonable default" ≠ "what the business wants"

Post business-decision ambiguities to stakeholders. **DO NOT PROCEED until questions are answered or explicitly deferred.**

Document ALL answers and decisions in the spec file.

**CHECKPOINT: Human confirms all ambiguities resolved or intentionally deferred.**

---

## Step 4: Evaluate Tradeoffs

Ambiguities are resolved — now evaluate the tradeoffs of those decisions before committing to an approach.

For each significant decision from Step 3:
1. **What are we gaining?** What does this decision optimize for?
2. **What are we giving up?** What does this decision cost — in complexity, performance, migration effort, future flexibility?
3. **What are the alternatives?** Name at least one other reasonable path and why we're not taking it.
4. **Is this reversible?** If we're wrong, how hard is it to change later?

Not every decision needs a full tradeoff analysis. Focus on the ones where the cost of being wrong is high or the decision is hard to reverse.

Log tradeoff evaluations to the spec file.

**CHECKPOINT: Human confirms tradeoffs are acceptable.**

---

## Step 5: Analyze Codebase

**Read the project first:**
- Read any README, CLAUDE.md, contributing guide, or code style guide
- Identify coding standards, conventions, and architectural patterns the project follows
- Note the testing conventions — how are tests organized, named, what factories/fixtures exist?

**Search for reusable code:**
- Search for existing services, classes, traits, helpers related to this feature
- Can you reuse an existing service class? Extend one? Implement an existing interface?
- Are there base classes, abstract classes, or contracts that this feature should follow?
- What shared components exist that this feature should integrate with rather than duplicate?
- **Stay DRY** — if similar logic exists elsewhere, extract and reuse rather than duplicate

**Assess the blast radius:**
- Identify files that will need modification
- Check for shared components — who else uses them?
- Look for similar implementations to follow as a pattern

**Surface new ambiguities:**
- Does existing code handle this differently than the ticket implies?
- Does the codebase contradict the spec? If so, go back to Step 3

Document the relevant files, patterns, reusable components, and standards found.

---

## Step 6: Propose Approach

**Assess the scale first.** For each sub-problem in the ticket:
- Q1: "Do I know which pattern governs this?"
- Q2: "Do I know how it interacts with the other parts?"
- Both yes → **COLLAPSE.** Known problem, known interactions — compress the workflow. Write test, implement, move on.
- Q1 no → Research the right approach first.
- Q2 no → **FULL LOOP.** Unknown interactions — need careful testing to discover them.

**ALL COLLAPSE → FAST PATH.** If every sub-problem is known, skip ceremony. Focus on edge cases.

Based on patterns found, propose implementation approach:
- List specific files to modify and what changes each needs
- Identify any new files needed
- Identify risks — what could break?
- State what this change intentionally does NOT do (scope boundaries)
- List what tests will be written

**CHECKPOINT: Get human approval on approach before writing any code.**

---

## Step 7: Establish Baseline

**Start clean. Know what's broken before you touch anything.**

1. If you aren't on a clean branch for the ticket create and checkout a fresh branch from the base branch (e.g., `develop`). Look at existing branch structure and follow it.
2. Verify no uncommitted changes
3. Run the full test suite before writing any code
4. Log the results:
   - How many tests pass?
   - How many tests fail? Which ones?
   - Are there any skipped or incomplete tests?
5. If tests are already failing, document them in the spec file as **pre-existing failures** — these are not your responsibility, but you need to know they exist so you don't waste time debugging them later

This is your baseline. After implementation, any new failures are yours. Any pre-existing failures are not. Without this step, you can't tell the difference.

**CHECKPOINT: Human confirms baseline is established and any pre-existing failures are noted.**

---

## Step 8: Write Failing Tests (Red) — Parallelize Where Possible

- Write failing tests that verify the acceptance criteria
- Tests should cover:
  - Happy path scenarios
  - Edge cases
  - Error conditions (if applicable)
- Run tests to confirm they fail as expected
- Show test failure output to human

Test names should read as sentences. If someone reads just the test names, they should understand what the system does.

If a test passes before you write the implementation, the test isn't testing anything — fix it.

**Parallel subagents:** If the plan from Step 6 identified truly independent sub-problems, dispatch separate agents to write tests for each simultaneously. Independent means: no shared state, no shared files, no interaction effects. If in doubt, do them sequentially — false independence creates merge conflicts and interaction bugs.

**CHECKPOINT: Failing tests reviewed. Do they cover the right behavior? Are edge cases included? Do they match the spec from Step 1?**

---

## Step 9: Implement (Green)

- Write minimum code to make tests pass
- Follow existing patterns identified in Step 5
- Run tests after each significant change
- Continue until all tests pass
- **Approach compliance**: Before presenting, compare what was built against what was approved in Step 6. Note any deviations and why.

**Parallel subagents:** Same rule as Step 8. If sub-problems are truly independent, dispatch agents in parallel. Each agent implements its sub-problem and runs its tests. Integrate and run the full suite after all agents complete.

---

## Step 10: Code Quality Review

**Two-pass review before running the full suite.**

**Pass 1 — Spec compliance:**
- Does the implementation match what was approved in Step 6?
- Does it satisfy every acceptance criterion from Step 1?
- Are there any deviations from the plan? Are they justified?

**Pass 2 — Code quality:**
- Does the code follow the project's coding standards and conventions (identified in Step 5)?
- Is it DRY? Could any new code reuse existing services, traits, or helpers?
- Are there security concerns (injection, XSS, mass assignment, etc.)?
- Are there performance concerns (N+1 queries, missing indexes, unnecessary loops)?

**Specialized agents:** If the project has domain-specific coding agents (e.g., authorization experts, data layer experts, workflow experts, test data experts), dispatch them to review the changes in their area of expertise. Each agent reviews independently and reports findings. This catches domain-specific issues that a general review misses.

Fix any issues found before proceeding — changes made during quality review could introduce regressions, which is why regression tests come next.

**CHECKPOINT: Human confirms code quality is acceptable.**

---

## Step 11: Regression Tests

- Run full test suite to ensure no regressions
- Compare results against the baseline from Step 7 — any new failures are yours
- Run code formatter (if applicable)
- Run static analysis (if applicable)
- Fix any failures or issues
- Report results to human

---

## Step 12: Verify

**Walk through each test scenario one at a time. Do not batch.**

1. Identify all test scenarios (happy path, edge cases, error conditions, composition). Present the full list for human approval before starting.

2. For each scenario, the AI should:
   - **Set up the preconditions** — seed test data, configure state, navigate to the right page, provide exact setup steps
   - **State the expected result** — what should the human see or what should happen?
   - **Tell the human exactly what to do** — specific clicks, inputs, URLs, sequences
   - **Wait for the human to report the result** — PASS or FAIL
   - **Cross-check** — verify database state, API responses, or logs if applicable to confirm what the UI shows matches the underlying data

3. If the change involves multiple interacting components, explicitly verify the composition:
   - "What assumptions are we making about how these parts interact?"
   - "Does the combined behavior match what each part does individually?"

**Do not proceed to the next scenario until the current one is confirmed PASS or resolved.**

**On FAIL — Failure Recovery:**
1. Diagnose: Is this a code bug (fix it), an integration issue (components conflict), or a wrong approach (the architecture doesn't work)?
2. **Before refining, search.** If the fix requires heroic effort, search for a different approach that meets the requirement natively.
3. Write a failing test that reproduces the bug
4. Fix until test passes
5. Re-run full suite
6. Re-verify the failed scenario
7. Continue to the next scenario

**Every failure found in verification must produce a new test.** The bug can never silently regress.

---

## Step 13: Document

While the context is fresh — not as an afterthought.

- Update or create README documentation where appropriate
- Add docblocks to new classes and methods
- Add inline comments only where the logic is non-obvious
- Update any affected project documentation (API docs, architecture notes, etc.)
- If the change introduces a new pattern or convention, document it so future developers follow it

**The goal:** A developer encountering this code for the first time should be able to understand what it does and why without reading the spec file or the PR.

---

## Step 14: Completion Check

- Re-read spec file from Step 1
- For EACH acceptance criterion, verify it's implemented
- For EACH requirement, confirm it's addressed
- Ask yourself: "Did I build ALL portions of this ticket?"
- Create a checklist mapping each requirement to implementation evidence
- Verify documentation from Step 13 covers the changes
- Flag any gaps or partial implementations

**CHECKPOINT: Human confirms nothing was missed before proceeding.**

---

## Step 15: Ship

**PR Description:**
- Summarize changes made
- List files modified
- List shared components affected and their blast radius
- Provide PR description draft

**Final Spec Check:**
- Re-read the spec file
- Go through each acceptance criterion and confirm it was addressed
- Create a checklist showing:
  - [ ] Each requirement and whether it was implemented
  - [ ] Each acceptance criterion and whether tests cover it
  - [ ] Any items that were descoped or need follow-up
- If anything was missed, flag it for the human

**QA Testing Instructions:**
- Generate a comprehensive set of testing instructions for QA
- Include:
  - **Prerequisites**: Any setup, test data, or access needed
  - **Test Scenarios**: Step-by-step instructions for each scenario to test
  - **Expected Results**: What QA should see for each scenario
  - **Edge Cases**: Any edge cases or boundary conditions to verify
  - **Regression Checks**: Areas that might have been affected and should be spot-checked
- Format as a clear, numbered checklist that QA can work through
- Save to spec file

**Do NOT commit — human will handle git operations.**

**CHECKPOINT: Human approves and ships.**

---

## When to Use Full TDD (Steps 8-10)

| Full TDD | Abbreviated (skip to Step 9) |
|----------|-------------------------------|
| Financial transactions, money movement | CSS / cosmetic changes |
| Calculations, balances, data integrity | Copy / text updates |
| Import/export logic | Config changes |
| API endpoints that write data | Dependency bumps |
| Bug fixes (reproduce the bug as a test first) | Prototyping / spikes |

**Steps 1-7 (Spec, Understanding, Ambiguities, Tradeoffs, Analysis, Plan, Baseline) always apply.** The only question is whether you write tests first or skip straight to implementation for low-risk work.

**Rule of thumb:** If it moves money or changes data, full TDD.

---

## Bug Fix Workflow

Same steps, with one addition at Step 7:

1. **Spec** — document the bug (what happens vs. what should happen)
2. **Understand** — find the root cause in the code
3. **Plan** — propose the fix
4. **Red** — write a test that reproduces the bug (it should fail, proving the bug exists)
5. **Green** — fix the bug (test now passes)
6. **Regression** — run full suite
7. **Verify** — manual testing
8. **Document** — update docs if the fix changes behavior
9. **PR** — the test stays forever, preventing the bug from coming back

---

## AI-Assisted TDD

When using Claude Code or similar tools, the workflow doesn't change — the checkpoints still apply:

1. **Spec** — you write or the AI drafts, you review
2. **Understanding** — AI researches the codebase, surfaces what it finds, you validate
3. **Ambiguities** — AI identifies questions, classifies them (business vs technical), you decide what to surface to stakeholders
4. **Tradeoffs** — AI evaluates alternatives, you confirm the direction
5. **Analysis** — AI searches for reusable code, reads conventions, you validate
6. **Plan** — AI proposes (with scale assessment), you approve
7. **Baseline** — AI runs test suite, logs pre-existing failures, you confirm
8. **Red** — AI writes failing tests (parallel subagents for independent sub-problems), you review and run them
9. **Green** — AI implements (parallel subagents where applicable), you review and run tests
10. **Code quality** — AI runs two-pass review + specialized agents, you confirm fixes
11. **Regression** — AI runs suite, compares against baseline from Step 7, you review results
12. **Verify** — AI sets up preconditions for each scenario, you test 1-by-1
13. **Document** — AI drafts, you review for accuracy
14. **Completion check** — AI creates checklist against spec, you confirm
15. **Ship** — you own the submission

The checkpoints exist because AI can be confidently wrong. Every phase gets human review before moving forward.

---

## Rules

1. **Every checkpoint requires human confirmation** — the human is the selection pressure
2. **NEVER commit code** — human handles all git operations
3. **Write tests BEFORE implementation** — red before green
4. **Every verification failure must produce a new test** — no silent regressions
5. **Kill honestly** — if the approach requires heroic effort, search for a different one
6. **Log decisions to the spec file** — captures WHY, not just WHAT. Survives context loss.
7. **The workflow scales down** — COLLAPSE problems get compressed. Don't ceremony trivial work.
8. **Ambiguities are the primary value** — if you only do one step well, make it Step 3
9. **Ask questions EARLY** — don't start coding with unresolved ambiguities
10. **Verify completeness BEFORE shipping** — catch missing portions before QA sees it

---

## Evidence Base

**Tested on software (4 peiraí, Feb 2026).** Compared against freestyle TDD on 4 problems of increasing complexity (LRU Cache, Discount Engine, Booking System, Spreadsheet Engine).

| Finding | Evidence |
|---------|----------|
| Both approaches produce working code | 4/4 peiraí |
| Ambiguity surfacing is the #1 differentiator | 12-16 ambiguities surfaced vs 0, across 3 ambiguous specs |
| Central problem drives architecture on complex problems | Spreadsheet: dependency graph vs lazy eval |
| Composition check catches interaction bugs | IF short-circuit + dependency tracking bug |
| Scale heuristic correctly triages every time | 4/4 peiraí |

**Production-tested on real tickets (Feb-Mar 2026).** Used daily on brownfield Laravel tickets with ambiguous specs, team stakeholders, and shared components.

**The workflow's value is in the "so the human can..." clause:**
- Central Problem → names what you're optimizing for — *so the human can disagree*
- Ambiguity Surfacing → lists assumptions — *so the human can correct them*
- Tradeoff Evaluation → makes costs explicit — *so the human can weigh them*
- Scale Heuristic → identifies when to skip ceremony — *so the human doesn't waste time*
- Composition Check → forces interaction analysis — *so subtle bugs get caught*
- Decision Log → persists choices — *so they survive context loss*

Remove the human, and you're adding tokens for marginal coverage. The human is the point.

---

## Workflow Evolution

**This workflow is subject to peira.** As you use it, log what works and what doesn't — directly in this document.

After each significant use, note:
- **What earned its keep** — which steps caught real problems or saved real time
- **What was overhead** — which steps added ceremony without value for that type of ticket
- **What's missing** — friction points the workflow doesn't address
- **What changed** — any modifications made and why

The log stays with the workflow so future users (and future you) inherit the lessons. A workflow that doesn't evolve from its own evidence is kenpo.

### Evolution Log

| Date | Project | Observation | Action Taken |
|------|---------|-------------|--------------|
| 2026-02 | Dokime (4 peiraí) | Ambiguity surfacing is the #1 value; 12-16 caught vs 0 freestyle | Elevated as the most important step |
| 2026-02 | Dokime (4 peiraí) | Scale heuristic correctly triages every time; prevents over-processing | Added COLLAPSE/FULL LOOP to approach step |
| 2026-02 | Dokime (4 peiraí) | Composition check caught IF short-circuit + dependency tracking bug | Added composition verification to verify step |
| 2026-02 | Dokime (4 peiraí) | Pre-flight (branch check) is overhead for greenfield | Removed as a standalone step; part of normal dev hygiene |
| 2026-02-03 | Dokime | Completion check + reverify catch partial implementations | Kept both — redundancy is intentional for completeness |
| 2026-03-31 | Dokime | Foundation version merged with Dokime enhancements | Consolidated into one canonical document |
| 2026-03-31 | Dokime | Steps need explicit tradeoff evaluation after ambiguity resolution | Added Step 4: Evaluate Tradeoffs |
| 2026-03-31 | Dokime | Documentation should happen while context is fresh, not as afterthought | Added Step 11: Document |
| 2026-03-31 | Dokime | Step numbering with decimals (1.5, 7.5) is confusing | Renumbered all steps sequentially 1-13 |
| 2026-03-31 | Dokime | Codebase analysis should explicitly look for reusable code, style guides, READMEs | Enhanced Step 5 with DRY focus and project conventions |
| 2026-03-31 | Dokime | "Better code" framing misses the real risk of AI development — black box maintainability | Rewrote Cost section to address decision visibility and human understanding |
| 2026-03-31 | Dokime | Need to know test suite state before starting work — can't tell what you broke vs pre-existing | Added Step 7: Establish Baseline (fresh branch + full test run + log failures) |
| 2026-03-31 | Dokime | Independent sub-problems can be parallelized for speed | Added parallel subagent guidance to Steps 8-9 |
| 2026-03-31 | Dokime | General code review misses domain-specific issues | Added Step 12: Code Quality Review with two-pass review + specialized agent dispatch |
| 2026-03-31 | Dokime | Tradeoffs of resolved ambiguities need explicit evaluation before committing to approach | Added Step 4: Evaluate Tradeoffs |

---

## Usage

```
I want to implement this task using the Dokime TDD workflow. Here's the task:
[DESCRIBE THE TASK OR PASTE THE TICKET]

Follow the Dokime TDD workflow - start with Step 1.
```

---

## Quick Reference

```
Step 1:  Capture Specs        → Write spec file, decisions log     → Spec saved
Step 2:  Understand           → Central problem, ambiguities       → CHECKPOINT
Step 3:  Surface Ambiguities  → Classify, resolve, log             → CHECKPOINT
Step 4:  Evaluate Tradeoffs   → Gains, costs, alternatives         → CHECKPOINT
Step 5:  Analyze Codebase     → Patterns, reuse, blast radius      → Document findings
Step 6:  Propose Approach     → Scale assessment, plan, scope      → CHECKPOINT
Step 7:  Establish Baseline   → Fresh branch, run tests, log state → CHECKPOINT
Step 8:  Write Failing Tests  → Red (parallelize if independent)   → CHECKPOINT
Step 9:  Implement            → Green (parallelize if independent) → Tests pass
Step 10: Code Quality Review  → Spec + quality + specialized agents→ CHECKPOINT
Step 11: Regression Tests     → Full suite, compare to baseline    → No new regressions
Step 12: Verify               → Human tests 1-by-1, composition   → CHECKPOINT
Step 13: Document             → READMEs, docblocks, conventions    → Docs updated
Step 14: Completion Check     → Spec vs. implementation            → CHECKPOINT
Step 15: Ship                 → PR, final spec check, QA guide     → CHECKPOINT
```

---

*"Working code" and "correct code" are not the same thing. This workflow closes the gap.*

*© 2026 Virgil Anderson. All rights reserved.*
