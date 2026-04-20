# Dokime Workflow

**Author:** Virgil Anderson
**Created:** February 2026
**Last Updated:** April 3, 2026
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

**Related argument from the theorem-proving world.** Lawrence Paulson (Isabelle) made the same case in early 2026 for AI-assisted mathematics: when Claude can write 130,000 lines of kernel-checked proof overnight, the kernel's "accepted" verdict is *one bit of information* — necessary but drastically insufficient. Paulson's prescription — interactive, not batch; read every line; make it your own — is exactly what this workflow's CHECKPOINTs enforce for code. See `~/Documents/Dokime/docs/case-studies/paulson-ai-formalization-2026.md` for the full argument. One line worth carrying: *"I don't think LLMs do worry."* The workflow exists so a human does.

---

## Spec File

Every task gets a spec file. This is the primary artifact — more important than the code for ambiguous problems.

```
~/.claude-specs/{project}/{ticket-or-task}-specs.md
```

The spec file captures **decisions**, not just requirements. "Chose X because Y." "Surfaced ambiguity Z — human decided W." "Killed approach A because B." This file survives context loss. The code doesn't tell you why it was built that way. The spec file does.

---

## Step 1: Capture Specs

- **Scan the Evolution Log** (bottom of this document) for recent entries — lessons from the last session may apply to this ticket. The log is operational, not archival; entries written in the morning can save work the same afternoon.
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

## Step 2: Classify the Ticket

Determine what kind of work this is:

- **Feature / Enhancement** → Continue with the Feature Workflow (Steps 3-15 below)
- **Bug Fix** → Switch to the Bug Fix Workflow (see section below)

**How to tell:** If the ticket describes something that *should work but doesn't*, it's a bug. If it describes something that *doesn't exist yet*, it's a feature. If it's unclear, treat it as a bug until root cause analysis reveals otherwise — bugs with unclear symptoms sometimes turn out to be missing features, and you'll catch that at Step B5 (Desired Behavior).

---

# Feature Workflow

## Step 3: Understand the Ticket

- Read and summarize the ticket requirements
- Identify acceptance criteria
- Read the relevant code — don't guess what it does
- Identify which files, services, and models are involved
- **Name the central problem** — what is the ONE core tension this ticket is solving? The central problem constrains the approach. Name it before decomposing.
- List any ambiguities or questions (see Step 3 for what counts)

**CHECKPOINT: Get human confirmation before proceeding.**

---

## Step 4: Surface Ambiguities

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

## Step 5: Evaluate Tradeoffs

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

## Step 6: Analyze Codebase

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

## Step 7: Propose Approach

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

## Step 8: Establish Baseline

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

## Step 9: Write Failing Tests (Red) — Parallelize Where Possible

- Write failing tests that verify the acceptance criteria
- Tests should cover:
  - Happy path scenarios
  - Edge cases
  - Error conditions (if applicable)
- Run tests to confirm they fail as expected
- Show test failure output to human

Test names should read as sentences. If someone reads just the test names, they should understand what the system does.

If a test passes before you write the implementation, the test isn't testing anything — fix it.

**Parallel subagents:** If the plan from Step 7 identified truly independent sub-problems, dispatch separate agents to write tests for each simultaneously. Independent means: no shared state, no shared files, no interaction effects. If in doubt, do them sequentially — false independence creates merge conflicts and interaction bugs.

**CHECKPOINT: Failing tests reviewed. Do they cover the right behavior? Are edge cases included? Do they match the spec from Step 1?**

---

## Step 10: Implement (Green)

- Write minimum code to make tests pass
- Follow existing patterns identified in Step 5
- Run tests after each significant change
- Continue until all tests pass
- **Approach compliance**: Before presenting, compare what was built against what was approved in Step 7. Note any deviations and why.

**Visual smoke test:** If the change affects UI, load it in the browser before proceeding. Confirm the output is in the right place, the right component, the right page. Code that passes tests but renders in the wrong location is not green — it's red in a way tests don't catch.

**Parallel subagents:** Same rule as Step 8. If sub-problems are truly independent, dispatch agents in parallel. Each agent implements its sub-problem and runs its tests. Integrate and run the full suite after all agents complete.

---

## Step 11: Code Quality Review

