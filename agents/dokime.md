# Dokime Workflow

**Author:** Virgil Anderson
**Created:** February 2026
**Last Updated:** April 30, 2026
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

## Recording Checkpoint Outcomes

dokime records what each run produces, so the workflow can be measured against its own claims (the measurement store).

**At every `CHECKPOINT` in this workflow — Feature or Bug — once the human has resolved it, record the outcome.** Call the helper:

```
record-checkpoint <run_id> <ticket_id> <step> <outcome> [note]
```

- `run_id` and `ticket_id` — from the spec file header (`run_id` is minted at Step 1).
- `step` — the checkpoint's step, e.g. `Step 4` or `B4`.
- `outcome` — classify the resolution as exactly one of:
  - `approved-clean` — the checkpoint passed with no change to the step's output.
  - `approved-with-changes` — it passed, but the human's response caused a change to the step's output before it passed (an added acceptance criterion, a corrected decision, a late-surfaced ambiguity).
  - `reopened` — the checkpoint did not pass; the step's work returns for rework.
- `note` — optional; what changed (for `approved-with-changes`) or why it was reopened.

The helper resolves the store path itself (`$DOKIME_MEASUREMENT_STORE` → `measurement_store_path` in `./.claude/dokime-config.json` → default `~/.dokime/measurements/`) and guarantees a schema-conforming record — the dev's only job is to *call* it at each checkpoint. Recording is **instrumentation, never a gate**: if the helper is not installed (an older plugin), skip recording and proceed.

---

## Step 1: Capture Specs

- **Resume vs. start.** Before creating the spec file, check whether one already exists for this ticket. If a spec file is found — especially with a feature branch carrying committed work — the workflow is being *resumed*, not started: do not restart at Step 1. Read the spec, determine the last completed step it records, and resume from there. If the spec records no clear resume point, ask the human where to pick up. Tagged class: `workflow_resume_unhandled`.
- **Scan the Evolution Log** (bottom of this document) for recent entries — lessons from the last session may apply to this ticket. The log is operational, not archival; entries written in the morning can save work the same afternoon.
- Parse the ticket/task requirements
- Create the spec file
- Write to the spec file:
  - Task ID and title
  - Run ID — `<ticket-id>@<ISO-8601 start timestamp>` (e.g. `DKV2-T2@2026-05-22T16:00:00`); keys this run's checkpoint-outcome records — see *Recording Checkpoint Outcomes*
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

A Step 4 decision is not a contract. If later evidence — a Step 9 sentinel going red, a Step 6 codebase finding, a composition check — overrides a decision recorded here, that is the workflow working, not a process violation. Record the pivot in the Decision Log: keep the original decision *and* the evidence that overrode it. A mid-flight pivot driven by sentinel red does not require a workflow restart.

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

**Identify framework lifecycle dependencies:**
- If the code under change reads from framework lifecycle state (Eloquent `$table`/`$exists`/attributes; Symfony container resolution; Rails ActiveRecord initialization; React component lifecycle; etc.), note it explicitly.
- Service-level tests that go through normal hydration auto-populate this state and silently mask abstraction bugs — they catch only catastrophic regressions, not the latent class. Unit-level tests on factory-fresh / new-instance scenarios are required to discriminate. Carry this finding to Step 9 for test-design implications. Tagged class: `lifecycle_state_masking`.

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

**Specialized agents at proposal time.** When the approach touches a domain with a registered specialized agent (authorization, data layer, MIS, workflow, test data, etc.), dispatch that agent now — not only at code-review time. The earliest cheap correction is during proposal, before any code is written: at Step 7 a course change is a one-line spec edit; at Step 11 it's a re-implementation.

**Deliberate-state check.** If the approach proposes changes to deployment, infrastructure, or shared architectural state — anywhere outside the layer you own (deploy pipelines, server config, shared service architecture, team conventions) — first check whether the current state is deliberate. Sources: project CLAUDE.md, recent session logs, recent meeting transcripts, recent Slack on the topic. Proposing a "fix" for an intentional architectural choice creates friction without value. Different from the B2 reclassification trap (which catches "this bug is already resolved" claims); this catches "this state is a bug" claims about *deliberate* architectural choices. Tagged class: `deliberate_state_misclassified_as_bug`.

**Apply evidence-first discipline to agent claims.** A dispatched specialized agent's output mixes verified code reading with inference about production behavior. Treat the inferential part the way you'd treat a peer's verbal dismissal on a call: do not accept it without named evidence. When an agent recommends *expanding scope* ("this nearby line is almost certainly contributing to the Sentry signature"), demand the concrete evidence — breadcrumb shape, a repro, source quotes — before accepting. A breadcrumb trail alone can falsify an "almost certainly firing" claim: a single-breadcrumb initial-load crash is not a multi-breadcrumb mid-session crash. The rule is not "distrust agents" — it is "hold agent recommendations to the same evidence standard as peer recommendations." Tagged class: `agent_speculation_unverified`.

**Wrap/reshape layer audit (mandatory).** When the approach adds, expands, or touches an interceptor or any wrap/reshape layer — Axios response interceptors, Express middleware, Symfony EventDispatcher, Laravel HTTP middleware — do not stop at the layer itself. Sweep its consumers: grep the call sites that read the payload and check whether each honors the *wrapped* shape across the layer's full output domain, including null-data and error paths. A consumer written against the pre-wrap shape mismatches silently — production code reading `error.response.data` on a reshaped payload throws a TypeError, often cascading `.then`→`.catch`→double-throw so the outer throw masks the inner cause. This is the production-code-side analogue of Rule 11's `tautological_test`: two pieces of code share a blind spot, but the pairing is interceptor↔caller, not test↔code. This sweep is not optional — the class recurred within hours on a sibling ticket from one interceptor change (combined 216 users / 423 events). Tagged class: `interceptor_contract_violation`.

**Route middleware group must match how the client authenticates.** When the change adds or moves a route, confirm its middleware group matches the client's auth mechanism. A session-cookie SPA calling a route in a stateless `api` group (token guard, no session middleware) gets a 401 — and the mismatch is invisible to the backend test suite.

**CHECKPOINT: Get human approval on approach before writing any code.**

---

## Step 8: Establish Baseline

**Start clean. Know what's broken before you touch anything.**

1. If you aren't on a clean branch for the ticket create and checkout a fresh branch from the base branch (e.g., `develop`). Look at existing branch structure and follow it.
2. **Verify branch sync.** Run `git log HEAD..origin/<base>` and confirm it's empty, or document the divergence in the spec. The baseline-vs-PR-diff signal silently degrades as base moves; surface drift now, not when drafting the PR. Tagged class: `baseline_drift`.
3. Verify no uncommitted changes
4. Run the full test suite before writing any code
5. Log the results:
   - How many tests pass?
   - How many tests fail? Which ones?
   - Are there any skipped or incomplete tests?
6. If tests are already failing, document them in the spec file as **pre-existing failures** — these are not your responsibility, but you need to know they exist so you don't waste time debugging them later

**Verify test-DB isolation before trusting the count.** Confirm the suite runs against an isolated, reset-per-run test database. If it runs against a shared or populated database, the pass/fail *count* drifts run-to-run from database content, not code — it is not a reliable baseline. In that case capture the baseline as the **failing-test set** (test name + file), not the count. Tagged class: `no_test_db_isolation`.

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

**Mutation-test new tests (strongly recommended; required for refactor sentinels).** For each new or changed test, briefly mutate the production code in a way that should make the test fail. If the test still passes, it isn't discriminating against the bug you care about — strengthen the assertion or the setup. Restore the production code before continuing. This is the multi-bit version of the red step: "did I see red once?" is one bit; "does this test discriminate against the mutation I care about?" is what catches false greens.

**Refactor sentinels — mutation testing required, not recommended.** A *refactor sentinel* is a test that passes green against both the pre-refactor and post-refactor code (a regression sentinel against accidental behavior change). Refactor sentinels by definition cannot be discriminated against by a normal red→green cycle — there is no red moment in their lifecycle. Mutation testing is the only mechanism that proves they're not tautological. **Run the named mutation; do not accept hypothetical mutations.** Tagged class: `tautological_test` (refactor variant).

**Beware tautological tests (Rule 11).** When the test fixture and the production code share a blind spot, no internal contradiction surfaces — the test cannot fail. Two common mechanisms:
- **Value mismatch.** Test mocks infrastructure (storage, queues, cache, external services, auth, feature flags) using the same hardcoded value the code uses literally. Example: production calls `Storage::disk("local")`, test calls `Storage::fake("local")`. Switching the production disk to a different value leaves the test passing.
- **Scope mismatch.** Test activates a flag, feature, or permission in a scope the production code doesn't check. Example: production calls `Feature::active("x")` in an authenticated user context (user-scoped), test activates the flag globally without user-scoping it. The flag check fails silently and the test passes for the wrong reason — the gate code is never evaluated.

The structural fix in either case is to refactor the code to read from a config or scope layer the test can drive, or to integration-test against the real boundary. Mutation testing surfaces both. See Rule 11.

**Test design under framework lifecycle dependencies.** If Step 6 flagged that the code under test reads framework lifecycle state, your test plan must include unit-level coverage on factory-fresh / new-instance scenarios. Service-level tests that go through normal hydration auto-populate the state and silently mask abstraction bugs. Both layers are usually needed: service tests confirm production paths still work; unit tests confirm the abstraction itself isn't broken. Tagged class: `lifecycle_state_masking`.

**Jest projects — name mock bindings with the `mock` prefix from the start.** If the project uses Jest, Jest hoists `jest.mock()` factory functions above all `import` statements. A factory closure may reference only out-of-scope identifiers whose name is prefixed with `mock` (case-insensitive); a plain identifier throws `ReferenceError: ... not allowed to reference any out-of-scope variables`. Name every spy/stub binding `mockFoo` *before* writing the factory — renaming afterward costs a failed run plus cascading edits, and a blanket `replace_all` over-matches into production property keys. Not applicable to Pest, pytest, or other runners.

