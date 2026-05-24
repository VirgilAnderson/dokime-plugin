# dokime v2 — Measurement Store (component B)

The measurement store records what a dokime workflow run produced, so the workflow can be measured against its own claims. It is **component B** of dokime v2 — see `~/Documents/Dokime/docs/dokime-v2-spec.md`.

This store is **machine-written** (by the instrumentation in tickets T2–T4) and **machine-read** (by component C, the evolution loop). It is the machine-facing sibling of the `ledger.md` family: `ledger.md` stays the human-facing longitudinal rollup; this store holds the fine-grained per-run records. That is why these files are JSONL, not markdown — they are append-heavy logs (spec decision Q-T1-1).

Created by ticket **DKV2-T1**, which created the store and this contract. T2–T4 write into it; nothing reads it until component C.

## Files

| File | Holds | Written by |
|------|-------|-----------|
| `checkpoint-outcomes.jsonl` | one record per checkpoint per run | T2 |
| `escaped-ambiguity.jsonl` | one record per escaped ambiguity discovered | T3 |
| `comprehension-checks.jsonl` | one record per decision-point comprehension check | T4 |

Each file is JSON Lines: one JSON object per line, UTF-8, newline-terminated. An empty file (zero lines) is valid — it means zero records.

## Shared keys

Every record, in every file, carries:

- `schema_version` (integer) — the schema version this record was written under. Current: `1`. A reader that does not recognise a version should skip the record, not crash.
- `run_id` (string) — identifies one workflow run. Format: `<ticket_id>@<ISO-8601 start timestamp, to the second>` — e.g. `DKV2-T1@2026-05-22T14:30:15`. To-the-second granularity avoids collision between two runs of the same ticket.
- `ticket_id` (string) — the ticket the run was for.
- `timestamp` (string) — ISO-8601; when this record's event occurred.

## Record types

### checkpoint-outcomes

One record each time a workflow checkpoint is resolved.

| Field | Type | Notes |
|-------|------|-------|
| `schema_version` | int | shared key |
| `run_id` | string | shared key |
| `ticket_id` | string | shared key |
| `step` | string | the checkpoint's step — e.g. `Step 4`, `B4` |
| `outcome` | enum | `approved-clean` · `approved-with-changes` · `reopened` |
| `timestamp` | string | shared key |
| `note` | string | *optional* — what changed (if `approved-with-changes`) or why reopened |

```json
{"schema_version":1,"run_id":"DKV2-T1@2026-05-22T14:30:15","ticket_id":"DKV2-T1","step":"Step 4","outcome":"approved-with-changes","timestamp":"2026-05-22T15:05:00Z","note":"Q-T1-6 surfaced late and was added before the checkpoint passed."}
```

### escaped-ambiguity

One record each time a bug's root cause is found to be an ambiguity that Step 4 / B5 should have surfaced (spec decision Q6). A retrospective metric — written during the bug-fix run, attributed back to the ticket that let the ambiguity through.

| Field | Type | Notes |
|-------|------|-------|
| `schema_version` | int | shared key |
| `run_id` | string | shared key — the *discovering* (bug-fix) run |
| `ticket_id` | string | shared key — the bug ticket |
| `origin_ticket_id` | string | the ticket whose Step 4 / B5 should have surfaced the ambiguity |
| `origin_step` | string | `Step 4` or `B5` |
| `description` | string | what the ambiguity was |
| `timestamp` | string | shared key |

```json
{"schema_version":1,"run_id":"ICOV3-1601@2026-06-10T09:12:00","ticket_id":"ICOV3-1601","origin_ticket_id":"ICOV3-1588","origin_step":"Step 4","description":"Discount stacking order was never specified; the bug was two discounts applying in the wrong sequence.","timestamp":"2026-06-10T09:40:00Z"}
```

### comprehension-checks

One record per decision-point comprehension check.