**Two-pass review before running the full suite.**

**Pass 1 — Spec compliance:**
- Does the implementation match what was approved in Step 7?
- Does it satisfy every acceptance criterion from Step 1?
- Are there any deviations from the plan? Are they justified?

**Pass 2 — Code quality:**
- Does the code follow the project's coding standards and conventions (identified in Step 5)?
- Is it DRY? Could any new code reuse existing services, traits, or helpers?
- Is the code structurally organized — responsibilities in the right classes, file/namespace structure matching the feature boundary? Would a new developer find the right file on the first try? (Distinct from conventions: this is *discoverability and maintainability*, not style. Tests won't catch it — working code in the wrong place still works.)
- Are there security concerns (injection, XSS, mass assignment, etc.)?
- Are there performance concerns (N+1 queries, missing indexes, unnecessary loops)?

**Specialized agents:** If the project has domain-specific coding agents (e.g., authorization experts, data layer experts, workflow experts, test data experts), dispatch them to review the changes in their area of expertise. Each agent reviews independently and reports findings. This catches domain-specific issues that a general review misses.

Fix any issues found before proceeding — changes made during quality review could introduce regressions, which is why regression tests come next.

**CHECKPOINT: Human confirms code quality is acceptable.**

---

## Step 12: Regression Tests

- Run full test suite to ensure no regressions
- Compare results against the baseline from Step 8 — any new failures are yours
- Run **all** configured quality tools — not just the formatter. Formatting tools (e.g., Pint, Prettier) catch style issues. Static analysis and codesniffer tools (e.g., PHPStan, PHPCS, ESLint, `tsc --noEmit`) catch structural issues — trailing commas, docblock annotations, type errors, unused imports. Running one without the other leaves a gap.
- Fix any failures or issues
- Report results to human

---

## Step 13: Verify

**Walk through each test scenario one at a time. Do not batch.**

Verification catches what automated tests can't — **UI/behavior issues** (layout, interactions, real user flow) *and* **infrastructure/config issues** (unconfigured services, disk/S3 gaps, environment drift masked by `Storage::fake()` or similar). Both surface here.

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

## Step 14: Document

While the context is fresh — not as an afterthought.

- Update or create README documentation where appropriate
- Add docblocks to new classes and methods
- Add inline comments only where the logic is non-obvious
- Update any affected project documentation (API docs, architecture notes, etc.)
- If the change introduces a new pattern or convention, document it so future developers follow it

**The goal:** A developer encountering this code for the first time should be able to understand what it does and why without reading the spec file or the PR.

---

## Step 15: Completion Check

- Re-read spec file from Step 1
- For EACH acceptance criterion, verify it's implemented
- For EACH requirement, confirm it's addressed
- Ask yourself: "Did I build ALL portions of this ticket?"
- **Map each acceptance criterion to specific file(s) and method(s)** that implement it — not just "yes this was handled." Vague completion checks are how requirements silently vanish.
- **Cross-repo criteria are a known failure mode.** When an acceptance criterion touches multiple repositories, name each repo's contribution explicitly. It's easy to mentally check off a criterion against one repo's PR while the corresponding change in the other repo never got written.
- Verify documentation from Step 13 covers the changes
- Flag any gaps or partial implementations

**CHECKPOINT: Human confirms nothing was missed before proceeding.**

---

## Step 16: Ship

**PR Packaging (decide before drafting):**
- Is the commit history clean? Squash WIP / merge / fix-fix-fix noise if appropriate — reviewers read commits, not just the final diff.
- Does the diff include infrastructure or preparatory changes that aren't part of this feature (schema dumps, `.env.testing` edits, unrelated refactors)? Consider splitting them into separate PRs — reviewer attention is finite, and mixed PRs are harder to review and revert.
- Is the diff scoped to what a reviewer actually needs to see? Minimize noise.

**PR Description:**
- Summarize changes made
- List files modified
- List shared components affected and their blast radius
- Provide PR description draft

**Final Spec Check:**
- Re-read the spec file
- Use Step 15's criterion→file→method mapping as the source of truth — verify the map is complete, not just that criteria "feel addressed"
- Create a checklist showing:
  - [ ] Each requirement, the file(s)/method(s) that implement it, and whether it's complete
  - [ ] Each acceptance criterion and whether tests cover it
  - [ ] For cross-repo criteria: each repo's contribution named explicitly
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

**Evolution check:** If this session produced any lessons — steps that caught real problems, steps that were unnecessary overhead, missing coverage, or process violations that were caught and corrected — summarize the candidate observations and ask: *"This session produced observations that could improve the workflow for all Dokime users. Want to submit them via `/dokime:evolve`?"* Do not submit without the human's consent.

---

## When to Use Full TDD (Steps 8-10)

| Full TDD | Abbreviated (skip to Step 10) |
|----------|-------------------------------|
| Financial transactions, money movement | CSS / cosmetic changes |
| Calculations, balances, data integrity | Copy / text updates |
| Import/export logic | Config changes |
| API endpoints that write data | Dependency bumps |
| Bug fixes (always — reproduce the bug as a test first) | Prototyping / spikes |

**Steps 1-8 (Spec, Classify, Understanding, Ambiguities, Tradeoffs, Analysis, Plan, Baseline) always apply.** The only question is whether you write tests first or skip straight to implementation for low-risk work.

**The real heuristic:** The workflow's value is proportional to the risk of *silent errors*, not proportional to lines of code changed. A one-line fix in a calculation method that groups data across repos warrants the full ceremony. A 200-line cosmetic refactor may not. Small PRs that touch shared logic, cross-repo boundaries, or pipeline stages are exactly where requirements silently vanish — because the change "looks simple" and completion checking gets lazy.

**Rule of thumb:** If it moves money or changes data, full TDD. If it's a bug, always write the reproduction test first.

---

## Bug Fix Workflow

Bugs are a different cognitive task than features. The primary challenge is **diagnosis**, not design. The ambiguity isn't "what should we build?" — it's "why is this broken?" and "what's the correct behavior?"

This workflow branches from Step 2 (Classify). Step 1 (Capture Specs) is shared.

### Step B1: Capture the Bug

Write to the spec file:
- **Steps to reproduce** — exact sequence to trigger the bug
- **Expected result** — what *should* happen
- **Actual result** — what *does* happen
- **Environment** — browser, OS, user role, data conditions, anything relevant
- **Evidence** — screenshots, error messages, stack traces, log output

If the ticket is missing reproduction steps, expected result, or actual result — ask before proceeding. You cannot diagnose what you cannot describe.

---

### Step B2: Understand the Bug

- Read and summarize the reported bug
- Read the relevant code — don't guess what it does
- Identify which files, services, and models are involved
- **Name the central problem** — what is the ONE thing that's broken? Name it before investigating.
- Note any initial hypotheses about the cause, but don't commit to one yet

**Reclassification trap:** If positive evidence suggests the bug is already resolved (e.g., logs show the system working in production), verify that the evidence matches the original report's *specific trigger* — same notification type, same program, same user role, same data conditions. Evidence from a different trigger proves a different code path works, not that the reported path works. "Twilio shows SMS working" doesn't close "badge awards aren't firing" — those are different award types on different code paths. Don't reclassify until evidence matches the report.

**CHECKPOINT: Get human confirmation that the understanding is correct before proceeding.**

---

### Step B3: Reproduce

**If you can't reproduce it, you can't verify the fix. Full stop.**

1. Follow the reported reproduction steps exactly on local
2. Confirm you see the same actual result described in B1
3. If you cannot reproduce:
   - Try variations (different data, different user, different sequence)
   - Check if the bug is environment-specific
   - Report back to the human — you need more information or the bug may be intermittent
   - **Do not proceed until you can reliably trigger the bug**
4. Document the exact reproduction steps that work (they may differ from the ticket)

**UI reproduction > feature test.** When faced with the choice between "write a feature test that simulates the bug" and "actually run the system," prefer actually running it. Feature tests are models of reality — they test the test, not the system. UI reproduction exposes real blockers (validation gates, missing data, rendering issues) that feature tests silently bypass. Blockers encountered during manual reproduction are themselves evidence that feature tests would have missed.

**Enable, don't bypass.** If you need to patch test data to reach the code path under test, ask: does this patch *enable* the path to execute, or does it *bypass* the path? Giving a record a required attribute so a form can submit is enabling (the validation isn't what you're testing). Skipping validation entirely is bypassing. Document all enablements in the spec file for audit — each one is a small divergence from production reality.

**Anti-pattern: "The code clearly shows the bug, so I don't need to run it."** Code inspection is not reproduction. When the root cause is obvious from reading the source, that certainty is exactly when you're most likely to skip this step — and exactly when skipping it does the most damage. Without local reproduction:
- B12 Verify has no anchor to compare against — you're verifying the fix against your *imagination* of the broken state, not an observed one
- You can't detect env-specific factors (config, data state, feature flags) that could invalidate the fix
- You can't visually confirm that the user experience matches what the ticket describes

The obviousness of the diagnosis is not a reason to skip reproduction — if anything, it's a warning sign that a checkpoint is about to be rationalized away.

**CHECKPOINT: Human confirms the bug is reproduced locally.**

---

### Step B4: Root Cause Analysis

**The bug you see isn't always the bug you have.**

**Trace before you log.** Read the full execution path in the code first — from entry point to output — before adding any debug logging. Understand the flow conceptually, then add targeted logging to confirm or deny your hypothesis. Iterative log-add-check cycles waste time when you don't understand the code path, the logging infrastructure, or both.

Before adding any debug output, confirm:
- Where do logs go in this environment? (file? stderr? external service?)
- How do you read them? (tail the file? docker logs? cloud dashboard?)
- What is the full code path from the trigger to the failure?

1. Read the code path end-to-end from the reproduction steps to the failure point
2. Form a hypothesis about the root cause
3. **Design an experiment to falsify or confirm the hypothesis.** State: (a) what would be observed if the hypothesis is true, (b) what would be observed if it's false, (c) where to place observation points. Then run the experiment.
4. **Place targeted logs at state-observation points** — the specific locations where internal state becomes visible (e.g., reactive model values vs. DOM values, payload contents at capture time, backend values at processing time). These are often the fastest path to definitive diagnosis once you understand the code path.
5. Identify the root cause — the specific code that produces the wrong behavior
6. Ask: **Is this the actual bug, or a symptom of something deeper?**
   - If the fix would be a band-aid over a deeper issue, name the deeper issue
   - If multiple symptoms trace to one root cause, document all of them
7. **Isolation test: "Would this fix, by itself, produce the observed behavior?"** A real bug found during code inspection is evidence, not diagnosis. If fixing it would still leave the reported symptom intact on other code paths, root cause hasn't been reached — you found a different bug. Both can be real; only one explains what the reporter experienced. Don't confuse "a true bug I found in the file" with "the root cause of the observed symptom."
8. Check for **interaction bugs** — could the fix collide with other parts of the system? (e.g., label collisions, key overwrites, shared state)
9. Document the root cause in the spec file with file paths and line numbers

**Anti-pattern: "Does this look right?"** Do not present a root cause hypothesis to the human as a "does this look right?" question. That's asking the human to be a genie — to validate your inference without evidence. Present the hypothesis, the experiment you designed, and the evidence the experiment produced. The checkpoint is "here is the evidence," not "does this look right?"

**CHECKPOINT: Human confirms root cause diagnosis *based on experimental evidence*. This is the most important checkpoint in the bug workflow — a wrong diagnosis means a wrong fix.**

---

### Step B5: Desired Behavior

What *should* happen? This is the bug-specific version of ambiguity surfacing.

- State the correct behavior clearly
- If there's ambiguity about what "correct" means (multiple reasonable interpretations), surface it now — label as business decision or technical decision, same as Step 4 in the feature workflow
- If the correct behavior contradicts other existing behavior, flag it

**CHECKPOINT: Human confirms the desired behavior.**

---

### Step B6: Blast Radius & Fix Proposal

Collapsed version of feature Steps 5-7. Bugs are usually constrained by existing architecture, so there's less design space to explore.

**Blast radius:**
- What else uses the code you're about to change?
- What could break if this fix is wrong?
- Are there shared components, traits, or services affected?

**Fix proposal:**
- Propose the specific fix with files and changes
- State what this fix intentionally does NOT change (scope boundaries)
- If multiple fix approaches exist, briefly name the alternatives and why you're recommending this one

**CHECKPOINT: Human approves the fix approach.**

---

### Step B7: Establish Baseline

Same as feature Step 8.

1. Create and checkout a fresh branch from the base branch
2. Verify no uncommitted changes
3. Run the full test suite before writing any code
4. Log results — passes, failures, skips
5. Document pre-existing failures — these are not yours

**CHECKPOINT: Human confirms baseline is established.**

---

### Step B8: Write Failing Test (Red)

Write a test that reproduces the bug. **This test should fail**, proving the bug exists in code.

- The test should encode the *desired* behavior from Step B5
- It fails because the code currently produces the *actual* (wrong) behavior
- If the test passes, either the bug isn't what you think it is or the test isn't testing the right thing — go back to B4

**CHECKPOINT: Failing test reviewed. Does it accurately reproduce the bug?**

---

### Step B9: Fix the Bug (Green)

- Write minimum code to make the test pass
- Follow existing patterns in the codebase
- Run tests after each significant change
- Continue until the reproduction test passes
- **Approach compliance**: Compare the fix against what was approved in Step B6. Note any deviations and why.
- **Check every link in the causal chain.** After the first observable change, don't stop. Trace the fix through every downstream step — from the trigger, through each intermediate state, to the final output. Partial success looks like success until you check the next link. (Example: Vue model clears correctly but `dataChange` payload still misses the field because programmatic updates don't fire DOM events — two different links in the same chain.)

