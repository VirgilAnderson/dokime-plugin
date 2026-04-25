# /dokime:log-ticket — Specification (Not Yet Built)

This is a design spec for a future skill. The skill submits anonymized ticket-level metrics to the cross-user dokime ledger, complementing `/dokime:evolve` (which captures notable observations).

## Why This Exists

`/dokime:evolve` captures *observations* — things engineers noticed about the workflow. That gives dense narrative but sparse coverage: only tickets with notable observations get logged.

`/dokime:log-ticket` captures *outcomes* — what every ticket actually produced, regardless of whether anything was notable. That gives broad coverage and lets us answer:

- Has failure class X recurred since evolution entry Y was added?
- Do tickets with strict adherence have lower production-incident rates than those with skipped steps?
- Which process metrics (ambiguities surfaced, mutations applied) correlate with outcome metrics?
- Is the workflow improving over time, or are evolution entries adding ceremony without adding signal?

Together, the two skills form a corpus: dense narrative + broad signal. Quarterly review cross-references them.

## When Invoked

- **At Step 16 / B15 (Ship)** — the workflow agent prompts: *"Want to submit this ticket to the dokime ledger?"*
- **Manually** — engineer runs `/dokime:log-ticket` to retro-fill or correct a row
- **Automated trigger (future)** — Sentry webhook updates outcome fields when production incidents fire on a tracked release

## Schema

Submission body fields. All are optional; engineers can submit partial rows and complete them retrospectively.

```json
{
  "date": "2026-04-21",
  "type": "feature",
  "workflow_version": "1.3.0",
  "strict_adherence": true,
  "steps_skipped": [],
  "ambiguities_surfaced": 4,
  "decisions_logged": 7,
  "mutations_applied": 3,
  "time_to_merge_days": 6,
  "production_incident_30d": null,
  "production_incident_90d": null,
  "qa_escape": null,
  "post_merge_bugfix_commits": null,
  "revert_required": false,
  "is_bug_ticket": false,
  "origin_workflow": null,
  "known_class_match": null,
  "gap_type": null,
  "evolution_entry_created": false,
  "project_type": "brownfield Laravel",
  "submission_id": "engineer-generated-uuid"
}
```

**Anonymity rules (same as `/dokime:evolve`):**
- NO ticket IDs
- NO repo names
- NO project/company names
- NO file paths
- `project_type` is a free-form anonymized description; engineer responsible for stripping identifiers

The `submission_id` is engineer-generated and locally tracked so retrospective updates can reference the original row without revealing identity.

## API Endpoint

`POST https://launchtest.app/api/dokime/ledger`

Authentication: same anonymous-submission pattern as `/dokime:evolve`. No engineer identification, no auth tokens (currently).

Rate limiting: TBD. Expected volume is low (one submission per ticket, ~10–50 per engineer per quarter).

## Sentry Integration (Phase 2)

Engineers running Sentry can opt in to automated outcome population. Configuration (local only, never submitted):

```yaml
# ~/.config/dokime/sentry.yml
sentry:
  enabled: true
  organization: "incentco"
  projects:
    - id: "4511215334850560"
      name: "API"
    - id: "4511254382313472"
      name: "Admin"
    - id: "4511254386311168"
      name: "Program"
  api_token_env: "SENTRY_AUTH_TOKEN"
```

When `/dokime:log-ticket` is invoked, the skill:
1. Tags the merge commit as a Sentry release (if not already tagged)
2. Records the release SHA in the local ledger
3. After 30 days, queries Sentry for errors attributed to that release; populates `production_incident_30d`
4. After 90 days, repeats for `production_incident_90d`

The Sentry-derived outcome data is then submitted to the cross-user feed (anonymized — release SHA is replaced with a hash; only the boolean outcome flags are submitted).

Sentry integration is opt-in; engineers without Sentry can fill outcome fields manually or leave them blank.

## Local Ledger Sync

Engineer's local ledger lives at `~/Documents/Dokime/data/ledger.md` (or project-equivalent). On submission:

1. Skill reads the local ledger row (if exists)
2. Strips local-only fields (ticket_id, repo)
3. Submits the anonymized payload
4. Updates the local row with the submission timestamp + remote ID

This way the local ledger remains the engineer's full record; the cross-user feed gets only what's needed for aggregate analysis.

## Implementation Phases

1. **Phase 1 (manual):** Skill captures fields via prompt, submits to API. Engineer fills outcome fields manually.
2. **Phase 2 (Sentry):** Add Sentry integration for automated outcome population.
3. **Phase 3 (workflow integration):** Add the prompt at Step 16 / B15 in the workflow agent.
4. **Phase 4 (aggregation):** Build a maintainer-side dashboard that surfaces:
   - Failure-class recurrence rates
   - Process-metric vs. outcome-metric correlations
   - Quarterly trends per workflow version
   - Evolution entries that have/have not earned their keep

## Open Design Questions

1. **Per-engineer aggregation vs. ticket-level granularity.** Submitting per-ticket gives finer signal; submitting quarterly aggregates per engineer is lower-friction but loses ticket-level detail. Lean: per-ticket with the anonymity rules above.
2. **Workflow-version weighting.** Tickets shipped under v1.2.0 vs. v1.3.0 should be tracked separately so we can isolate the effect of evolution entries that landed between versions.
3. **Negative observations.** Should engineers also submit "this ticket went perfectly, nothing to note" rows? Lean: yes — silence is data. A workflow version where most rows are uneventful is one that's earned its keep.
4. **Failure class registry sync.** The Failure Class Registry lives in the local ledger. How do engineers learn which classes the maintainer has seen across the corpus? Possibly: `/dokime:list-classes` skill that fetches the canonical registry from the API.

## Related Files

- `~/Documents/Dokime/data/ledger.md` — engineer's local ledger
- `~/Documents/Dokime/dokime-plugin/skills/evolve/SKILL.md` — companion skill for observations
- `~/Documents/Dokime/dokime-plugin/agents/dokime.md` — workflow agent (will eventually prompt at Step 16 / B15)

## Status

**Designed, not built.** Spec captures the contract for future implementation.

Last updated: 2026-04-24
