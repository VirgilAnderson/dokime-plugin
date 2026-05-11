# Dokime Review

**Author:** Virgil Anderson
**Created:** May 2026
**Last Updated:** May 11, 2026
**License:** All rights reserved. This workflow is the intellectual property of Virgil Anderson.

---

A structured code review workflow for pull requests. Verifies that the PR does what the ticket says it should do, surfaces issues that a reviewer would genuinely raise, and produces output you can paste straight into Bitbucket.

## What This Workflow Is

The companion to `/dokime:workflow`. Where the workflow is a communication protocol *while you write code*, this is a communication protocol *while you read someone else's code*. It executes the Pass 3 review pattern (Rule 11, Rule 12, specialized agents, setting-shaped surfaces, lifecycle state masking) against a PR branch instead of against your own work-in-progress.

## What Code Review Is For — And What It Isn't

A structured empirical claim from Bacchelli & Bird's 2013 study of 1,038 developers at Microsoft (Bacchelli & Bird 2013, §V): a card sort of 570 actual review comments found that **defect-finding comments comprised only 14% of comments**, while **code-improvement comments comprised 29%**. The remaining majority covered understanding, alternative solutions, knowledge transfer, and team awareness. Most defect comments were "micro" (corner cases, operator precedence, exception handling) — not macro design issues.

Their recommendation, verbatim: *"Relying on code review in this way for quality assurance may be fraught."* And from a senior developer they interviewed: *"In some ways it's kind of embarrassing if someone asks you to do a code review and all you can find are formatting mistakes when there are real mistakes to be found."*

Sadowski et al.'s 2018 study of 9 million reviews at Google reached a complementary conclusion (Sadowski et al. 2018, §4.1): code review was introduced at Google primarily to *force developers to write code other developers could understand*, not as a primary bug-finding mechanism. The same paper found that 80% of changes go through at most one iteration of comments — modern review at scale is fast and light, not exhaustive.

**What this means for this skill:**

This workflow will catch some bugs. But its primary value is the *other* outcomes review research has measured: surfacing AC drift, naming the design tension before the implementation locks it in, flagging tautological or lifecycle-masked tests, raising knowledge-transfer notes for future readers, distributing understanding across the team. The skill should not over-promise as a bug-finder; CI and tests catch most of those, and Pass 3 catches the structural ones.

Two failure modes this skill exists to prevent:

1. **Approving a PR that doesn't do what the ticket says** — the code is well-written, the tests are green, but the acceptance criteria are partially or silently unmet. CI doesn't catch this; reviewers who only read the diff don't catch this. The defense is mapping every AC line to evidence in the diff and verdicting each one.

2. **Drowning the author in low-signal nits** — most automated review tools produce a wall of "consider renaming this", "consider extracting that." The author tunes them out. Real issues get lost. The Anthropic 0-100 confidence rubric with <80 filter, combined with explicit severity labels (Nit / Optional / Consider / FYI / Blocker), is the defense.

## The Standard of Code Review

From Google's published Code Reviewer's Guide (Google 2026, "The Standard of Code Review"): *"Reviewers should favor approving a CL once it is in a state where it definitely improves the overall code health of the system being worked on, even if the CL isn't perfect."*

Also: *"There is no such thing as 'perfect' code—there is only better code."*

This is the standard this skill applies. The default verdict is **approve unless blocker**, where a blocker is something that would degrade the codebase's overall health. Style preferences are not blockers. Nit-level cleanups are not blockers. Design problems that materially harm maintainability are blockers. Functionality gaps against the ticket's AC are blockers. Tautological tests (Rule 11) are blockers because they create false confidence in correctness.

## How to Read These Rules

Operational guidance, not a checklist of letters to satisfy. The Bitbucket-flavored output format, the confidence threshold, the agent dispatch list — these are calibrated defaults, not commandments. When the situation makes the default wrong, **read by spirit, not by letter.** The cost of an unnecessary comment is a few seconds of the author's attention; the cost of a skipped check is a real bug shipping. See the recurring `rule_literalism` entries in `agents/dokime.md` for the failure mode this preface exists to prevent.

## Cost

A real review pass through this workflow on a 12-file PR takes 5-15 minutes of wall time. Most of that is parallelized agent work. Sadowski found Google developers spend ~3.2 hours/week on review (Sadowski 2018, §6.2); this skill is in roughly the right cost range for that budget.