**Visual smoke test:** If the fix affects UI, load it in the browser before proceeding. Confirm the bug is visually resolved and the fix renders in the right place. A fix that passes tests but looks wrong is not green.

---

### Step B10: Code Quality Review

Same as feature Step 11. Two-pass review:

**Pass 1 — Fix correctness:**
- Does the fix address the root cause identified in B4?
- Does it produce the desired behavior from B5?
- Is it scoped to the fix proposal from B6?

**Pass 2 — Code quality:**
- Does the code follow the project's coding standards?
- Are there security or performance concerns introduced by the fix?
- Is the fix minimal — does it change only what's necessary?

Fix any issues found before proceeding.

**CHECKPOINT: Human confirms code quality is acceptable.**

---

### Step B11: Regression Tests

Same as feature Step 12.

- Run full test suite
- Compare results against baseline from Step B7 — any new failures are yours
- Run **all** configured quality tools — formatter, static analysis, and codesniffer (same as feature Step 12)
- Fix any failures

---

### Step B12: Verify

**Verify the bug is fixed AND nothing else broke.**

1. Follow the reproduction steps from B3 — the bug should no longer occur
2. Verify the desired behavior from B5 is now the actual behavior
3. Check the blast radius items from B6 — do they still work?
4. If the fix changes user-facing behavior, walk through related workflows