**`actingAs()` bypasses the auth-middleware path.** Pest/PHPUnit `actingAs()` sets the guard user directly — it never exercises session middleware or the route group's real auth path. A suite of `actingAs()` tests all pass on a route placed in the wrong middleware group. To discriminate, add a route-group/middleware assertion or a guest-request test (no `actingAs()`) that exercises the real auth path. Tagged class: `stateless_route_group_masked_by_actingas`.

**Parallel subagents:** If the plan from Step 7 identified truly independent sub-problems, dispatch separate agents to write tests for each simultaneously. Independent means: no shared state, no shared files, no interaction effects. If in doubt, do them sequentially — false independence creates merge conflicts and interaction bugs.

**CHECKPOINT: Failing tests reviewed. Do they cover the right behavior? Are edge cases included? Do they match the spec from Step 1?**

---

## Step 10: Implement (Green)

- Write minimum code to make tests pass
- Follow existing patterns identified in Step 5
- Run tests after each significant change
- Continue until all tests pass
- **Approach compliance**: Before presenting, compare what was built against what was approved in Step 7. Note any deviations and why.

**Refactor expansion — ask one at a time, count the cumulative.** When the human approves a refactor *not* in the Step 7 scope ("we're already in this file, let's also extract this scope / split this method / drop `::query()`"), do not batch the remaining expansions into one approval. Ask before *each* next expansion, framed as do-it / sibling-ticket / leave-alone. The granular ask is the brake — it keeps the human gating PR size and creates a natural off-ramp at every step. Each time, name the cumulative cost so the off-ramp is visible: "this is expansion 6; the ticket was 1 point, the PR is now 7 files." Refactor-prone tickets silently grow when expansions are pre-approved as a block.

**Visual smoke test.** If the change affects user-visible behavior on a UI surface — including changes to which state, count, list, or tile a record appears in — load it in the browser before proceeding. UI-behavior change includes side effects of service-layer code that surface in views, *even when no view file was edited*. Confirm the output renders in the right place, the right component, the right page. Code that passes tests but renders in the wrong location (or routes a record to the wrong tile) is not green — it's red in a way tests don't catch. Read this rule by spirit, not by letter: "I didn't touch a blade file" is not the question; "can the user see the difference?" is. API consumers are users: a change to an API endpoint's JSON response shape or content is a user-visible surface change even when no view file is touched — the consumers are SPAs, mobile apps, integrations. For an API-only change, the smoke test is a real `curl` against the changed endpoint *and* a real UI smoke through at least one consumer. "It's an API change, no UI" is not an exemption.

**Parallel subagents:** Same rule as Step 8. If sub-problems are truly independent, dispatch agents in parallel. Each agent implements its sub-problem and runs its tests. Integrate and run the full suite after all agents complete.

**Present the change set for a reader who is not in this context.** The human checkpoint is only as good as the human's understanding of what they're approving — and the reviewer does not hold the diff in their head the way the AI does. Do not present changes as raw tool output and prose alone. Give a per-file *what changed and why*, before/after snippets for any non-obvious edit, and — for a flow or structural change — a simple diagram. Teach the change; don't just list it.

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

**Pass 3 — Test/code agreement (tautological test check, see Rule 11):**
- For each new test that mocks infrastructure (storage, queues, cache, external services, auth, feature flags): name every value *and scope* the test fixture and the production code share — both hardcoded values *and* scopes (user, team, role, request context). For each, is the agreement structural (driven by config or environment the test mocks) or coincidental (both hardcoded, or both ignoring scope)? Coincidental = tautological — refactor or integration-test against the real boundary.
- For each new test: name a change to the production code that should make the test fail. If you cannot name one, the test isn't discriminating against the bug it was written for.
- **Scope checks must name scopes, not reason about them.** A "no user-scoping mismatch risk" conclusion is valid only if it names three concrete scopes and confirms they agree: (1) the scope production *reads* (e.g. `Feature::active()` resolves per-user); (2) the scope the *test* drives (e.g. `Feature::define(fn => true)` — true for every scope, which hides mismatch); (3) the scope the production *enable path writes* (e.g. a global/null-scope activation). If production reads per-user but the enable path writes global, the flag shows enabled and the endpoint still 404s. A no-risk conclusion reached without naming all three scopes is itself the failure — the scope check satisfied by reasoning instead of by enumeration.
- **Refactor sentinels** (tests green against both pre- and post-refactor code): the previous bullet is **required**, not recommended. Run the named mutation; do not accept hypothetical mutations.
- **Setting-shaped surfaces** (admin checkboxes, toggles, thresholds, feature flags, env-driven config): for each, name (a) at least one consumer that reads the value and changes behavior, and (b) at least one test that exercises the *effect* on behavior, not just persistence. Persistence-only tests permit `unwired_admin_setting` regressions where the setting is structurally a no-op.
- **Request-field coverage** (Laravel `FormRequest::validated()` consumers): for each field the controller or service reads out of `request->validated()` — or any validator that returns only ruled keys — is there a validation rule that *keeps* that key? An unruled key is silently dropped: `request->all()` has it, `request->validated()` does not, so the downstream `isset()`/`??` guard is permanently false and the feature no-ops with no error. When in doubt, confirm with a discriminating experiment — same payload, same rules, compare `all()` vs `validated()`. New failure class: `validated_strips_unruled_field` (structural).

**Specialized agents:** If the project has domain-specific coding agents (e.g., authorization experts, data layer experts, workflow experts, test data experts), dispatch them to review the changes in their area of expertise. Each agent reviews independently and reports findings. This catches domain-specific issues that a general review misses. **Note:** these agents should also have been dispatched at Step 7 (proposal time) — Pass 3 review is a second look, not a first one. If you skipped early dispatch, that's the cheaper miss to fix going forward.

Fix any issues found before proceeding — changes made during quality review could introduce regressions, which is why regression tests come next.

**CHECKPOINT: Human confirms code quality is acceptable.**

---

## Step 12: Regression Tests

- Run full test suite to ensure no regressions
- Compare results against the baseline from Step 8 — any new failures are yours
- If Step 8 found the test database is not isolated, compare the failing-test **set** (test name + file) against the Step 8 baseline set — not the counts. A regression is a new failure name or a failure in a file outside the diff; a changed count alone is noise.
- Run **all** configured quality tools — not just the formatter. Formatting tools (e.g., Pint, Prettier) catch style issues. Static analysis and codesniffer tools (e.g., PHPStan, PHPCS, ESLint, `tsc --noEmit`) catch structural issues — trailing commas, docblock annotations, type errors, unused imports. Running one without the other leaves a gap.
- Fix any failures or issues
- Report results to human

---

## Step 13: Verify

**Walk through each test scenario one at a time. Do not batch.**

Verification catches what automated tests can't — **UI/behavior issues** (layout, interactions, real user flow) *and* **infrastructure/config issues** (unconfigured services, disk/S3 gaps, environment drift masked by `Storage::fake()` or similar). Both surface here.

UI-behavior scope is broad: a service-layer change that affects which state, count, list, or tile a record appears in is a UI-behavior change even if no view file was edited. If the human user can see the difference, it's in scope here. API consumers count as users: a change to an API endpoint's JSON response shape or content is a user-visible surface change even when no view file is touched — verify it with a real `curl` and a real UI smoke through at least one consumer (SPA, mobile, integration).

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
- **Reconcile decision rationale across artifacts.** For any in-scope decision made during this workflow whose rationale is recorded in more than one place (spec, session log, commit message, PR draft), re-verify before ship that the rationale still holds. Generalized question: *Has any finding later in this workflow contradicted a scope decision made earlier?* A same-workflow after-finding can quietly supersede the rationale for in-scope work — the two documents drift apart within one session. If a finding has superseded a decision, reconcile: either un-scope the now-unjustified work or update the stale rationale before the code ships. Tagged class: `after_finding_supersession`.

**CHECKPOINT: Human confirms nothing was missed before proceeding.**

---

## Step 16: Ship

**PR Packaging (decide before drafting):**
- **Re-verify branch sync.** Run `git log HEAD..origin/<base>` again. Baseline drift since Step 8 produces misleading diff output and noisy PRs — files you never touched will appear in `git diff origin/<base>` because base moved while you were working. If drift exists, merge or rebase before drafting. Tagged class: `baseline_drift`.
- Is the commit history clean? Squash WIP / merge / fix-fix-fix noise if appropriate — reviewers read commits, not just the final diff.
- Does the diff include infrastructure or preparatory changes that aren't part of this feature (schema dumps, `.env.testing` edits, unrelated refactors)? Consider splitting them into separate PRs — reviewer attention is finite, and mixed PRs are harder to review and revert.
- Is the diff scoped to what a reviewer actually needs to see? Minimize noise.

**PR Description:**
- Summarize changes made
- List files modified
- List shared components affected and their blast radius
- Provide PR description draft

**Present the change set for a reader who is not in this context.** The PR reviewer does not hold the diff in their head the way the AI does, and a checkpoint only works if the human understands what they're approving. The PR description must teach the change: a per-file *what changed and why*, before/after snippets for any non-obvious edit, and — for a flow or structural change — a simple diagram. A list of files is not an explanation.

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

**Reclassification trap (false-resolved direction).** If positive evidence suggests the bug is already resolved (e.g., logs show the system working in production), verify that the evidence matches the original report's *specific trigger* — same notification type, same program, same user role, same data conditions. Evidence from a different trigger proves a different code path works, not that the reported path works. "Twilio shows SMS working" doesn't close "badge awards aren't firing" — those are different award types on different code paths. Don't reclassify until evidence matches the report.

**Symmetric trap (false-active direction) — historical fix in same corpus.** When a ticket is sourced from an older transcript, channel, or corpus (e.g., a training-session transcript, an old Slack thread, a stale RAG hit), scan that same source for *resolution* evidence before classifying as an active bug. The symptom narrative is often preserved alongside the fix narrative — checking only the symptom side carries forward already-fixed bugs as present-tense vulnerabilities. Before B3 reproduction, RAG-search the source corpus for the symptom plus terms like "fixed", "resolved", "reverted", "safeguard", "incident" — and check dates. If you find a fix narrative, verify with the reporter live before classifying as an active bug. Counterpart to the reclassification trap above (which catches false-resolved); this catches false-active. Tagged class: `reclassification_trap` (false-active direction).