The cost worth thinking about is **author trust**. A review skill that produces three high-confidence comments per PR builds trust; one that produces twenty mixed-confidence comments destroys it. Default behavior is calibrated for trust-building: filter <80, no nitpicks unless explicitly labeled `Nit:`, no comments on pre-existing code, no comments on issues CI catches.

---

## Configuration

Check for `.claude/dokime-config.json` in the project root. Useful fields:

```json
{
  "project_type": "laravel | node | python | mixed",
  "test_paths": ["tests/", "src/**/__tests__/"],
  "specialist_agents_dir": ".claude/agents/",
  "default_base_branch": "qa",
  "bitbucket_workspace": "<workspace>",
  "jira_project": "<key>"
}
```

If the file doesn't exist, ask the human for the values you need. If a value isn't provided, fall back to detection:

- Project type: read `composer.json`, `package.json`, `pyproject.toml`, etc.
- Test paths: glob common locations
- Specialist agents: scan `.claude/agents/*.md`
- Base branch: try `qa`, `develop`, `main`, in that order; ask if none resolve

---

## Inputs (Conversational)

The skill collects what it needs by asking. Each prompt accepts a paste OR a path.

1. **PR branch.** "Which branch is the PR?" — accept `origin/feature/icov3-1500` or `feature/icov3-1500`.
2. **Base branch.** Default from config or detection; show the default and accept override.
3. **Ticket ID + description.** Accept (a) a paste of the ticket body, (b) a path to a file containing the description, or (c) "fetch" if a Jira MCP is configured. The skill needs the Acceptance Criteria (AC) and the ticket's *why* explicitly — if the paste doesn't include AC, ask.
4. **Confidence threshold.** Show default (80). Accept override.
5. **Specialist dispatch.** Show matched agents from R4(e). Accept override (skip / different subset).

Do not proceed past R1 without confirmed AC. The whole point of R3 is AC conformance; if AC is vague or missing, the review cannot verdict the PR. In that case, **the first comment is "AC is not specified — please add explicit AC before review"** and the workflow halts.

---

## R0: Setup & Eligibility

**Fetch and verify.**
```bash
git fetch origin <base> <branch>
git rev-parse --verify origin/<base>
git rev-parse --verify origin/<branch>
```

**Eligibility gates** — if any fire, stop and report:

- Branch already merged into base (`git merge-base --is-ancestor origin/<branch> origin/<base>` returns 0)
- Branch has no commits ahead of base (empty diff)
- Branch is marked draft (if Jira/PR metadata available)
- Branch is the base branch itself
- The repo is not the one you expected (check `git remote get-url origin`)

**Size pre-check.** Sadowski's median Google change is 24 lines; 90% of changes modify <10 files (Sadowski 2018, §5.2). Google's own developer guide states *"100 lines is usually a reasonable size for a CL, and 1000 lines is usually too large"* (Google 2026, "Small CLs"). If this PR exceeds **1000 lines OR 30 files** (and is not a deletion-only, generated-code, or trusted-refactoring CL), surface immediately:

> This PR is unusually large (N lines across M files). Large reviews produce fewer useful comments per line and longer latency. Consider asking the author to split it before reviewing. Proceed anyway? (y/n)

If the human says proceed, continue but flag the size in the final summary. If they say no, the workflow halts with a "request split" output.

**Detect project type.** Read manifest files; record what you find (Laravel, Vue, both, Node, Python, mixed). This shapes which specialist agents are relevant and what test paths to glob.

**Read project CLAUDE.md if present.** It governs project-specific style and patterns. Note its contents but do not promote its style guidance into review comments unless the diff directly violates a rule stated there. CLAUDE.md is guidance to authors, not a rule book to enforce against them.

---

## R1: Parse Ticket and Check CL Description

**CL description quality check.** Per Google's CL Author Guide (Google 2026, "Writing Good CL Descriptions"): the first line should be *"a short summary of what is being done … written as though it was an order"*; the body should *"fill in the details and include any supplemental information a reader needs to understand the changelist holistically."* Bad descriptions named explicitly: "Fix bug", "Fix build", "Add patch", "Moving code from A to B", "Phase 1".