**Do not batch. Test one scenario at a time.**

**On FAIL — same as feature workflow:** diagnose, write a failing test, fix, re-run suite, re-verify.

**CHECKPOINT: Human confirms bug is fixed and no regressions.**

---

### Step B13: Document

- Update docs if the fix changes behavior
- Add inline comments only if the fix is non-obvious (e.g., "This null check prevents X because Y can be null when Z")
- If the bug revealed a pattern that could recur, document the pattern

---

### Step B14: Completion Check

- Re-read spec file from Step B1
- Confirm: bug is reproduced as a test, root cause is fixed, desired behavior is achieved, no regressions
- Flag any related issues discovered during investigation that need separate tickets

**CHECKPOINT: Human confirms nothing was missed.**

---

### Step B15: Ship

Same as feature Step 16.

- PR description: summarize the bug, root cause, and fix
- Include the reproduction test as evidence the bug won't recur
- Generate QA testing instructions (reproduction steps + blast radius checks)

**Do NOT commit — human will handle git operations.**

**CHECKPOINT: Human approves and ships.**

**Evolution check:** If this session produced any lessons — steps that caught real problems, steps that were unnecessary overhead, missing coverage, or process violations that were caught and corrected — summarize the candidate observations and ask: *"This session produced observations that could improve the workflow for all Dokime users. Want to submit them via `/dokime:evolve`?"* Do not submit without the human's consent.

