---
name: project
description: Decompose a free-form project description into a dokime-shaped project spec — central problem, components, v1 slice, dependency-ordered ticket map, backlog. Pairs with /dokime:ticket (each emitted ticket runs through that skill for proper formatting). Scales with project size — small projects get a compressed spec; large projects (6+ tickets) get the full §7 structure modeled on dokime v2's own spec.
---

# Dokime Project

User request: "$ARGUMENTS"

You are decomposing a project into ticket-sized work. The output is a **paste-ready project spec in Markdown** — the dev pastes it as their `<project>.spec.md`, then runs `/dokime:ticket` per emitted item as they get to it.

The discipline this skill enforces, derived from the dokime v2 spec's own §7 structure:

- **A project spec names the central problem and components**, then lists the ticket decomposition.
- **The decomposition is dependency-ordered.** Each ticket lists "depends on" if applicable; the dependency map IS the execution order.
- **Each ticket is ticket-sized** — one workflow run, one PR.
- **The v1 slice is named explicitly for 6+ ticket projects.** What's the smallest closing loop? Defer the rest. (See dokime v2 spec D11 / Q-T9-9 — the smallest-closing-loop principle.)
- **Backlog items get their own row.** Work that surfaces during decomposition but doesn't belong in v1 goes to a Candidate Tickets / Backlog section.
- **Read by spirit.** A 2-ticket "project" doesn't need §7 — it gets a paragraph. A 12-ticket project does. Scale-down anti-ceremony.

## Step 1: Resume or start?

If `--spec-file <path>` was passed and the path exists, **read it first** and resume — figure out which sections are complete and which are pending. Don't restart the whole decomposition. Ask the user where to pick up.

Otherwise, start fresh.

## Step 2: Sketch the project shape