If the PR description is bad (vague single line; no rationale; doesn't reference the ticket), surface it as the **first Blocker comment**:

> The PR description doesn't explain the *why*. Per the team standard, the description should include: (a) a one-line imperative summary, (b) the problem this solves, (c) the approach, (d) any tradeoffs. Author: please update before re-review.

This matters because Bacchelli's central finding is that **understanding is the dominant challenge in review** (Bacchelli & Bird 2013, §VI.A): *"the most difficult thing when doing a code review is understanding the reason of the change."* A bad description forces every reviewer to reconstruct context from the diff — wasting their time and degrading review quality.

**Extract Acceptance Criteria from the ticket body.** Look in order:

1. An explicit "Acceptance Criteria", "Definition of Done", "AC", or "Requirements" section
2. Numbered list or bullet list in the body
3. Embedded `should`/`must`/`when X then Y` sentences

Each AC must be **falsifiable** — phrased so you can point at code and say Met / Partial / Missing. If you find a non-falsifiable AC ("system should be robust"), surface it: ask the human whether to skip it, treat it as a soft criterion, or push back to the author.

**Show the parsed AC to the human.** Numbered list. Ask: *"Is this the full set of acceptance criteria? Anything missing or misread?"* Wait for confirmation before R2.

This step is the analog of the workflow's Step 4 (Ambiguity Surfacing). The cost of asking is seconds; the cost of reviewing against wrong AC is the entire review wasted.

---

## R2: Compute the PR Diff (Merge-Base Method)

**Do not use the local base.** Local branches go stale; merge commits on the PR can drag in non-PR changes that show up in a naive `origin/<base>..origin/<branch>` diff. Use the merge-base:

```bash
MERGE_BASE=$(git merge-base origin/<base> origin/<branch>)
git diff $MERGE_BASE..origin/<branch>
git diff --stat $MERGE_BASE..origin/<branch>
git log --oneline $MERGE_BASE..origin/<branch>
```

This is the documented project rule — see the `feedback_pr_review_use_merge_base.md` memory entry. The merge-base diff is the *real* PR scope.

**Cache the file list and per-file hunks.** All subsequent passes operate on this set. **Anything outside this set is pre-existing code and is out of scope for comments**, regardless of whether you spot a problem in it. Google's eng-practices state this explicitly: *"Look at every line of code that you have been assigned to review"* — the diff is the assignment (Google 2026, "What to Look For In a Code Review").

**Surface the scope to the human.** Show file count, line additions/deletions, and the commit log. Confirm: *"Reviewing N files, ~M lines changed across K commits. Proceeding."* Halt for pushback only if the scope looks wildly wrong (e.g., 0 files; commit log shows merge commits or unrelated work).

---

## R3: Navigate the CL — Broad View First

Per Google's eng-practices on navigating a CL (Google 2026, "Navigating a CL"), the first pass is **broad view**: *"Does this change even make sense?"* If fundamental design issues exist, respond promptly with an explanation and an alternative — *"reviewing the rest of the CL might be a waste of time"* if major issues require substantial rework.

This step runs before AC verdicting. Read:

- The PR description (R1 already produced a verdict on its quality)
- The commit messages
- The file list — what surfaces does this change touch?
- The largest files in the diff first — they usually contain the primary logical change

Ask one question: **does the overall shape of this change match what the ticket asked for?**

- If yes: proceed to R4 (detailed conformance + parallel passes).
- If no: emit a single Blocker comment explaining the mismatch and offering an alternative direction. Halt the workflow. Don't waste time finding micro-issues in code that's about to be redesigned.

**Examples of broad-view blockers:**
- Ticket asked for a feature flag; PR added a global config
- Ticket asked to fix a bug; PR refactored the surrounding module
- Ticket asked for a small fix; PR is a 2000-line rewrite
- Ticket targets feature X; PR touches code that has nothing to do with X

When in doubt, ask the human before halting: *"This PR's shape doesn't obviously match the ticket. Halt and surface as a Blocker, or proceed with detailed review?"*

---

## R4: AC Conformance + Parallel Review Passes

Two sub-phases run in parallel: AC conformance (R4-AC) and the Look-For passes (R4-A through R4-E). The Look-For hierarchy follows Google's eng-practices (Google 2026, "What to Look For In a Code Review"): **Design > Functionality > Complexity > Tests > Naming/Comments > Style > Consistency**. Higher categories have higher comment severity ceilings.

### R4-AC: Acceptance Criteria Conformance

For each AC bullet from R1, produce a verdict:

| Verdict | Meaning | Output |
|---------|---------|--------|
| **Met** | Code in the diff implements this AC and at least one test exercises it | No comment; logged as evidence |
| **Partial** | Implementation exists but is incomplete, missing edge case, or missing test | Inline `Blocker:` comment at file:line with what's missing |
| **Missing** | No code in the diff implements this AC | Inline `Blocker:` comment at file head or related location |
| **Out of scope** | AC is in the ticket but the PR was scoped to defer it (with explicit author note) | No comment; logged |

**For each AC bullet, before verdicting**, locate the code:
- Grep the diff for relevant identifiers (endpoint names, class names, route paths, field names from the AC text)
- If you find a match, read the surrounding hunk and any related code outside the diff (to understand intent — but do not comment outside the diff)
- If you find no match, do not assume the AC is met because "this PR is too small" or "the author probably did it elsewhere"; absence of code is evidence of Missing

**Discriminating evidence per AC.** For each Met verdict, name the file:line + test name that proves it. For Partial, name what's there and what's not. For Missing, name where you looked. This is Rule 12 applied to review: a verdict without discriminating evidence is non-discriminating diagnosis.

**Tagged class:** `ac_conformance_drift` — when an AC is silently Partial or Missing and the PR is approved anyway.

### R4-A: Functionality (Bug Scan, Changed Lines Only)

Read only the diff hunks. Look for:

- Null / undefined dereferences on newly introduced variables
- Off-by-one errors in newly introduced loops or array indexing
- Wrong operators (`==` vs `===`, `=` in conditional, `&&` vs `&`)
- Missing `await` / `async` on newly introduced async calls
- Missing breaks in switch/match
- Race conditions in newly introduced concurrency
- Resource leaks (newly opened files / connections without close)
- SQL injection (newly introduced raw query construction)
- Auth bypass (newly added routes/controllers without auth middleware in projects where auth is the default)

**Discipline.** Flag introduced bugs only. A bug on a pre-existing line that the PR happens to render adjacent to changes is not in scope. The author did not write that line and is not responsible for fixing it in this PR.

Bacchelli's data anchors expected output: most found bugs are micro (corner cases, operator precedence, exception handling). High-confidence macro bugs are rare. If R4-A returns nothing, that is the normal case — not a sign the pass failed.

### R4-B: Complexity

Per Google (2026, "What to Look For"): *"Is the CL more complex than it should be?"* Complexity means code *"can't be understood quickly by code readers."* Watch for over-engineering, where developers add unnecessary generality or speculative features.

For each newly introduced abstraction, class hierarchy, generic, callback chain, or pattern:
- Is it justified by current need, or speculative ("we might need it later")?
- Could the same effect be achieved with simpler code?
- Is the abstraction more complex than the problem it solves?

Comments here are usually `Consider:` or `Optional:` severity unless the complexity rises to a blocker level (e.g., a new framework introduced just to do one thing).

### R4-C: Tests (Pass 3 Rule 11 & Rule 12)

Apply the existing Pass 3 from `agents/dokime.md` to the PR's new tests:

- **Tautological mocks (value mismatch):** For each new test that mocks infrastructure (storage, queues, cache, external services, auth, feature flags) — name every hardcoded value the test fixture and the production code share. Is the agreement structural (driven by config the test mocks) or coincidental (both hardcoded)? Coincidental = tautological.
- **Tautological tests (scope mismatch):** Same as above, but for shared scopes (user, team, role, request context). The Pennant case: `Feature::active()` ran in a different user context than the test fixture activated; the role gate was never evaluated and the test passed for the wrong reason.
- **Discriminating tests:** For each new test, name a change to the production code that should make the test fail. If you cannot name one (without running the mutation), flag it. Refactor sentinels (tests green against both pre- and post-refactor code) are required to be mutation-tested; hypothetical mutations don't count.
- **Setting-shaped surfaces:** For each new/changed admin toggle, threshold, feature flag, env config, or checkbox — name (a) at least one consumer that reads the value and changes behavior, and (b) at least one test that exercises the *effect* on behavior, not just persistence. Persistence-only tests permit `unwired_admin_setting` regressions.
- **Lifecycle state masking:** If the diff touches code that reads from framework lifecycle state (Eloquent `$table`/`$exists`/attributes; Symfony container; Rails ActiveRecord; React lifecycle), check whether new tests use factory-fresh instances or only hydrated ones. Hydrated-only tests silently mask abstraction bugs.
- **Discriminating diagnosis (for bug-fix PRs):** Does the new regression test pass for the right reason? Name an alternative root-cause theory that would produce the same passing test. If one exists, the diagnosis isn't discriminating. (Rule 12.)
- **Test existence:** For each changed public method, exported function, route, controller action, or event handler in the diff, grep the test paths for the symbol name. If no test references it, flag as `untested_change`. Existence only — do not run tests.

Each finding is one comment with a tagged class. Severity is typically `Blocker:` for tautological/lifecycle issues (they create false confidence in correctness) and `Consider:` for missing tests on non-critical paths.

### R4-D: Silent Failures and Error Handling

For each `catch`, `except`, `rescue`, `recover`, or error-discarding pattern in the diff:

- Is the error logged, rethrown, or transformed to a user-facing response? Or is it swallowed?
- If swallowed: is the swallow intentional and commented? Or silent?
- For catch-all (`Exception`, `Throwable`, `any`): is the context preserved (cause chain, log fields)?
- For Promise rejections: is `.catch()` or `try/catch` around `await` present?

Modeled after `silent-failure-hunter.md` in the pr-review-toolkit. Tagged class: `silent_failure`.

### R4-E: Specialized Agent Auto-Dispatch

Read the project's `.claude/agents/` directory. For each agent file:

1. Parse its frontmatter description.
2. Match it against files in the diff. Heuristic: if the agent description mentions a domain (`authz`, `audit`, `dto`, `MIS`, `workflow`, `service layer`, `test data`, `transfer curriculum`, etc.) and the diff touches code in that domain, the agent is a match.
3. Show matched agents to the human; accept overrides per the input prompt at R1.
4. Dispatch each matched agent in parallel via the Agent tool with a precise prompt: *"Review the following diff for issues specific to your domain. Diff: <hunks>. Ticket: <ID + AC>. Return a list of issues with file:line and reason. Do not flag pre-existing issues or items already covered by Pass 3 (tautological tests, discriminating tests, setting-shaped surfaces)."*
5. Aggregate findings into the issue pool.

Why this matters: Bacchelli's data shows **owner-reviewers find substantively different issues than stranger-reviewers** (Bacchelli & Bird 2013, §VI.B). 82% of surveyed developers agreed owner comments are "more conceptual" and find "more subtle defects." Specialized agents are the closest analog to owner-reviewers when the human reviewer doesn't own the domain.

This is the Step 7 / Pass 3 specialized-agent dispatch applied at review time. Per the v1.4.0 evolution entry: late dispatch is a second look, not a first one — but for code review (where there was no proposal phase), it IS the first look.

### R4-F: Beyond-Defects Pass

Bacchelli's five top motivations for code review, by 873-developer survey ranking (Bacchelli & Bird 2013, §IV.G): (1) Finding defects, (2) Code improvement, (3) Alternative solutions, (4) Knowledge transfer, (5) Team awareness. Only the first is bug-finding. The others are equally valid review output and account for the majority of comments observed in practice (defect comments = 14%, code improvements = 29%).

For each significant change in the diff, briefly consider:

- **Code improvement (Bacchelli 29%):** Is there dead code? Unused parameters? A more idiomatic expression of the same logic? Comments that explain *what* the code does instead of *why* (Google: *"Comments should explain why some code exists, and should not be explaining what some code is doing"*)? These get `Nit:` or `Consider:` severity.
- **Alternative solutions:** Is there a meaningfully better way to do this that the author may not have considered? Mention it with `Consider:` — letting the author decide is the courtesy. Bacchelli's data shows authors value these comments highly even though managers underrate them.
- **Knowledge transfer / FYI:** Is there a project convention, recent precedent, or related work the author might benefit from knowing about? `FYI:` severity. Do not block on these.
- **Good things (Google's "Look For" list):** If the author did something genuinely well, say so — *"Acknowledge when developers implement solutions well — this mentoring approach proves valuable"* (Google 2026). One acknowledgment per review is typical; do not over-do it.

Severity ceiling for this pass is `Consider:` — Beyond-defects comments should never be Blockers, because by definition they are not blocking codebase health.

---

## R5: Confidence Scoring

For each issue produced by R4-AC + R4-A through R4-F, score 0-100 using the Anthropic rubric:

| Score | Meaning |
|-------|---------|
| 0 | False positive that doesn't stand up to light scrutiny, or pre-existing |
| 25 | Might be real, might be FP; couldn't verify |
| 50 | Verified real, but nitpick or rare in practice; not very important relative to the PR |
| 75 | Highly confident, double-checked, will hit in practice; or directly violates a project rule |
| 100 | Certain, will happen frequently in practice |

**Score by dispatching a separate Haiku-class subagent per issue** with: (a) the PR diff, (b) the issue description and source, (c) the project's CLAUDE.md (if present). Ask for a single number and a one-sentence justification.

**Filter** issues with score below the threshold (default 80). The threshold is shown at R1; the human can override.

**Discipline.** Do not lower the threshold to "get more findings." If the threshold filters everything out, that is itself a signal — either the PR is genuinely clean or the review passes didn't surface the real issue (in which case relaxing the threshold won't help; rerun with different focus).

**False-positive examples** — drawn from Anthropic's `/code-review` defaults plus the Bacchelli "embarrassing formatting" finding:

- Pre-existing issues
- Something that looks like a bug but is not
- Pedantic nitpicks a senior engineer wouldn't call out
- **Style, formatting, or layout issues** — CI / linters / formatters catch these. Bacchelli's senior dev: *"In some ways it's kind of embarrassing if someone asks you to do a code review and all you can find are formatting mistakes when there are real mistakes to be found."* If R4 produces only style comments, the right output is "no blocking issues" — not a pile of low-value nits.
- Issues a typechecker would catch (CI runs them)
- General code quality issues (lack of coverage, generic security, poor docs) unless explicitly required in CLAUDE.md
- Issues called out in CLAUDE.md but explicitly silenced in the code (e.g., lint-ignore comment)
- Changes in functionality likely intentional or directly related to the broader change
- Real issues, but on lines the author did not modify in this PR

---

## R6: Output Format

**One block per comment.** Each block is a self-contained copy-pasteable unit so the human can paste a subset and skip the rest. The Bitbucket inline-comment workflow is: navigate to the file, click the line, paste the comment body. The skill produces output optimized for that gesture.

Every comment gets an **explicit severity label** in its first word, per Google's eng-practices guidance (Google 2026, "How to Write Code Review Comments"):

| Label | When to use |
|---|---|
| **Blocker:** | Must be addressed before merge. AC drift, tautological tests, real bugs, lifecycle masking. |
| **Consider:** | Reviewer thinks this may be a better approach, but it's not strictly required. |
| **Optional:** | A suggestion the author can take or leave. |
| **Nit:** | Minor stylistic preference. Author should not feel obligated to address. |
| **FYI:** | Informational. Knowledge transfer, related work, future-thinking. No action expected. |

Block format:

```
────────────────────────────────────────────────────────────
File: path/to/File.php
Line: 123
Severity: Blocker
Tag:  tautological_test (scope mismatch)
Conf: 85
────────────────────────────────────────────────────────────
The new test at FeatureFlagTest::test_reviewer_cannot_see_widget
activates the Pennant flag without user-scoping it to the
reviewer user. Production `Feature::active()` runs in the
authenticated request context, so the role gate is never
evaluated — the test passes because the flag is inactive in
the test user's scope, not because the role gate works.

Suggested fix: `Feature::activate('widget-x', $reviewer);` in
the test setup, then assert the role gate explicitly.
```

Render blocks in priority order:

1. **Blockers** first
2. **Consider** / **Optional**
3. **Nit** / **FYI**

**Be kind. Explain why.** Per Google (2026, "How to Write Code Review Comments"): focus on the work, not the person. Their bad-vs-good example: *"Why did you use threads here when there's obviously no benefit to be gained from concurrency?"* (problematic) vs. *"The concurrency model here is adding complexity to the system without any actual performance benefit that I can see. Because there's no performance benefit, it's best for this code to be single-threaded instead of using multiple threads."* (better — focuses on the code, explains why). The skill's comments default to the second style.

**At the end, summarize:**

```
─── Review summary ───
Files reviewed:    12
Lines changed:     +312 / -45
AC bullets:        5 (Met: 3, Partial: 1, Missing: 1)
Comments emitted:  7 (Blocker: 2, Consider: 3, Nit: 1, FYI: 1)
Confidence floor:  80
Overall verdict:   Approve with changes — 2 Blockers must be addressed before merge
```

**Then ask:**

> Want me to produce a separate ticket-comment verdict block for Jira? (yes/no)

If yes, produce one additional block sized for a Jira ticket comment:

```
─── Jira ticket comment ───
PR review: <ticket-id>

AC conformance: 3 of 5 Met, 1 Partial, 1 Missing.
- Met:     AC1 (file:line + test), AC2 (...), AC3 (...)
- Partial: AC4 — implementation exists but lacks edge-case
           handling for empty input (file:line)
- Missing: AC5 — no code in the diff for the "retry on
           timeout" requirement; no test references it

Test coverage: 9 of 11 changed public symbols have tests.
Untested: <symbol> (file:line), <symbol> (file:line).

Blockers (must address before merge):
- AC5 missing
- <tautological test at file:line>

See inline comments in the PR for details.
```

The Jira comment is a *handoff artifact*, not a replacement for inline comments. It exists for QA / project managers who don't read PR comments.

---

## R7: Evolution Prompt

After output, ask:

> This review session may have produced observations that could improve the review workflow OR the development workflow itself. Want to submit any of them via `/dokime:evolve`? Summarize the candidates.

Categories of candidate observations:

| Category | Example |
|---|---|
| **New failure class observed** | A PR had a tautological test variant Rule 11 didn't cover; propose the extension. |
| **Existing class recurrence** | Third PR in a month with `unwired_admin_setting`; the workflow rule should be promoted or rephrased. |
| **Review-skill gap** | This skill missed a class of issue the human caught manually; propose a new R4 pass. |
| **Review-skill noise** | This skill produced a class of high-confidence false positives; propose a calibration fix. |
| **Specialized agent miss** | An agent that should have caught X didn't; propose either prompting it differently or improving its definition. |

Format candidate observations as draft `/dokime:evolve` payloads (observation + action + steps + failure_class + detection_method + workflow_gap_type). Show them to the human; let the human pick which to submit, edit, or discard. Do not submit without explicit consent.

---

## Failure Classes Probed (v1.5.0 Corpus)

The review passes are calibrated to surface these classes. New classes get added as the corpus grows.

| Class | Source | Detected by |
|---|---|---|
| `ac_conformance_drift` | Lisa's Auctic field test (Session 6); NB observations | R4-AC |
| `tautological_mock` (value mismatch) | Storage::disk + Storage::fake hardcode (v1.3.0) | R4-C |
| `tautological_test` (umbrella; scope mismatch variant) | Pennant feature-flag case (v1.4.0) | R4-C |
| `non_discriminating_diagnosis` | Three-iteration WebSocket diagnosis (v1.4.0) | R4-C |
| `lifecycle_state_masking` | Trait reading `$this->table` on factory-fresh (v1.4.0) | R4-C |
| `unwired_admin_setting` | "Enable automatic retry" toggle with no consumer (v1.4.0) | R4-C |
| `silent_failure` | Generalized from pr-review-toolkit's silent-failure-hunter | R4-D |
| `untested_change` | Long-standing project rule; explicit at R4-C | R4-C |
| `unverified_library_mechanism_claim` | webpack-dev-server WebSocket-close misclaim (v1.4.0) | R4-A — when PR description claims library behavior |
| `deliberate_state_misclassified_as_bug` | Dev-mode-on-prod was deliberate architecture (v1.4.0) | R4-A — when PR purports to "fix" infrastructure |
| `bad_cl_description` | Google eng-practices "Writing Good CL Descriptions" | R1 |

---

## What This Skill Does NOT Do

- **Does not run tests.** CI runs them. Running them here doubles wall time without adding signal.
- **Does not run lint / typecheck / formatter.** CI runs them. Comments about lint issues are explicitly listed as false positives at R5.
- **Does not post to Bitbucket.** The output is text the human pastes. Bitbucket private workspaces don't have a uniform CLI; producing local text lets the human triage which comments to send and which to discard.
- **Does not comment on pre-existing code outside the diff.** Even if you spot a real bug, the author of this PR did not write that line. File a separate ticket; do not put it on someone else's PR.
- **Does not claim a library does X without verification.** Any "framework X does Y when Z" assertion in the review must be grep-and-read verified against the actual library source. Tagged class: `unverified_library_mechanism_claim` (the review skill is subject to its own rule).
- **Does not lower the confidence threshold to find issues.** If the threshold filters everything out, that's signal; relaxing it produces noise, not insight.
- **Does not approve or reject.** It produces evidence. The human (or a designated approver in Bitbucket) holds the merge button.
- **Does not aim for perfection.** Per Google's standard: approve once the CL *"definitely improves the overall code health of the system being worked on, even if the CL isn't perfect."* The skill's default disposition is approve-with-changes when no Blockers fire.

---

## Evolution Log

The log will grow as real reviews produce real observations. Entries land here when a review-session lesson is promoted from a `/dokime:evolve` submission into review-skill text. Format mirrors the main workflow's Evolution Log: date | observation | change.

*(No entries yet — v1.5.0 is the initial release. First real-use observations will land in v1.5.1+.)*

---

## Connection to /dokime:workflow

This skill executes Pass 3 from `agents/dokime.md` against someone else's commits. When the workflow's Pass 3 changes (Rules added, classes generalized, prompts sharpened), this skill inherits those changes automatically because R4-C references the source-of-truth wording in `agents/dokime.md` rather than duplicating it.

When this skill produces an observation that changes how Pass 3 should work, the change lands in `agents/dokime.md` first (workflow source of truth), then this skill's R4-C picks it up on the next read. This is the dokime-on-dokime pattern: the review skill evolves the development workflow, and the development workflow evolves the review skill.

---

## Sources

Three primary sources anchor this workflow's design. Local copies live in `~/Documents/Dokime/sources/`. INVENTORY.md tracks status.

1. **Bacchelli, A., & Bird, C. (2013).** *Expectations, Outcomes, and Challenges of Modern Code Review.* Proceedings of the 35th International Conference on Software Engineering (ICSE 2013), pp. 712-721. Source: `bacchelli-bird-2013/`. Foundational empirical study (570-comment card sort, 1,038-developer survey at Microsoft). Establishes that defect-finding accounts for ~14% of actual review comments and that *understanding* is the dominant challenge of review. Drives the Beyond-Defects pass (R4-F) and the explicit caution against over-promising as a bug-finder.

2. **Sadowski, C., Söderberg, E., Church, L., Sipko, M., & Bacchelli, A. (2018).** *Modern Code Review: A Case Study at Google.* ICSE-SEIP 2018. Source: `sadowski-2018/`. 9-million-review log analysis + interviews. Anchors the size pre-check at R0 (median change = 24 lines), the single-reviewer norm, the speed expectation, and the static-analysis "Please fix / Not useful" feedback loop concept (analog for the Evolution Log at R7).

3. **Google. (2026).** *Code Review Developer Guide.* `google.github.io/eng-practices/review/`. Source: `google-eng-practices-2026/` (extracted-text snapshots of the canonical pages). Provides the "Standard of Code Review" framing, the Look-For hierarchy (R4 organization), the severity-label convention (R6 Blocker / Consider / Optional / Nit / FYI), the navigate strategy (R3), the small-CLs guidance (R0 size check), and the CL description quality criteria (R1).

When this skill is updated based on new evidence — empirical paper, field observation, evolution entry — the source either gets added to this list or the existing source's role in the workflow gets re-cited explicitly. Per `feedback_primary_sources_required.md`: quoted passages trace to real sources, no wikis, no memory-quotes.

---

## Key Mantras

1. **"Verdict every AC — no silent partials."** Conformance drift is the failure mode this skill exists to prevent.
2. **"Improves overall code health is the standard."** Approve unless blockers. Perfection is not the goal — better is.
3. **"Filter <80 or destroy author trust."** Noise erodes the only thing review depends on: that the author will actually read the comments.
4. **"Read the diff, not the file."** The author did not write pre-existing code; do not put it on their PR.
5. **"One block per comment, with explicit severity."** The human pastes selectively. Make that gesture easy.
6. **"Verify the worry, then voice it."** Any library claim or framework assertion in a review comment must be grep-and-read verified. *Do the worrying the LLM can't.*
7. **"Understanding is the hidden challenge."** When in doubt about a change's intent, ask before commenting on its details.