**AC-vs-evidence drift.** Acceptance criteria on a bug ticket are often drafted *before* observed evidence (Sentry breadcrumbs, logs, the actual reproduction) is in hand — so an AC's reproduction recipe can encode the author's *assumption* about the trigger rather than the production-frequency path. Once evidence is pulled, scan each AC's stated recipe against it: does the AC's trigger match what the breadcrumbs / logs / repro actually show? If they diverge, flag it explicitly in the spec — do not silently read the AC as "test what's written." Both can be valid coverage, but the test design at B8 must then split them: one test for the AC literal, one for the production-frequency trigger. Resolve the divergence at B5. Counterpart to the two reclassification traps above — those operate on the bug-active/resolved axis; this operates on the AC layer. Tagged class: `ac_drafted_before_evidence`.

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

**A crash during reproduction can be evidence, not a setback.** If the reproduction itself crashes — e.g. an out-of-memory fatal at the leak site of a security bug — do not immediately bypass it (raising memory limits, switching test paths). A crash at the failure site can be a *second* failure mode the reproduction just discovered: a deep exception trace serialized into a response is both an info leak and a DoS surface. Document the discovered secondary failure mode in the spec *before* bypassing it; it may warrant its own ticket. Tagged class: `diagnostic_signal_bypassed`.

**Narrow exemption — when external evidence is the anchor.** B3's purpose is to give B12 a real observed state to verify against. That purpose can be served without local reproduction *only* when all three hold: (a) concrete external reproduction evidence exists — a production video, a reporter screenshot, a customer session recording — and can serve as B12's before-state anchor; (b) the fix is data-only or config-only — no logic change, no migration, no signature change; (c) the consumer code is verified by inspection to apply no transform between the changed source and the user-visible output. If all three hold, the external evidence stands in for local repro as the B12 anchor. If any one fails, B3 is non-negotiable as stated above — and "the source obviously shows the bug" is never one of the three. Tagged class: `b3_exemption`.

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

**Anti-pattern: AI-asserted library mechanism.** Any "library X does Y when Z" claim about library or framework internals (e.g., "webpack-dev-server reloads on WebSocket close", "React batches state updates here", "Laravel's Pennant scopes to user automatically") must be verified against actual library source — grep + read the relevant lines — before being relayed to the human or to stakeholders. Cheap to verify; expensive when wrong. The verification is one of the simplest peira available: stop, read the source, confirm. Without this rule, AI-generated mechanism claims propagate as if they were source-verified, leading to misdirected fix attempts and stakeholder messages that have to be retracted. Tagged class: `unverified_library_mechanism_claim`.

**Discriminating diagnosis (Rule 12).** Before concluding the root cause and proceeding to B5, name a test — mutation or experiment — that should produce one observable result under the current theory and a *different* result under at least one named alternative theory. If the test confirms the theory, proceed. If it doesn't (or if no discriminating test can be named), the theory is incomplete and B4 continues. This generalizes Step 9 / B8's mutation-test rule from "is this *test* discriminating?" to "is this *diagnosis* discriminating?" Bug investigations that produce a coherent-looking single-mechanism theory at every iteration — each falsified by the next experiment — are exactly the failure mode this rule names. Tagged class: `non_discriminating_diagnosis`.

**Sibling-pattern check.** For each candidate root cause, compare the affected code against its siblings in the same file or module. If the suspected bug pattern is the *dominant* pattern across siblings, it may be the intended convention, not a bug — or the bug may be that this one entity diverges from the convention its siblings follow. Sibling comparison discriminates "this code is wrong in isolation" from "this code is wrong relative to its peers." The two diagnoses produce different fix shapes (change a comparator vs. re-order the data). A fix built on the wrong one looks plausible but doesn't fix the bug. Tagged class: `sibling_pattern_blind_diagnosis`.