---

## AI-Assisted TDD

When using Claude Code or similar tools, the workflow doesn't change — the checkpoints still apply:

1. **Spec** — you write or the AI drafts, you review
2. **Classify** — AI proposes ticket type, you confirm (feature → Steps 3-16, bug → Steps B1-B15)
3. **Understanding** — AI researches the codebase, surfaces what it finds, you validate
4. **Ambiguities** — AI identifies questions, classifies them (business vs technical), you decide what to surface to stakeholders
5. **Tradeoffs** — AI evaluates alternatives, you confirm the direction
6. **Analysis** — AI searches for reusable code, reads conventions, you validate
7. **Plan** — AI proposes (with scale assessment), you approve
8. **Baseline** — AI runs test suite, logs pre-existing failures, you confirm
9. **Red** — AI writes failing tests (parallel subagents for independent sub-problems), you review and run them
10. **Green** — AI implements (parallel subagents where applicable), you review and run tests
11. **Code quality** — AI runs two-pass review + specialized agents, you confirm fixes
12. **Regression** — AI runs suite, compares against baseline from Step 8, you review results
13. **Verify** — AI sets up preconditions for each scenario, you test 1-by-1
14. **Document** — AI drafts, you review for accuracy
15. **Completion check** — AI creates checklist against spec, you confirm
16. **Ship** — you own the submission