Conversationally elicit (only ask for what's not already in `$ARGUMENTS`):

- **Central problem** — the ONE thing this project is solving, stated so it can be disagreed with.
- **Components** — the natural pieces. (For dokime v2 this was A / B / C; for most projects it's 1–4 named pieces.)
- **Goal type** — *deliverable* (a spec or design artifact) vs. *capability* (running code) vs. *both* (e.g., dokime v2 was both — spec ticket + implementation tickets).
- **Rough size** — does the project feel like 1–2 tickets, 3–5, or 6+?

Don't go deep yet. This is the shape sketch.

## Step 3: Scale the spec to the project size

Branch on the rough size:

- **1–2 tickets ("paragraph project")** — skip §7 structure entirely. Emit a single paragraph naming the central problem, then the 1–2 tickets with one-line descriptions and a dependency arrow if applicable. Done.
- **3–5 tickets ("moderate project")** — emit central problem + component sketch + ticket map (table format). No v1-slice section; no backlog (small enough to ship together).
- **6+ tickets ("full project")** — emit the full §7 structure: central problem, components, wiring, tier model, skill map (if applicable), migration approach, v1 slice, ticket decomposition, backlog. Modeled on `dokime-v2-spec.md`.

State which size category you're scaling to and why. The user can override (rarely needed).

## Step 4: Decompose into tickets

Walk through the work conversationally and surface tickets one at a time. For each:

- **Name** (short — title-cased phrase; the proper Jira title comes from `/dokime:ticket`).
- **Type** — Design (deliverable = document; runs Steps 3/4/5/7 + 14-16 per Finding F1) / Feature / Bug.
- **One-sentence description.**
- **Depends on** — list prior tickets it needs done first; empty if it can start fresh.
- **In v1 or backlog** (only relevant for 6+ projects).

As you go, **separate v1 from backlog** for 6+ projects. The discipline: v1 is the smallest closing loop. Push back if the user wants "everything in v1" — ask "what's the smallest scope where the loop closes against reality?"

When discovered work surfaces that doesn't belong in v1 (sibling tickets, follow-on cleanup, infrastructure, future-feature ideas), **flag for backlog row immediately** — don't quietly absorb it into v1 (`bureaucratic_nudge` discipline applied at the project tier: don't let scope grow silently).

## Step 5: Self-check dependency ordering

For each ticket, ask: *"Does this ticket's work have all its inputs produced by its declared dependencies?"* (Reapplies the `spec_locates_work_at_step_without_prerequisites` discipline from T9.)

If a ticket needs data / state / files that no prior ticket produces, either:
- Add the missing prior ticket (likely an earlier number); or
- Move this ticket later in the order; or
- Note explicitly that some inputs come from outside the project (existing codebase, external systems).

The dependency map must be sound before it's emitted — a broken decomposition wastes the dev's time at the first execution attempt.

## Step 6: Self-check the v1 slice (6+ projects only)

For 6+ projects, the v1 slice must satisfy:
- **Closes a real loop against reality** — produces an artifact or behavior the dev / user can actually use, not just intermediate plumbing.
- **Is the smallest such loop.** If you can drop a ticket from v1 and the loop still closes, drop it.
- **Doesn't depend on backlog work.** Every v1 ticket's `depends on` list is satisfied within v1.

If any check fails, revise v1 before emitting.

## Step 7: Emit the project spec

Print the project spec in the size-appropriate shape (Step 3 chose the shape).

**Paragraph-project shape:**

```markdown
# <Project name>

<One-paragraph central problem.>

**Tickets:**
1. **<Name>** (<type>) — <description>. Depends on: <prior tickets or "—">.
2. ...
```

**Moderate-project shape:**

```markdown
# <Project name>

## Central problem
<The ONE thing, stated so it can be disagreed with.>

## Components
- **<Component A>** — <responsibility>.
- ...

## Tickets (dependency-ordered)

| # | Name | Type | Depends on | Description |
|---|------|------|------------|-------------|
| 1 | ... | ... | — | ... |
| 2 | ... | ... | 1 | ... |
```

**Full-project shape** — full §7 structure modeled on `dokime-v2-spec.md`:

```markdown
# <Project name> — System Specification

- **Task ID:** <PROJECT-SPEC>
- **Type:** Feature / design ticket — deliverable is this specification
- **Created:** <date>
- **Stakeholder:** <name>
- **Spec file:** <path>

## Step 1 — Capture
### Requirements / description
...

## Step 7 — The <project> Specification

### 7.1 What this is
### 7.2 Components
### 7.3 How the components wire — the loop
### 7.4 Tier model (if applicable)
### 7.5 Skill / artifact map (if applicable)
### 7.6 Migration — strangler fig vs. rebuild (per component)
### 7.7 The v1 build — N tickets

| # | Name | Type | Depends on | Description |
|---|------|------|------------|-------------|

### 7.8 Candidate Tickets / Backlog (v2+)

| # | Item | Scope | Notes |
|---|------|-------|-------|
```

## Step 8: Hand off

After emitting, tell the user:

> "Paste the above as your `<project>.spec.md`. For each ticket in the decomposition, run `/dokime:ticket` when you're ready to start it — that skill produces the paste-ready Jira ticket. Open each ticket through `/dokime:workflow` for the engineering execution."

That's it. No "should I write the file?" — the dev pastes and goes.

## Discipline

- **Conversational only in v1** — no structured input. Skill-to-skill structured-input mode is v2+.
- **No auto-write of files** — output is text; the dev pastes. (Parallel to `/dokime:ticket` v1 discipline.)
- **No auto-running `/dokime:ticket` per emitted item** — the user invokes that skill per ticket as they get to it.
- **No story tier** — Q1 deferred to v2+. Tickets are direct children of projects.
- **Scale by ticket count is firm.** A 2-ticket project that gets a §7 spec is ceremony; a 12-ticket project that gets a paragraph is under-scoped. Trust the count.
- **If the dev pushes back on v1-slice scoping** ("everything is critical for v1"), accept their version but record the original v1-slice recommendation as a one-line note in the spec's backlog section ("considered: <ticket> deferred to v2; dev chose to include — revisit if v1 schedule slips"). Their override is recorded; the discipline isn't silently overridden.