**Classify the failure class (workflow audit).** With root cause in hand, cross-reference this bug against the Failure Class Registry in `~/Documents/Dokime/data/ledger.md` (or the project's local equivalent). Three possibilities:

- **Known class** — the bug matches an existing entry. Note which evolution rule should have caught it. Then ask: was the rule violated (discipline gap), not applicable to this context (rule needs scope refinement), or insufficient (rule exists but doesn't actually catch this case)?
- **New class** — the bug doesn't match any registry entry. This is a candidate for a new evolution entry at B15. Name the class in snake_case (e.g., `time_zone_drift`, `null_default_regression`).
- **Unclassifiable** — the bug is genuinely novel or one-off; not a recurring pattern. Note that explicitly so we don't over-name.

**Trace the bug to its origin (regression check).** Use `git blame` on the root-cause code to find the commit that introduced it. Then check whether that commit traces back to a dokime ticket — by ticket ID in the commit message, by associated spec file (project convention varies — `specs/`, `docs/specs/`, or referenced in PR description), or by matching date against the ledger. Three outcomes:

- **Origin is a dokime ticket** — record the originating ticket ID, the workflow version active at the time, and the spec file path. This bug is a *direct regression on a specific dokime ticket*. The audit question sharpens: which step of that ticket's pass should have caught this? Was a rule that now exists not present then, or did it exist and miss?
- **Origin pre-dates dokime adoption** — record `origin_workflow: N` in the ledger row. The bug is unaudited from a dokime perspective; the workflow can claim no credit or blame.
- **Origin unknown** — code was rewritten, history is squashed, or blame points to a non-feature commit (refactor, merge). Record `origin_workflow: unknown` and move on.

This classification feeds the ledger row at B15 and (if new class or direct regression) a `/dokime:evolve` submission. The bug workflow is itself a peira against dokime — every bug is data on what the workflow caught, missed, or never claimed to catch. Direct regressions are the highest-value data: they tell us exactly which version of the workflow let exactly which class of bug through.

**`git blame` finds where the code was written, not when the behavior broke.** When blame shows the root-cause code is old but the symptom is new — especially if a peer reports it worked recently — the regression may not be in your code at all. Before classifying origin as pre-dokime or broken-from-birth, check the regression window for a framework or dependency change: was there a major-version upgrade (or any dependency bump) between "last known good" and "first observed bad"? Major versions silently change method *behavior* — e.g. Laravel's `validated()` began stripping unruled nested-array keys across one upgrade. Apply the framework-upgrade behavioral-grep here too: grep for callers of the suspect framework method and read its changelog / upgrade guide for behavior changes, not just signature changes. A behavior regression from a dependency upgrade is still a regression with a datable origin — record the upgrade commit/date as the origin, not `origin_workflow: N`. New failure class: `framework_upgrade_behavior_regression` (structural).

**CHECKPOINT: Human confirms root cause diagnosis *based on experimental evidence* AND failure class classification. This is the most important checkpoint in the bug workflow — a wrong diagnosis means a wrong fix.**

---

### Step B5: Desired Behavior

What *should* happen? This is the bug-specific version of ambiguity surfacing.

- State the correct behavior clearly
- If there's ambiguity about what "correct" means (multiple reasonable interpretations), surface it now — label as business decision or technical decision, same as Step 4 in the feature workflow
- If the correct behavior contradicts other existing behavior, flag it
- If B2 flagged AC-vs-evidence drift, resolve it here: confirm which trigger each test will target so AC-literal coverage and production-frequency coverage are both designed in at B8, not collapsed into one.
- **B5 decisions are reopenable at B9.** A B5 desired-behavior decision — including ambiguities resolved as "out of scope" — is provisional until B9 visual smoke confirms it against observed reality. If B9 smoke shows the B5-locked behavior is unacceptable in practice (passing tests, failing user experience), reopen B5. Do not ship that result on the grounds that "B5 already decided." The spec records the reopening and the rationale at each iteration; that record *is* the audit trail. Iteration here is the workflow doing its job.

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

**Specialized agents at fix-proposal time.** When the proposed fix touches a domain with a registered specialized agent (authorization, data layer, MIS, workflow, test data, etc.), dispatch that agent now — not only at code-review time. At B6 a course change is a one-line spec edit; at B10 it's a re-implementation. Domain-specific agents catch corrections general review can't surface (e.g., "the dependency you're injecting is already reachable through an existing service — add a proxy method instead", "the upstream gate you're worried about is already in the console kernel"). The earliest cheap correction is here.

**Deliberate-state check.** If the proposed fix would touch a layer outside the one you own (deploy pipelines, server config, shared service architecture, team conventions), check whether the current state is deliberate before recommending change. Sources: project CLAUDE.md, recent session logs, recent meeting transcripts, recent Slack on the topic. Different from the B2 reclassification trap (which catches "this bug is already resolved" claims); this catches "this state is a bug" claims about *deliberate* architectural choices. Tagged class: `deliberate_state_misclassified_as_bug`.

**Probe scope decisions, don't defend them.** When a scope decision — in-scope vs out-of-scope, ship-or-pull, keep-or-refactor — hinges on whether an underlying issue is real, do not argue it from speculation. Design and run a probe that is decisive within minutes (a payload-size measurement, a clean-session repro with the code reverted, a quota check) before continuing to defend either position. This is Rule 12 applied to scope: name a test whose outcome forces one decision under one theory and the opposite under the alternative; if you cannot name one, you are speculating. A wasted probe costs minutes; speculation-driven scope creep — or pulling code that was actually needed — costs more. Tagged class: `speculative_scope_defense`.

**Wrap/reshape layer audit (mandatory).** When the proposed fix adds, expands, or touches an interceptor or any wrap/reshape layer — Axios response interceptors, Express middleware, Symfony EventDispatcher, Laravel HTTP middleware — do not stop at the layer itself. Sweep its consumers: grep the call sites that read the payload and check whether each honors the *wrapped* shape across the layer's full output domain, including null-data and error paths. A consumer written against the pre-wrap shape mismatches silently — production code reading `error.response.data` on a reshaped payload throws a TypeError, often cascading `.then`→`.catch`→double-throw so the outer throw masks the inner cause. This is the production-code-side analogue of Rule 11's `tautological_test`: two pieces of code share a blind spot, but the pairing is interceptor↔caller, not test↔code. This sweep is not optional — the class recurred within hours on a sibling ticket from one interceptor change (combined 216 users / 423 events, both latent in pre-existing code for over a year). Tagged class: `interceptor_contract_violation`.

**Apply evidence-first discipline to agent claims.** A dispatched specialized agent's output mixes verified code reading with inference about production behavior. Treat the inferential part the way you'd treat a peer's verbal dismissal on a call: do not accept it without named evidence. When an agent recommends *expanding scope* ("this nearby line is almost certainly contributing to the Sentry signature"), demand the concrete evidence — breadcrumb shape, a repro, source quotes — before accepting. A breadcrumb trail alone can falsify an "almost certainly firing" claim: a single-breadcrumb initial-load crash is not a multi-breadcrumb mid-session crash. The rule is not "distrust agents" — it is "hold agent recommendations to the same evidence standard as peer recommendations." Tagged class: `agent_speculation_unverified`.

**Multi-surface fix audit.** When a fix touches more than one surface (a controller catch block, the global exception handler, a new middleware), audit each surface independently: does *this* piece address a production concern, or is it consistency-tightening on a path that was not actually leaking in production? Editing a surface that was already behaving correctly in prod — e.g. removing env-gating production was evaluating correctly — is silent scope drift; the PR description ends up claiming more than the change delivers. Each surface must trace to the reported problem or be re-scoped to a sibling ticket. Tagged class: `multi_surface_scope_drift`.

**CHECKPOINT: Human approves the fix approach.**

---

### Step B7: Establish Baseline

Same as feature Step 8.

1. Create and checkout a fresh branch from the base branch
2. **Verify branch sync.** Run `git log HEAD..origin/<base>` and confirm it's empty, or document the divergence in the spec. The baseline-vs-PR-diff signal silently degrades as base moves; surface drift now, not when drafting the PR. Tagged class: `baseline_drift`.
3. Verify no uncommitted changes
4. Run the full test suite before writing any code
5. Log results — passes, failures, skips
6. Document pre-existing failures — these are not yours
7. **Verify test-DB isolation.** Confirm the suite runs against an isolated, reset-per-run test database. If it runs against a shared or populated database, the pass/fail *count* drifts run-to-run from database content, not code — capture the baseline as the **failing-test set** (test name + file), not the count. Tagged class: `no_test_db_isolation`.

**CHECKPOINT: Human confirms baseline is established.**

---

### Step B8: Write Failing Test (Red)

Write a test that reproduces the bug. **This test should fail**, proving the bug exists in code.

- The test should encode the *desired* behavior from Step B5
- It fails because the code currently produces the *actual* (wrong) behavior
- If the test passes, either the bug isn't what you think it is or the test isn't testing the right thing — go back to B4

**Mutation-test the new test (strongly recommended).** Briefly mutate the production code in a way that should make the test fail. If the test still passes, it isn't discriminating against the bug you care about — strengthen the assertion or the setup. Restore the production code before continuing.

**Jest projects — name mock bindings with the `mock` prefix from the start.** If the project uses Jest, Jest hoists `jest.mock()` factory functions above all `import` statements. A factory closure may reference only out-of-scope identifiers whose name is prefixed with `mock` (case-insensitive); a plain identifier throws `ReferenceError: ... not allowed to reference any out-of-scope variables`. Name every spy/stub binding `mockFoo` *before* writing the factory — renaming afterward costs a failed run plus cascading edits, and a blanket `replace_all` over-matches into production property keys. Not applicable to Pest, pytest, or other runners.

**Beware tautological tests (Rule 11).** When the test fixture and the production code share a blind spot, no internal contradiction surfaces. Two common mechanisms:
- **Value mismatch.** Test mocks infrastructure (storage, queues, cache, external services, auth, feature flags) using the same hardcoded value the code uses literally. Example: production calls `Storage::disk("local")`, test calls `Storage::fake("local")` — switching the production disk leaves the test passing.
- **Scope mismatch.** Test activates a flag, feature, or permission in a scope the production code doesn't check. Example: production reads a Pennant flag user-scoped, test activates it globally — the gate code is never evaluated and the test passes for the wrong reason.

Either refactor to read from a config or scope layer the test can drive, or integration-test against the real boundary. See Rule 11.

**CHECKPOINT: Failing test reviewed. Does it accurately reproduce the bug?**

---

### Step B9: Fix the Bug (Green)

- Write minimum code to make the test pass
- Follow existing patterns in the codebase
- Run tests after each significant change
- Continue until the reproduction test passes
- **Approach compliance**: Compare the fix against what was approved in Step B6. Note any deviations and why.
- **Check every link in the causal chain.** After the first observable change, don't stop. Trace the fix through every downstream step — from the trigger, through each intermediate state, to the final output. Partial success looks like success until you check the next link. (Example: Vue model clears correctly but `dataChange` payload still misses the field because programmatic updates don't fire DOM events — two different links in the same chain.)

**Visual smoke test.** If the fix changes user-visible behavior on a UI surface — including changes to which state, count, list, or tile a record appears in — load it in the browser before proceeding. UI-behavior change includes side effects of service-layer code that surface in views, *even when no view file was edited*. Confirm the bug is visually resolved and the fix renders in the right place. A fix that passes tests but looks wrong (or routes a record to the wrong tile) is not green. Read this rule by spirit, not by letter: "I didn't touch a blade file" is not the question; "can the user see the difference?" is. The pre-fix vs. post-fix visual contrast also anchors B12 — without it, you're verifying the fix against an *imagined* post-fix state. If the smoke reveals the B5-agreed behavior is unacceptable in observed reality, reopen B5 rather than accepting a technically-compliant but unusable result. API consumers are users: a change to an API endpoint's JSON response shape or content is a user-visible surface change even when no view file is touched — for an API-only fix the smoke is a real `curl` against the endpoint *and* a real UI smoke through at least one consumer (SPA, mobile, integration).

**B9 visual smoke is where minimum-scope meets user experience.** A fix can pass every unit test and meet the literal AC while producing an unacceptable experience — a blank page, a permanent "loading…" state, a bare flash banner. *Passing-tests-but-failing-UX is a real outcome class*, and the smoke test is the only place it surfaces before a Sentry secondary signal weeks later. Expect iteration here; iteration is the workflow working, not failing. The minimum-scope fix may well survive the iteration — but you have to run the iteration to know. The fix that ships is the one the human sees in production reality, not the one the tests blessed.

**Multi-surface fix audit (re-check).** If the fix touched more than one surface, re-confirm here what B6 flagged: each surface traces to the reported production problem; none is consistency-tightening on a path that wasn't actually leaking in prod. See B6's multi-surface audit. Tagged class: `multi_surface_scope_drift`.

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

**Pass 3 — Test/code agreement (tautological test check, see Rule 11):**
- For the new test that mocks infrastructure (storage, queues, cache, external services, auth, feature flags): name every value *and scope* the test fixture and the production code share — both hardcoded values *and* scopes (user, team, role, request context). For each, is the agreement structural (config-driven, scope-driven) or coincidental (both hardcoded, or both ignoring scope)? Coincidental = tautological — refactor or integration-test against the real boundary.
- Name a change to the production code that should make this test fail. If you cannot, the test isn't discriminating against the bug it was written for.
- **Scope checks must name scopes, not reason about them.** A "no user-scoping mismatch risk" conclusion is valid only if it names three concrete scopes and confirms they agree: (1) the scope production *reads* (e.g. `Feature::active()` resolves per-user); (2) the scope the *test* drives (e.g. `Feature::define(fn => true)` — true for every scope, which hides mismatch); (3) the scope the production *enable path writes* (e.g. a global/null-scope activation). If production reads per-user but the enable path writes global, the flag shows enabled and the endpoint still 404s. A no-risk conclusion reached without naming all three scopes is itself the failure.
- **Refactor sentinels** (tests green against both pre- and post-fix code): the previous bullet is **required**, not recommended. Run the named mutation; do not accept hypothetical mutations.
- **Setting-shaped surfaces** (admin checkboxes, toggles, thresholds, feature flags, env-driven config) introduced or changed by the fix: name (a) at least one consumer that reads the value and changes behavior, and (b) at least one test that exercises the *effect* on behavior, not just persistence. Persistence-only tests permit `unwired_admin_setting` regressions.
- **Request-field coverage** (Laravel `FormRequest::validated()` consumers): for each field the controller or service reads out of `request->validated()` — or any validator that returns only ruled keys — is there a validation rule that *keeps* that key? An unruled key is silently dropped: `request->all()` has it, `request->validated()` does not, so the downstream `isset()`/`??` guard is permanently false and the feature no-ops with no error. When in doubt, confirm with a discriminating experiment — same payload, same rules, compare `all()` vs `validated()`. New failure class: `validated_strips_unruled_field` (structural).

Fix any issues found before proceeding.

**CHECKPOINT: Human confirms code quality is acceptable.**

---

### Step B11: Regression Tests

Same as feature Step 12.

- Run full test suite
- Compare results against baseline from Step B7 — any new failures are yours
- If Step B7 found the test database is not isolated, compare the failing-test **set** (test name + file) against the baseline set — not the counts. A regression is a new failure name or a failure in a file outside the diff; a changed count alone is noise.
- Run **all** configured quality tools — formatter, static analysis, and codesniffer (same as feature Step 12)
- Fix any failures

---

### Step B12: Verify

**Verify the bug is fixed AND nothing else broke.**

1. Follow the reproduction steps from B3 — the bug should no longer occur
2. Verify the desired behavior from B5 is now the actual behavior
3. Check the blast radius items from B6 — do they still work?
4. If the fix changes user-facing behavior — including side effects of service-layer code that surface in views (which state, count, list, or tile a record appears in) — walk through related workflows. Read by spirit, not by letter: "no view file edited" is not the question; "can the user see the difference?" is. API consumers count: a change to an API endpoint's JSON response shape or content is user-visible even with no view file touched — verify it with a real `curl` and a real UI smoke through at least one consumer.

**Do not batch. Test one scenario at a time.**

**Discriminating-diagnosis recheck (Rule 12).** Before B14, restate the discriminating test you named at B4 and confirm the fix produced the predicted observable result. If the diagnosis was right, the fix should change behavior in the way the discriminator predicted — and not change behavior in the way an alternative theory would have predicted. If the predicted result didn't materialize, B4 was incomplete; loop back. Tagged class: `non_discriminating_diagnosis`.

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
- **Reconcile decision rationale across artifacts.** For any in-scope decision made during this workflow whose rationale is recorded in more than one place (spec, session log, commit message, PR draft), re-verify before ship that the rationale still holds. Generalized question: *Has any finding later in this workflow contradicted a scope decision made earlier?* A same-workflow after-finding can quietly supersede the rationale for in-scope work. If a finding has superseded a decision, reconcile: either un-scope the now-unjustified work or update the stale rationale before the code ships. Tagged class: `after_finding_supersession`.

**CHECKPOINT: Human confirms nothing was missed.**

---

### Step B15: Ship

Same as feature Step 16.

- **Re-verify branch sync.** Run `git log HEAD..origin/<base>` again. Baseline drift since B7 produces misleading diff output and noisy PRs. If drift exists, merge or rebase before drafting. Tagged class: `baseline_drift`.
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

**How to read these rules.** They are operational guidance, not a checklist of letters to satisfy. When a rule's scope is ambiguous in your specific case, **read by spirit, not by letter.** The cost of an unnecessary check is minutes; the cost of a skipped one is verifying the fix against an imagined state instead of an observed one. See the recurring `rule_literalism` entries in the Evolution Log (2026-04-09 "code inspection is not reproduction"; 2026-04-30 "UI-behavior scope") for cases where a rule's letter was followed and its spirit was missed — those are the failure mode this preface exists to prevent.

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
11. **Tautological tests are a class of test that cannot fail** — when the test fixture and the production code share a blind spot, no internal contradiction surfaces. Two common mechanisms: **value mismatch** — test mocks a hardcoded string the code uses literally (e.g., `Storage::fake("local")` mirroring `Storage::disk("local")`); **scope mismatch** — test activates a flag, feature, or permission in a scope the production code doesn't check (e.g., a Pennant flag activated globally while production reads it user-scoped). Mutation testing surfaces both. The structural fix is to refactor the code to read from a config or scope layer the test can drive, or to integration-test against the real boundary.
12. **Diagnosis claims must be discriminating** — before concluding root cause or shipping a fix, name a test (mutation or experiment) that should produce one observable result under the current theory and a *different* result under at least one named alternative theory. If the test confirms the theory, proceed. If it doesn't — or if no discriminating test can be named — root cause analysis continues. Applies at the B4→B5 and B12→B14 transitions. Analogous to mutation-testing for tests, applied to the diagnosis itself. The same discipline extends to **scope decisions** (in-scope vs out-of-scope, ship-or-pull, keep-or-refactor) when the decision hinges on whether an underlying issue is real: name a probe whose outcome forces one decision under one theory and the opposite under the alternative. If you cannot — or if you have not run it — the scope position is speculation. Applies at Step B6 (and Step 7 for features). Tagged class: `speculative_scope_defense`.

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
- Decision Log → persists choices *and the evidence that later overrode them* — *so they survive context loss, and so a mid-flight pivot reads as the workflow working*

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
| 2026-04-24 | Mutation testing each new test surfaces tests that don't actually discriminate against the bug they were written for — caught two cases (a test that passed regardless of the fix because it tested a different invariant; tests covering redundant ground while leaving a real gap elsewhere). | Added "mutation-test new tests (strongly recommended)" guidance to Step 9 and B8 — the multi-bit version of the red step. |
| 2026-04-24 | A test mocking `Storage::fake("local")` mirrored the production code's `Storage::disk("local")` hardcode; the test passed because the mock shared the bug. Shipped to production, caused user-visible data loss when the local filesystem was wiped on deploy. The workflow could not catch this class structurally — when the test and the code share the same blind spot, no internal contradiction surfaces for any process step to expose. | Added "tautological mocks" check to Step 9 / B8 (test writing) and named it as Rule 11. Generalizes beyond storage to any mockable infrastructure boundary (cache, queue, auth, external services, feature flags). |
| 2026-04-24 | Without ticket-level outcome tracking, evolution entries are faith-based: we believe the workflow improves but have no way to test it. Bug tickets in particular are unaudited — each one is a peira against dokime, but the workflow didn't ask "did this come from a known failure class? Did the rule for that class fail to catch it?" | Added classification sub-step to B4 (Root Cause Analysis): cross-reference each bug against the Failure Class Registry; classify as known-class (and why the rule didn't catch it) or new class (candidate for new evolution entry). Created `data/ledger.md` with per-ticket schema and Failure Class Registry. Drafted spec for `/dokime:log-ticket` skill. |
| 2026-04-24 | Visibility-only rules (Rule 11 and similar) need explicit prompt-level enforcement — naming the class isn't enough if engineers don't ask the question at the right moment. | Added Pass 3 to Step 11 / B10 code review: name shared hardcoded values between test and code; name a change to the production code that should make the test fail. Forces the recognition the Rule 11 abstraction depends on. |
| 2026-04-24 | Evolution entries lacked structured metadata for failure-class tracking, detection method, or gap type — making it impossible to detect recurrence or measure rule stickiness across the corpus. | Updated `/dokime:evolve` skill to capture `failure_class`, `detection_method`, and `workflow_gap_type` fields. Optional but strongly preferred for failure observations; blank for positive observations. |
| 2026-04-24 | Bug classification at B4 named the failure class but didn't trace bugs to their origin — losing the highest-value signal: which workflow version let which class through. | Added regression-check sub-step at B4: use `git blame` to find the introducing commit, cross-reference to a dokime ticket via commit message / spec file / ledger date. Three outcomes: dokime origin (record ticket + workflow version), pre-dokime origin, or unknown. Ledger schema extended with `origin_ticket`, `origin_spec_file`, `origin_workflow_version`. Direct regressions on specific dokime tickets are now the highest-priority data point in the corpus. |
| 2026-04-09 | On ICOV3-1069 Pass 2, skipped B3 (Reproduce) and went straight from B2 (Understand) to B4 (Root Cause) because the missing CoCard branch was visible in code inspection. Rationalized as "I don't need to run it to confirm what I already know." Virgil caught it: *"Why did we skip B3?"* Failure mode: **clarity of diagnosis is not permission to skip reproduction**. When the code reading feels certain, that certainty is exactly the thing that makes you dangerous — it's the same failure mode as "jumping to implementation before tests," just earlier in the flow. Without local reproduction, B12 Verify has no anchor — you're comparing the fix against an *imagined* broken state, not an observed one. | B3 is non-negotiable regardless of how obvious the root cause looks in source. Added explicit anti-pattern to B3: "If you read the bug in code and feel certain, that is exactly when you most need to run it." The obviousness of the diagnosis is irrelevant to the reproduction requirement — if anything, it's a warning sign that you're about to skip a checkpoint. |
| 2026-04-09 | I presented a root cause diagnosis to the human as a "does this look right?" checkpoint question without running an experiment to verify it. The human pushed back: "I am not a genie. We need to replicate or have some kind of experimental feedback to verify." I was presenting inference as diagnosis — skipping the experimental step that makes B4 a real checkpoint instead of a rubber stamp. | B4 now requires experimental falsification before the human checkpoint. State the hypothesis, state what would be observed if true vs false, design an experiment, run it, present evidence. Not "does this look right?" — "here is the evidence." Added anti-pattern to B4. |
| 2026-04-09 | After forming a root cause hypothesis, I placed targeted console logs at four state-observation points (Vue watcher, click handler, form capture, diff request) and confirmed the exact divergence in under an hour. Static code tracing alone would have taken significantly longer and produced less confidence. | B4 now explicitly recommends placing targeted logs at state-observation points — the specific locations where internal state becomes visible — as the fastest path to definitive diagnosis once the code path is understood. |
| 2026-04-09 | After the first fix attempt, console logs showed the Vue model was clearing correctly but the diff payload still didn't include the field. I was tempted to declare partial success. Sticking with the instrumented experiment revealed that programmatic Vue updates don't fire DOM input events — so the form capture pathway still missed the change. A second fix was needed. | B9 now includes "check every link in the causal chain" — after the first observable change, trace the fix through every downstream step. Partial success looks like success until you check the next link. |
| 2026-04-09 | Given the choice between "write a feature test that simulates the bug" and "actually run the system in the browser," Virgil said: "I say it's in the spirit of Dokime to click through on local and confirm the bug." UI reproduction uncovered three validation blockers a feature test would have bypassed. Each blocker was a real consequence of the system under test. | B3 now includes "UI reproduction > feature test" guidance. Feature tests are models; UI is reality. Blockers encountered during manual reproduction are themselves evidence that feature tests would have missed. |
| 2026-04-09 | To unblock each validation during UI reproduction, I patched test data (added cip_code_id and includes_lecture to CCNs, populated Summary tab fields). Each patch was a small divergence from production reality. Virgil asked: "Is this still in the spirit of Dokime?" | B3 now includes "enable, don't bypass" distinction. If the patch enables the code path under test to execute, that's enabling. If it skips the code path under test, that's bypassing. Document enablements for audit. |
| 2026-04-09 | ICOV3-1069 Pass 2 ran end-to-end cleanly through the full Bug Fix Workflow (B1–B15). One process violation (skipped B3, caught and reversed), one quality correction (magic strings → class constants at B8/B9, caught by Virgil), zero iterative debugging, zero rework. Clean-pass characteristics: diagnosis visible in source, pattern precedent already in codebase (PPSS), blast radius small and bounded, B13 Document was near-zero because docblocks were written inline during B9 Green, B10/B11 collapsed cleanly because the full suite ran without regressions on the first attempt. **Meta-observation worth logging separately:** both evolution-log entries from earlier the same day (Step 15 cross-repo completion rule + B3 "code inspection is not reproduction" anti-pattern) were operationally useful hours later — the cross-repo rule drove the B14 completion mapping, and the B3 anti-pattern almost repeated itself in the same pass. | No workflow changes needed — this is dokime running in its "well-formed inputs" mode. Documented as evidence that (a) the ceremony scales down cleanly on well-scoped bugs: it still surfaces an architecture decision at B8/B9 (const refactor), still maps acceptance criteria across repos at B14, still produces ship-ready PR drafts at B15 — value is proportional to the risk of silent errors, not proportional to lines of code changed; and (b) the Evolution Log is *operational*, not archival, on an active project — lessons written in the morning can save work the same afternoon. A workflow doc that lives on a shelf is just documentation; one whose lessons compound within the same session is a tool. |
| 2026-04-13 | A bug was reclassified from "open" to "resolved" based on a single positive Twilio log entry for a different program + different award type than the one originally reported. Shipped a symptom-level fix based on a true bug found during code inspection (wrong preference-key check), then closed the loop. Bug recurred in QA the next week because the fix didn't address the reported symptom — the symptom was caused by missing env config, not the preference-key bug. Category confusion (different award type) masqueraded as resolution. Confused "a true bug I found in the file" with "the root cause of the observed symptom." *Submitted via `/dokime:evolve` — first entry from the evolution feedback loop.* | B4 now includes isolation test (step 7): "Would this fix, by itself, produce the observed behavior if applied in isolation?" Bugs found during inspection are evidence, not diagnosis. B2 now includes reclassification trap: when positive evidence suggests a bug is resolved, verify the evidence matches the original report's specific trigger (notification type, program, user role). Evidence from a different trigger proves a different code path works. |
| 2026-04-24 | The kill discipline was named in methodology ("kill honestly") but not operationalized — no machinery for *making* kills happen. Rules accumulated as ceremony; sunk-cost and over-coverage bias prevented removal. Without explicit kill mechanics, the workflow had generation, articulation, tracking, and testing but no closing action when reality said no. | Added Killed Rules / Steps / Metrics section below the Evolution Log. Kill criteria specified per artifact type (Rule / Step / Process metric). Kill action specified (delete the line, log the kill, bump version). Reversibility preserved — original entries stay in Evolution Log; kill entries reference them. Companion Kill Queue lives in the local ledger as the running list between quarterly reviews; Kill Log here records committed actions. Closes the variation→selection→retention loop the workflow had been claiming but not executing on its own rules. |
| 2026-04-30 | A bug ticket sourced from an older training-session transcript framed a historical vulnerability as a present-tense bug. Three B3 reproduction-attempt tests all showed the system was correctly handling the described attack vectors. RAG search of the same source corpus revealed a December 2025 incident (real financial loss) had been resolved same-day by reverting the offending commit + a follow-on safeguard pipeline. The symptom narrative was preserved in the transcripts; the fix narrative was preserved alongside it but was not checked at B2. Reporter confirmed live: bug is fixed. The 3 reproduction-attempt tests became regression sentinels instead of becoming a wasted day. The workflow surfaced the *absence* of a bug plus locked in safeguards against its return — value was in the ceremony, not in shipping a fix. *Submitted via `/dokime:evolve` 2026-04-29.* | B2 now has a symmetric reclassification trap entry: when a ticket is sourced from an older transcript / channel / corpus, scan the same source for *resolution* evidence (terms like "fixed", "resolved", "reverted", "safeguard", "incident") before classifying as an active bug. Counterpart to the existing 2026-04-13 entry (false-resolved direction); this is the false-active direction. Tagged class: `reclassification_trap` (extended to cover both directions). |
| 2026-04-30 | Step 8 established a clean 226-test baseline. Six steps later at Step 16, `git diff origin/qa --stat` showed files I never touched (StatementService.php, MigrateProgramsService.php, etc.) because origin/qa had moved 4 commits ahead during the day. The 12-file PR appeared as a 13-file diff with hundreds of lines of unrelated noise until the branch was merged with current qa. The baseline-vs-PR-diff signal silently degraded as the workflow progressed; a sync check at Step 8 would have surfaced this proactively, and a re-check at Step 16 would have caught it before it confused the deliverable. *Submitted via `/dokime:evolve` 2026-04-29.* | Added explicit `git log HEAD..origin/<base>` sync check to Step 8 / B7 (establish baseline) and Step 16 / B15 (PR packaging). Surfaces drift at both ends of the workflow. New failure class: `baseline_drift` (structural). |
| 2026-04-30 | At Step 9 in a refactor (replacing one implementation with another), 17 of 30 new tests were green against current production code AND the new implementation. They were intended as regression sentinels. Per the workflow rule "if a test passes before you write the implementation, it isn't testing anything," this should have triggered scrutiny — but I claimed mutation tests would discriminate without running them. The user challenged: "if the test always passes then it's kind of worthless." When I actually mutated the production code, several tests indeed didn't fail — confirming the user's instinct. The workflow's "strongly recommended" mutation testing was treated as optional. *Submitted via `/dokime:evolve` 2026-04-29.* | Promoted mutation testing in Step 9 from strongly-recommended to **required for refactor sentinels** — tests green against both pre- and post-refactor code. Refactor sentinels by definition have no red→green discriminator in their lifecycle; mutation testing is the only mechanism that proves they're not tautological. Step 11 / B10 Pass 3 updated: hypothetical mutations don't count — run them. Tagged class: `tautological_test` (refactor variant). |
| 2026-04-30 | A trait being refactored had a latent bug (raw `$this->table` property access — empty on factory-fresh instances, populated only when models are loaded via Eloquent query hydration). Production code paths always go through query hydration, so the bug never surfaced in production. Service-level tests using `Model::where(...)->get()` also went through query hydration and silently fixed the bug at runtime — so a service-level integration test could not reproduce or discriminate against the trait bug, only against catastrophic future regressions. Unit-level tests using factory-fresh instances WERE able to discriminate. *Submitted via `/dokime:evolve` 2026-04-29.* | Step 6 (codebase analysis) now includes "Identify framework lifecycle dependencies" — when the refactor target reads from framework lifecycle state (Eloquent `$table`/`$exists`/attributes; Symfony container resolution; Rails ActiveRecord initialization; React lifecycle), note it explicitly. Step 9 now distinguishes service-level integration tests (production paths, may auto-populate state) from unit-level tests on factory-fresh instances (can discriminate against abstraction bugs). Both layers usually needed. New failure class: `lifecycle_state_masking` (structural — same family as `tautological_test` but mechanism is path-sharing, not value/scope-sharing). |
| 2026-04-30 | An "Enable automatic retry" admin checkbox persisted in DB and rendered in UI but no decision-making code consumed it — `isEnabled()` was read only by the admin form read-back; no retry-decision code consulted it. QA reproduced the symptom (failures landing in Pending Sync regardless of toggle). Direct regression on a specific dokime ticket whose origin commit predates the 2026-04-24 Pass 3 review rule. The Pass 3 check ("name a change to the production code that should make this test fail") applied to the setting-persistence test would have surfaced the gap — no test verifies the setting *affects* behavior. Generalizes beyond MIS context: any admin-configurable setting added without a corresponding behavior-effect test is a candidate. *Submitted via `/dokime:evolve` 2026-04-30.* | Step 11 / B10 Pass 3 extended with a "setting-shaped surfaces" check: for each admin-configurable surface (checkbox, toggle, threshold, feature flag, env-driven config) introduced or changed, name (a) at least one consumer that reads the value and changes behavior, and (b) at least one test that exercises the *effect* on behavior, not just persistence. New failure class: `unwired_admin_setting` (structural). |
| 2026-04-30 | An existing test asserting "widget hidden for reviewer role" passed for the wrong reason. The test setup activated a Laravel Pennant feature flag without user-scoping it to the reviewer test user. Production code `Feature::active()` ran in the authenticated user context and short-circuited to false because the user-scoped flag was never activated — the role gate was never evaluated. Test passed because the flag check failed, not because the role gate worked. Same structural pattern Rule 11 names for infrastructure mocks (storage, queue, cache fakes), but with a different mechanism: scope mismatch instead of value mismatch. Caught only because a parallel new test in the same file mirrored the same setup and was flagged at red-step (passed without the production fix in place); investigation revealed the existing reviewer test had been tautological since written. *Submitted via `/dokime:evolve` 2026-04-30.* | Generalized Rule 11 from "tautological mocks" (value-mismatch only) to "tautological tests" (value mismatch *and* scope mismatch). Pass 3 of code review (Step 11 / B10) now asks for shared values *and* shared scopes (user, team, role, request context). Synced Step 9 / B8 wording with Step 11 Pass 3 (feature flags now listed in both). Plugin version bumped to 1.4.0 — Rule 11 is public-facing. New failure class registered as `tautological_test` (umbrella) with `tautological_mock` (value-mismatch) as the original instance and the Pennant case as the scope-mismatch instance. |
| 2026-04-30 | Dispatching a domain-specific expert agent at B6 (Blast Radius and Fix Proposal) caught two real corrections that general review would not have produced: (1) the proposed fix added a constructor parameter to a service, but the expert pointed out that the necessary dependency was already reachable via an existing injected service — adding a thin proxy method on the existing service eliminated a 10-site test fan-out and respected SRP boundaries; (2) the expert flagged that the production scheduler was already gated upstream in the console kernel, meaning half of the bug was defense-in-depth for direct invocation paths rather than a separate live production bug — sharpening the PR description framing materially. Both corrections required domain-specific code knowledge a general review would not have surfaced. *Submitted via `/dokime:evolve` 2026-04-30.* | Step 7 / B6 now explicitly recommend dispatching specialized agents at proposal time, not only at code-review time. The earlier the dispatch, the cheaper the correction: at proposal a course change is a one-line spec edit; at code review it's a re-implementation. Step 11 / B10 Pass 3 also notes that late dispatch is a second look, not a first one — if early dispatch was skipped, that's the cheaper miss to fix going forward. |
| 2026-04-30 | B9 visual smoke test ("If the fix affects UI, load it in the browser before proceeding") was almost skipped for a fix that touched zero view files. The fix was service-layer code only. But the user-visible effect was which dashboard tile a record landed in (Pending Sync vs. Failed) — a UI behavior change despite no view file edits. Reading the rule literally as "if you edited a blade file" was the trap. The human caught it ("did we skip the UI verification step?") and the resulting smoke test produced real visual evidence (pre-fix vs. post-fix course state contrast) that anchored B12 verification. Skipping would have left B12 verifying the fix against an *imagined* post-fix state. Same class as the 2026-04-09 "code inspection is not reproduction" anti-pattern at B3 — both are cases where the engineer literalizes a rule's wording and rationalizes skipping a checkpoint that the rule's spirit required. *Submitted via `/dokime:evolve` 2026-04-30.* | Reworded B9 / Step 10 / B12 / Step 13 visual-smoke-test scope: "user-visible behavior on a UI surface — including changes to which state, count, list, or tile a record appears in. UI-behavior change includes side effects of service-layer code that surface in views, even when no view file was edited." Added a Rules-section preface ("How to read these rules") establishing read-by-spirit-not-by-letter as the meta-principle. New failure class: `rule_literalism` (discipline / meta) — recurring pattern across 2026-04-09 (B3) and 2026-04-30 (B9). |
| 2026-04-30 | I asserted webpack-dev-server's behavior ("WebSocket close handler calls `window.location.reload()`") to the human as the bug's mechanism, and the human passed that explanation up to a stakeholder before I had verified it against the actual library source. When the human pushed back later with "how can we confirm" — a B4 discipline question — I read the actual webpack-dev-server v4 source bundled in the production bundle and discovered the close handler does NOT call reload at all (it only logs "Disconnected!" and reconnects). The reload is triggered by a different path entirely (hash-mismatch on reconnect via reloadApp). This was the second time in the session that the human's "how can we confirm" question caught a confidently-asserted-but-unverified claim from me. *Submitted via `/dokime:evolve` 2026-04-30.* | B4 / B6 now include explicit "AI-asserted library mechanism" anti-pattern: any "library X does Y when Z" claim about library or framework internals must be verified against actual library source (grep + read) before being relayed to the human or to stakeholders. Cheap to verify; expensive when wrong. New failure class: `unverified_library_mechanism_claim` (discipline; AI-specific). Connects to the Paulson 2026 case study — *do the worrying the LLM can't*. |
| 2026-04-30 | I framed the bug's apparent root cause ("dev-mode bundle on production") as something the deployment team should "fix," and drafted Slack/Jira messages framing it as a misconfiguration. The human pointed me at a team transcript from the previous day's tech heartbeat meeting where the dev-mode-on-prod arrangement was discussed as deliberate architecture (in transition to build-based serving on a separate roadmap). The framing was wrong: the team's existing state was an intentional choice with known tradeoffs, not a mistake to correct. Recommending changes to it as "fixes" without first checking whether it's deliberate would have created friction. *Submitted via `/dokime:evolve` 2026-04-30.* | Step 7 / B6 now include a deliberate-state check: before proposing changes to deployment, infrastructure, or shared architectural state (anywhere outside the layer you own), check whether the current state is deliberate. Sources: project CLAUDE.md, recent session logs, recent meeting transcripts, recent Slack on the topic. Different from the B2 reclassification trap (which catches "this bug is already resolved" claims); this catches "this state is a bug" claims about *deliberate* architectural choices. New failure class: `deliberate_state_misclassified_as_bug` (discipline). |
| 2026-04-30 | Diagnosis went through three iterations on the same bug, each producing a coherent-looking single-mechanism theory that fit the evidence at the time but turned out to be wrong or incomplete. Iteration 1: "WebSocket close triggers reloadApp" — falsified by bundle source read. Iteration 2: "dev-mode bundle weight is too heavy for iOS" — falsified by Test B (production build still reloaded). Iteration 3: "carousel autoplay continuous activity is the trigger" — confirmed correct by Test C (dev mode + autoPlay=false stable). At each iteration I was confident enough to propose moving forward (PR shape, deploy handoff, etc.). Each iteration was advanced only because the human pushed for one more discriminating experiment. *Submitted via `/dokime:evolve` 2026-04-30.* | Added Rule 12: "Diagnosis claims must be discriminating" — before concluding root cause or shipping a fix, name a test (mutation or experiment) that should produce one observable result under the current theory and a *different* result under at least one named alternative theory. If the test confirms the theory, proceed. If it doesn't (or no discriminating test can be named), B4 continues. Generalizes Step 9 / B8's mutation-test rule from "is this *test* discriminating?" to "is this *diagnosis* discriminating?" Applies at B4→B5 and B12→B14 transitions. New failure class: `non_discriminating_diagnosis` (discipline). |
| 2026-05-14 | A request field downstream code read was silently dropped by Laravel `FormRequest::validated()` — no rule covered the key, so `validated()` returned without it and the `isset()` guard was always false; the feature no-op-ed with no error. Discriminating experiment confirmed: same payload/rules, `all()` had the field, `validated()` did not. *Submitted via `/dokime:evolve` 2026-05-14.* | Step 11 / B10 Pass 3 add a "Request-field coverage" check. New failure class: `validated_strips_unruled_field` (structural). |
| 2026-05-14 | At B4, `git blame` showed the root-cause code was ~3.5 years old, so the bug was classified broken-from-birth (`origin_workflow: N`). Wrong: it was a 9-day-old regression — a framework major-version upgrade silently changed `validated()` to strip unruled nested-array keys. The human reopened the approved B4 checkpoint with external evidence. *Submitted via `/dokime:evolve` 2026-05-14.* | B4 origin trace extended: `git blame` finds where the code was written, not when the behavior broke. When blame shows old code but a new symptom, check the regression window for a framework/dependency behavior change before classifying origin. New failure class: `framework_upgrade_behavior_regression` (structural). |
| 2026-05-15 | A dead/unwired parameter (threaded through three helpers, never supplied by the only caller) was the AC4 correctness bug: its absence forced a fallback to global store state that returned a wrong count. R4-B normally catalogs an unwired param as a complexity `Consider:`. *Submitted via `/dokime:evolve` 2026-05-15.* | R4-B (dokime-review) adds a "dead parameter forcing a degraded path" cross-check — escalate from complexity-`Consider:` to functionality-`Blocker:` when the dead param's absence forces a fragile fallback. New failure class: `unwired_param_forces_degraded_path`. |
| 2026-05-15 | R5's blanket confidence floor (default 80) would silently filter a borderline-confidence Partial AC verdict from R4-AC — contradicting R4-AC's "no silent partials" contract. Hit on AC5 in a real review at the boundary. *Submitted via `/dokime:evolve` 2026-05-15.* | R5 (dokime-review) now exempts R4-AC verdict comments from the confidence floor: Partial/Missing AC always surfaces; the score annotates, never suppresses. Floor applies only to R4-A..F findings. |
| 2026-05-15 | A code-review response committed to a refactor on the spec's in-scope rationale without noticing a later same-session finding (in the session log) had already superseded it. Two documents holding the same decision drifted apart within one session; human pushback forced the cross-document re-read and the in-scope code was pulled. *Submitted via `/dokime:evolve` 2026-05-15.* | Step 15 / B14 Completion Check add a "reconcile decision rationale across artifacts" sub-step: re-verify before ship that no later same-workflow finding contradicts an earlier scope decision. New failure class: `after_finding_supersession` (discipline). |
| 2026-05-15 | A scope decision (keep a defensive perf trim?) was defended via speculation for ~30 minutes with no decisive answer. The human pivoted to "test rather than speculate"; a payload-size probe + clean-session repro answered it in under 5 minutes and the code was pulled. *Submitted via `/dokime:evolve` 2026-05-15.* | Rule 12 extended from diagnosis to scope decisions; new B6 sub-step "Probe scope decisions, don't defend them." New failure class: `speculative_scope_defense` (discipline). |
| 2026-05-15 | A Step 4 architectural decision was overridden at Step 9 when a refactor sentinel went red. Step 10 pivoted; the Decision Log absorbed both the original decision and the overriding evidence with no workflow restart — the decisions-log-captures-WHY principle handling a mid-flight pivot as designed. *Submitted via `/dokime:evolve` 2026-05-15.* | One-line clarification at Step 4 and the Decision Log clause: a pivot driven by later evidence (sentinel red, composition check) is the workflow working, not a process violation requiring restart. |
| 2026-05-15 | A 1-point feature ticket grew into a 7-file, ~600-line PR through 8 refactor expansions. Because each expansion was asked one at a time (do-it / sibling-ticket / leave-alone) rather than batched, the human gated every one and stopped expansion at item 7. *Submitted via `/dokime:evolve` 2026-05-15.* | Step 10 adds a "refactor expansion — ask one at a time, count the cumulative" note: out-of-Step-7-scope refactors get one-at-a-time approval with the running cost named. |
| 2026-05-18 | On a React/Jest component test (B8), spy bindings were drafted as plain identifiers. Jest hoists `jest.mock()` factories above imports and rejects out-of-scope references not prefixed with `mock` — `ReferenceError`, costing a failed run plus cascading edits. *Submitted via `/dokime:evolve` 2026-05-18.* | Step 9 / B8 add a Jest-conditional note: name all mock/spy bindings with the `mock` prefix from the start. New failure class: `jest_mock_hoisting_pitfall` (structural). |
| 2026-05-18 | A bug-ticket AC was drafted before Sentry breadcrumbs were pulled — its recipe ("network offline") encoded the author's assumption; breadcrumbs showed the production-frequency trigger was an HTTP 500 wrapped by a response interceptor. *Submitted via `/dokime:evolve` 2026-05-18.* | B2 adds an "AC-vs-evidence drift" trap — third sibling to the two reclassification traps, operating on the AC layer; B5 adds a bullet to resolve flagged drift before B8 test design. New failure class: `ac_drafted_before_evidence` (structural). |
| 2026-05-18 | A wrapped-response Axios interceptor (introduced Feb 2026, expanded April 2026) reshaped error payloads; callers written against raw-Axios semantics read field paths the reshaped payload didn't have — TypeError cascading `.then`→`.catch`→double-throw. The class recurred within hours on a sibling ticket from the same interceptor change; combined 216 users / 423 events. *Submitted via `/dokime:evolve` 2026-05-18 (two submissions, same session).* | B6 / Step 7 add a mandatory "wrap/reshape layer audit" — when a fix touches an interceptor/middleware layer, sweep every consumer for shape assumptions across the layer's full output domain. New failure class: `interceptor_contract_violation` (structural). |
| 2026-05-18 | On a ticket where ambiguity A2 was locked at B5 as "out of scope," B9 visual smoke showed the post-fix experience ("stuck on loading…") failed the AC's spirit. B5 was reopened, expansions explored and reverted, and the minimum-scope fix shipped with a banked sibling — the spec capturing the back-and-forth. *Submitted via `/dokime:evolve` 2026-05-18.* | B5 adds a bullet: B5 decisions are reopenable at B9 — do not accept a passing-tests-but-failing-UX result; the reopening is the audit trail. |
| 2026-05-18 | A dispatched specialized agent recommended bundling a latent fix, framed "almost certainly contributing to the Sentry signature." The Sentry breadcrumb shape (single breadcrumb = initial-load crash) directly contradicted the claim; the human overrode on evidence-first grounds and shipped minimum scope. *Submitted via `/dokime:evolve` 2026-05-18.* | B6 / Step 7 add an "apply evidence-first discipline to agent claims" note — hold an agent's inferential, scope-expanding claims to the same evidence standard as a peer's verbal dismissal. New failure class: `agent_speculation_unverified` (structural). |
| 2026-05-18 | A 1-character fix passed all 8 unit tests and met the literal AC, but B9 visual smoke showed a blank page with a transient flash banner — technically compliant, obviously unacceptable. ~30 minutes of scope iteration followed; the minimum-scope fix was confirmed correct with the UX problem banked as an architectural sibling. *Submitted via `/dokime:evolve` 2026-05-18.* | B9 reinforced: visual smoke is where minimum-scope meets user experience; passing-tests-but-failing-UX is a real outcome class; expect iteration. |
| 2026-05-18 | B4 landed the right fix but the wrong reasoning ("non-strict compare mishandling multi-word entries") — the actual root cause was that the data array diverged from the sort convention its three sibling arrays in the same file followed. The human's "is this consistent with the rest?" surfaced it. *Submitted via `/dokime:evolve` 2026-05-18.* | B4 adds a "sibling-pattern check" sub-rule — compare a candidate root cause against its siblings in the same file/module; convention-divergence and isolated-bug produce different fix shapes. New failure class: `sibling_pattern_blind_diagnosis` (discipline). |
| 2026-05-18 | B3 local reproduction was skipped on a data-only fix; the skip didn't bite because external evidence (a production video) anchored B12, the fix changed no logic, and the consumer applied no transform. The 2026-04-09 "code inspection is not reproduction" rule has no exemption carve-out for cases where local repro adds nothing external evidence isn't already providing. *Submitted via `/dokime:evolve` 2026-05-18.* | B3 adds a narrow three-condition exemption: external reproduction evidence + data/config-only fix + no transform between source and output. If any condition fails, B3 is non-negotiable. New failure class: `b3_exemption` (discipline). |
| 2026-05-20 | During B3 reproduction of a stack-trace-leak security bug, the test crashed PHP with an out-of-memory fatal at the leak site — the deep trace serialized into the response. The crash was empirical evidence of a latent DoS surface on top of the named info leak. *Submitted via `/dokime:evolve` 2026-05-20.* | B3 adds guidance: a crash during reproduction can be a discovered secondary failure mode — document it before bypassing it (raising memory limits, switching test paths). New failure class: `diagnostic_signal_bypassed` (structural). |
| 2026-05-20 | A fix touched three surfaces (controller catch, global exception handler, new middleware); the handler edit removed env-gating that was already evaluating correctly in production. The human caught it ("is this only changing non-prod?"). Scope had quietly crept. *Submitted via `/dokime:evolve` 2026-05-20.* | B6 / B9 add a "multi-surface fix audit" — when a fix touches multiple surfaces, audit each independently: production concern, or consistency-tightening on a non-leaking path? New failure class: `multi_surface_scope_drift` (structural). |
| 2026-05-20 | An API-only fix (no Blade/view touched) had its B9/B12 visual smoke dismissed as "not applicable." The human corrected it — API consumers (SPAs, mobile, integrations) are users; the JSON response shape is the user-visible surface. *Submitted via `/dokime:evolve` 2026-05-20.* | B9 / B12 (and the mirrored Step 10 / Step 13) smoke-test wording clarified to explicitly cover API JSON response shape/content: run a real `curl` and a real UI smoke through a consumer. `rule_literalism`, same family as the 2026-04-30 entry. |
| 2026-05-21 | Step 8 captured the test baseline as a pass/fail count (86 failures); Step 12 compared 91 vs 86. But the suite ran against a shared, populated database with no test-DB isolation, so the count drifts run-to-run from data, not code — the comparison was invalid. The real signal was the failing-test set. *Submitted via `/dokime:evolve` 2026-05-21.* | Step 8 / B7 add a test-DB-isolation check; Step 12 / B11 diff the failing-test set (name + file), not the count, when the DB is not isolated. New failure class: `no_test_db_isolation` (structural). |
| 2026-05-21 | A new write endpoint was placed in the stateless `api` route group (no session middleware); a session-cookie SPA calling it via XHR got 401. All 19 backend tests passed because Pest `actingAs()` sets the guard user directly and never exercises session middleware. Only manual Verify caught it. *Submitted via `/dokime:evolve` 2026-05-21.* | Step 7 adds "route middleware group must match how the client authenticates"; Step 9 adds a note that `actingAs()` bypasses the real auth-middleware path — a route-group/middleware assertion or guest-request test is needed. New failure class: `stateless_route_group_masked_by_actingas` (structural). |
| 2026-05-21 | A controller read a feature flag via per-user `Feature::active()` while the production enable path wrote a global/null-scope activation — the two never met and the endpoint 404'd despite the flag showing enabled. Tests passed because `setUp()` used a resolver true for every scope. Step 9 Pass 3 named the scope-mismatch risk, then concluded "flag is global — no risk." That conclusion was wrong. *Submitted via `/dokime:evolve` 2026-05-21.* | Step 11 / B10 Pass 3 and R4-C: a scope check must name three concrete scopes (production reads / test drives / enable path writes) and confirm all agree — a no-risk conclusion reached without naming all three is itself the failure. `tautological_test` (scope-mismatch variant). |
| 2026-05-21 | `/dokime:workflow` was invoked on an already-in-progress ticket — the spec file existed (populated through Step 12) and the feature branch carried committed work — but the workflow starts unconditionally at Step 1, so the resume point had to be improvised. *Submitted via `/dokime:evolve` 2026-05-21.* | Step 1 adds a "resume vs. start" branch: check for an existing spec file and resume from the last completed step it records rather than restarting. New failure class: `workflow_resume_unhandled` (structural). |
| 2026-05-21 | The human checkpoint is only as effective as the human's understanding of what they're approving, but Steps 10 and 16 present changes mostly as prose and raw tool output — the reviewer has to reconstruct the change set themselves. *Submitted via `/dokime:evolve` 2026-05-21.* | Step 10 and Step 16 add a requirement to present the full change set for a reader not in the AI context — per-file what-changed-and-why, before/after snippets for non-obvious edits, simple diagrams for flow or structural changes. Teach the change, don't just list it. |