For bugs, the AI-assisted flow follows the same principle — checkpoints exist because AI can be confidently wrong about diagnosis just as much as about design. The root cause checkpoint (B4) is especially critical: a wrong diagnosis from the AI means a wrong fix.

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
8. **Ambiguities are the primary value** — if you only do one step well, make it Step 4 (features) or Step B4 (bugs)
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

**Production-tested on real tickets (Feb-Apr 2026).** Used daily on brownfield Laravel tickets with ambiguous specs, team stakeholders, and shared components.

| Finding | Evidence |
|---------|----------|
| Verify step catches bugs tests can't | Unit tests passed but Verify caught label collision in controller pipeline |
| Trace before you log saves debugging time | 5 rounds of iterative logging + wrong log channel wasted cycles |
| Interaction bugs need explicit checking | Two enum cases mapping to same display label caused key overwrite |
| Visual smoke test catches placement errors | UI column added in wrong place, not caught until final verify |
| Ambiguity surfacing works on real tickets (7/7) | Caught all 7 ambiguities before code vs. reactive discovery in standard implementation |

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

| Date | Observation | Action Taken |
|------|-------------|--------------|
| 2026-02 | Ambiguity surfacing is the #1 value; 12-16 caught vs 0 freestyle | Elevated as the most important step |
| 2026-02 | Scale heuristic correctly triages every time; prevents over-processing | Added COLLAPSE/FULL LOOP to approach step |
| 2026-02 | Composition check caught IF short-circuit + dependency tracking bug | Added composition verification to verify step |
| 2026-02 | Pre-flight (branch check) is overhead for greenfield | Removed as a standalone step; part of normal dev hygiene |
| 2026-02-03 | Completion check + reverify catch partial implementations | Kept both — redundancy is intentional for completeness |
| 2026-03-31 | Foundation version merged with Dokime enhancements | Consolidated into one canonical document |
| 2026-03-31 | Steps need explicit tradeoff evaluation after ambiguity resolution | Added Step 4: Evaluate Tradeoffs |
| 2026-03-31 | Documentation should happen while context is fresh, not as afterthought | Added Step 11: Document |
| 2026-03-31 | Step numbering with decimals (1.5, 7.5) is confusing | Renumbered all steps sequentially 1-13 (later 1-16 with classify step) |
| 2026-03-31 | Codebase analysis should explicitly look for reusable code, style guides, READMEs | Enhanced Step 5 with DRY focus and project conventions |
| 2026-03-31 | "Better code" framing misses the real risk of AI development — black box maintainability | Rewrote Cost section to address decision visibility and human understanding |
| 2026-03-31 | Need to know test suite state before starting work — can't tell what you broke vs pre-existing | Added Step 8: Establish Baseline (fresh branch + full test run + log failures) |
| 2026-03-31 | Independent sub-problems can be parallelized for speed | Added parallel subagent guidance to Steps 8-9 |
| 2026-03-31 | General code review misses domain-specific issues | Added Step 11: Code Quality Review with two-pass review + specialized agent dispatch |
| 2026-03-31 | Tradeoffs of resolved ambiguities need explicit evaluation before committing to approach | Added Step 5: Evaluate Tradeoffs |
| 2026-04-03 | Bug tickets are a different cognitive task than features — diagnosis, not design | Added Step 2: Classify (routes to Feature or Bug workflow) |
| 2026-04-03 | Bugs need reproduction, root cause analysis, and blast radius as explicit steps | Added full Bug Fix Workflow (B1-B15) with dedicated checkpoints |
| 2026-04-03 | Must reproduce bug on local before any investigation or fixing | B3 (Reproduce) is mandatory gate — cannot proceed without local reproduction |
| 2026-04-03 | UI column added in wrong place — not caught until final verify | Added visual smoke test to Step 10 (Green) — check UI before code review |
| 2026-04-03 | Verify caught a bug that tests couldn't — label collision in controller pipeline | Verify step validated as essential; unit tests alone are insufficient for pipeline bugs |
| 2026-04-03 | Debugging wasted cycles on wrong log channel and iterative shotgun logging | Added "trace before you log" guidance to B4 — read code path first, confirm logging setup, then add targeted logging |
| 2026-04-03 | Label collision (two enum cases → same display label) not caught during codebase analysis | B4 now includes interaction bug check — collisions, key overwrites, shared state |
| 2026-04-03 | LOG_CHANNEL=stderr not documented — wasted time checking wrong log file | Per-project logging setup should be in CLAUDE.md or spec file |
| 2026-04-03 | Running formatter (Pint) without codesniffer (PHPCS) left structural issues uncaught — trailing commas, docblock annotations | Step 12 / B11 now explicitly requires running all quality tools, not just the formatter |
| 2026-04-09 | Step 15 Completion Check passed on ICOV3-1069 but an acceptance criterion ("CoCard section above Fasteezy") was silently dropped because the work crossed two repos — the API PR only touched `getCsvHeaders()`, while the criterion required changes to `calc()`. Criterion was mentally checked off against the Admin PR that shipped new columns, not against the calc logic that actually groups the data. Winston caught it in QA on next pass. | Step 15 now requires mapping each acceptance criterion to **specific file(s) and method(s)** that implement it, not just checking if the criterion "feels done." When a criterion touches multiple repos, each repo's contribution must be named explicitly. Cross-repo criteria are a known failure mode of completion checking. |
| 2026-04-09 | On ICOV3-1069 Pass 2, skipped B3 (Reproduce) and went straight from B2 (Understand) to B4 (Root Cause) because the missing CoCard branch was visible in code inspection. Rationalized as "I don't need to run it to confirm what I already know." Virgil caught it: *"Why did we skip B3?"* Failure mode: **clarity of diagnosis is not permission to skip reproduction**. When the code reading feels certain, that certainty is exactly the thing that makes you dangerous — it's the same failure mode as "jumping to implementation before tests," just earlier in the flow. Without local reproduction, B12 Verify has no anchor — you're comparing the fix against an *imagined* broken state, not an observed one. | B3 is non-negotiable regardless of how obvious the root cause looks in source. Added explicit anti-pattern to B3: "If you read the bug in code and feel certain, that is exactly when you most need to run it." The obviousness of the diagnosis is irrelevant to the reproduction requirement — if anything, it's a warning sign that you're about to skip a checkpoint. |
| 2026-04-09 | I presented a root cause diagnosis to the human as a "does this look right?" checkpoint question without running an experiment to verify it. The human pushed back: "I am not a genie. We need to replicate or have some kind of experimental feedback to verify." I was presenting inference as diagnosis — skipping the experimental step that makes B4 a real checkpoint instead of a rubber stamp. | B4 now requires experimental falsification before the human checkpoint. State the hypothesis, state what would be observed if true vs false, design an experiment, run it, present evidence. Not "does this look right?" — "here is the evidence." Added anti-pattern to B4. |
| 2026-04-09 | After forming a root cause hypothesis, I placed targeted console logs at four state-observation points (Vue watcher, click handler, form capture, diff request) and confirmed the exact divergence in under an hour. Static code tracing alone would have taken significantly longer and produced less confidence. | B4 now explicitly recommends placing targeted logs at state-observation points — the specific locations where internal state becomes visible — as the fastest path to definitive diagnosis once the code path is understood. |
| 2026-04-09 | After the first fix attempt, console logs showed the Vue model was clearing correctly but the diff payload still didn't include the field. I was tempted to declare partial success. Sticking with the instrumented experiment revealed that programmatic Vue updates don't fire DOM input events — so the form capture pathway still missed the change. A second fix was needed. | B9 now includes "check every link in the causal chain" — after the first observable change, trace the fix through every downstream step. Partial success looks like success until you check the next link. |
| 2026-04-09 | Given the choice between "write a feature test that simulates the bug" and "actually run the system in the browser," Virgil said: "I say it's in the spirit of Dokime to click through on local and confirm the bug." UI reproduction uncovered three validation blockers a feature test would have bypassed. Each blocker was a real consequence of the system under test. | B3 now includes "UI reproduction > feature test" guidance. Feature tests are models; UI is reality. Blockers encountered during manual reproduction are themselves evidence that feature tests would have missed. |
| 2026-04-09 | To unblock each validation during UI reproduction, I patched test data (added cip_code_id and includes_lecture to CCNs, populated Summary tab fields). Each patch was a small divergence from production reality. Virgil asked: "Is this still in the spirit of Dokime?" | B3 now includes "enable, don't bypass" distinction. If the patch enables the code path under test to execute, that's enabling. If it skips the code path under test, that's bypassing. Document enablements for audit. |
| 2026-04-09 | ICOV3-1069 Pass 2 ran end-to-end cleanly through the full Bug Fix Workflow (B1–B15). One process violation (skipped B3, caught and reversed), one quality correction (magic strings → class constants at B8/B9, caught by Virgil), zero iterative debugging, zero rework. Clean-pass characteristics: diagnosis visible in source, pattern precedent already in codebase (PPSS), blast radius small and bounded, B13 Document was near-zero because docblocks were written inline during B9 Green, B10/B11 collapsed cleanly because the full suite ran without regressions on the first attempt. **Meta-observation worth logging separately:** both evolution-log entries from earlier the same day (Step 15 cross-repo completion rule + B3 "code inspection is not reproduction" anti-pattern) were operationally useful hours later — the cross-repo rule drove the B14 completion mapping, and the B3 anti-pattern almost repeated itself in the same pass. | No workflow changes needed — this is dokime running in its "well-formed inputs" mode. Documented as evidence that (a) the ceremony scales down cleanly on well-scoped bugs: it still surfaces an architecture decision at B8/B9 (const refactor), still maps acceptance criteria across repos at B14, still produces ship-ready PR drafts at B15 — value is proportional to the risk of silent errors, not proportional to lines of code changed; and (b) the Evolution Log is *operational*, not archival, on an active project — lessons written in the morning can save work the same afternoon. A workflow doc that lives on a shelf is just documentation; one whose lessons compound within the same session is a tool. |
| 2026-04-13 | A bug was reclassified from "open" to "resolved" based on a single positive Twilio log entry for a different program + different award type than the one originally reported. Shipped a symptom-level fix based on a true bug found during code inspection (wrong preference-key check), then closed the loop. Bug recurred in QA the next week because the fix didn't address the reported symptom — the symptom was caused by missing env config, not the preference-key bug. Category confusion (different award type) masqueraded as resolution. Confused "a true bug I found in the file" with "the root cause of the observed symptom." *Submitted via `/dokime:evolve` — first entry from the evolution feedback loop.* | B4 now includes isolation test (step 7): "Would this fix, by itself, produce the observed behavior if applied in isolation?" Bugs found during inspection are evidence, not diagnosis. B2 now includes reclassification trap: when positive evidence suggests a bug is resolved, verify the evidence matches the original report's specific trigger (notification type, program, user role). Evidence from a different trigger proves a different code path works. |

---

## Usage

```
I want to implement this task using the Dokime TDD workflow. Here's the task:
[DESCRIBE THE TASK OR PASTE THE TICKET]

Follow the Dokime TDD workflow - start with Step 1.
```

---

## Quick Reference

### Feature Workflow
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

### Bug Fix Workflow
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

---

*"Working code" and "correct code" are not the same thing. This workflow closes the gap.*

*© 2026 Virgil Anderson. All rights reserved.*