**Privacy (spec decision D5 / Q-T1-6):** comprehension data is private to the developer. This file carries **no developer identifier** — it records the *check*, never *who took it*. Per-developer detail lives in the private, out-of-repo store (`~/.dokime/knowledge/`), which is out of T1 scope (v2+).

| Field | Type | Notes |
|-------|------|-------|
| `schema_version` | int | shared key |
| `run_id` | string | shared key |
| `ticket_id` | string | shared key |
| `step` | string | where the check happened — e.g. `Step 3` |
| `result` | enum | `pass` · `fail` |
| `difficulty` | string | Bloom level — `recall` · `apply` · `analyze` · `evaluate` |
| `timestamp` | string | shared key |

```json
{"schema_version":1,"run_id":"DKV2-T2@2026-05-25T10:00:00","ticket_id":"DKV2-T2","step":"Step 3","result":"pass","difficulty":"analyze","timestamp":"2026-05-25T10:08:00Z"}
```

#### schema_version 2 — T8 adds `target_difficulty`

When the workflow computes a target Bloom for the question (`bin/target-bloom`, then `--target-difficulty` on `--comprehension` or the 5th positional on `--review`), the record is written at `schema_version: 2` and carries one additional field:

| Field | Type | Notes |
|-------|------|-------|
| `target_difficulty` | string | Bloom level the question *aimed at* — `recall` · `apply` · `analyze` · `evaluate`. Computed from the card's `leitner_box` via the Q-T8-1 box→Bloom mapping (1→recall, 2→apply, 3→apply, 4→analyze, 5→evaluate); `recall` on cold-start. |

`target_difficulty` is the *intent* (what the workflow asked the AI to aim at); `difficulty` is the *self-tag* (what the AI said it generated). The gap between them is signal for future calibration (v2+ will tune).

**Readers tolerate both versions.** Records before T8 stay `schema_version: 1` (no `target_difficulty`); records from plugin 1.12.0+ are `schema_version: 2` when the workflow passes the target. No migration of v1 records.

```json
{"schema_version":2,"run_id":"DKV2-T8@2026-05-23T10:00:00","ticket_id":"DKV2-T8","step":"Step 7:review","result":"pass","difficulty":"analyze","target_difficulty":"analyze","timestamp":"2026-05-23T10:08:00Z"}
```

#### schema_version 3 — T9 adds `pass`

When the workflow tags the comprehension question with which delivery pass produced it (`--comprehension-pass` on `dokime-checkpoint`), the record is written at `schema_version: 3` and carries one additional field:

| Field | Type | Notes |
|-------|------|-------|
| `pass` | string | Delivery pass — `silent` (Step 3) · `what` (Step 6) · `how` (Step 7) · `why` (Step 11). Identifies which of the four-pass Bloom-laddered delivery passes produced the recorded question (T9 four-pass delivery ritual). |

`pass` is the *delivery context* (which pass of the four-pass ritual the dev was being asked about); `difficulty` and `target_difficulty` (if present) remain the question's actual / intended Bloom level. A v3 record may carry `target_difficulty` too (when both `--comprehension-pass` and `--target-difficulty` are set); it may also omit `target_difficulty` when only `--comprehension-pass` is set.

**Readers tolerate v1/v2/v3.** Records before T9 stay at their original version (`pass` absent); records from plugin 1.15.0+ are `schema_version: 3` when the workflow passes `--comprehension-pass`. No migration of v1/v2 records.

```json
{"schema_version":3,"run_id":"DKV2-T9@2026-05-23T15:00:00","ticket_id":"DKV2-T9","step":"Step 3","result":"pass","difficulty":"recall","target_difficulty":"recall","pass":"silent","timestamp":"2026-05-23T15:08:00Z"}
```

## Schema changes

To change a record's shape: bump `schema_version` and add the new version's shape here. Old records keep their old version number and stay readable. No migration tooling exists yet (v1) — the version field is the hook for it.