When a Rule, step, sub-step, or process metric is removed because it didn't earn its keep, log it here with a reference to the original Evolution Log entry that introduced it. The original entry stays in place (history is preserved); the kill entry references it. If a killed item is later revived because the class it protected against returns, log a new Evolution Log entry referencing both the original and the kill.

| Date Killed | Original Entry (Date / Description) | Reason for Kill | Evidence | Reversal Conditions |
|-------------|--------------------------------------|-----------------|----------|---------------------|
| 2026-04-24 | 2026-04-24 / Historical replay as mechanism-validation protocol — proposed during v1.3.1 build session as a way to test whether the audit loop produces useful signal on bugs we already shipped | The bugs in the historical corpus weren't fixed via dokime, so retroactive replay can't validate the workflow — only the classifier's vocabulary. Confused "mechanism can describe past data" with "mechanism prevents future failures." Same-session peira: methodological gap identified on first read; the replay would have produced manual-classification labor without producing a mechanism-validation outcome. | Conversational pushback in the same session that proposed it. The proposer (Claude) couldn't defend the framing once asked what it actually shows. | Revisit if a forward-looking quarterly review reveals that retrospective replay would have surfaced patterns missed in real time. Until then: forward-only peira. |

**Kill criteria (when an item earns a kill):**

- **Workflow Rule** — named class hasn't appeared in M months (M ≥ 6 by default) AND rule has been skipped on N+ tickets without negative outcome correlation
- **Step / sub-step** — skipped on N consecutive tickets with no outcome difference; engineer feedback flags as ceremony
- **Process metric (ledger field)** — no correlation with any outcome metric after Q quarterly reviews

**Kill action (what file changes when):**

- Workflow Rule: remove the line from the Rules section (don't comment it out — actually delete it). Add Kill Log entry above. Bump plugin version (rules are public-facing).
- Step / sub-step: demote (mandatory → recommended → consider → remove) at quarterly review cadence. Each demotion is a separate Kill Log entry.
- Process metric: remove from ledger schema. Existing rows keep the data; new rows omit the field.

**Reversibility:** killed items are not deleted from history. The original Evolution Log entry stays. The Kill Log entry preserves why it died. If the class returns and the rule needs reviving, a new Evolution Log entry says "Revived: [original date]" and the Kill Log entry is annotated "superseded by [revival date]."

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
