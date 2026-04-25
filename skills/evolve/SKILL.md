---
name: evolve
description: Submit a Dokime workflow evolution entry — captures what you learned from a session so the workflow can improve for everyone. Asks for user consent before sending.
---

# Dokime Evolution Feedback

You are submitting a lesson learned from a Dokime workflow session. This sends an anonymous entry to the Dokime evolution feed so the workflow maintainer can review it and potentially improve the workflow for all users.

**User request:** "$ARGUMENTS"

## Step 1: Capture the Entry

If the user provided the observation and action inline, parse them. Otherwise, ask:

1. **Observation** — What happened during the session? What worked, what failed, what was missing? Be specific: name the step, what went wrong or right, and the concrete consequence.
2. **Action taken or proposed** — What change was made to the workflow (or should be made)? What step should be updated and how?
3. **Steps involved** — Which workflow step(s) does this relate to? (e.g., B3, B4, Step 15)
4. **Failure class** — What category of failure does this address? Use an existing class name from the Failure Class Registry (e.g., `tautological_mock`, `cross_repo_criterion_drop`) if it matches, or propose a new snake_case name. Leave blank if this is a positive observation (something that worked well) rather than a failure.
5. **Detection method** — How was the issue caught? One of: `production_incident`, `qa_escape`, `code_review`, `post_mortem`, `accident`, `pre_commit_check`, `mutation_test`, `verify_step`. Leave blank for positive observations.
6. **Workflow gap type** — Is this a `structural` gap (impossible to catch with the current workflow — no internal contradiction for any step to surface) or a `discipline` gap (process exists but wasn't followed)? Leave blank for positive observations.
7. **Project type** (optional) — A general description of the project context, anonymized. (e.g., "brownfield Laravel", "greenfield React", "data pipeline"). Do NOT include project names, company names, or identifying details.

## Step 2: Confirm with the User

Show the user exactly what will be sent:

```
Observation: [their observation]
Action: [their action]
Steps: [step list]
Failure class: [class name or blank]
Detection method: [method or blank]
Workflow gap type: [structural / discipline / blank]
Project type: [if provided]
Plugin version: [from VERSION file]
```

Then ask: **"This will be submitted anonymously to the Dokime evolution feed. The maintainer will review it and may use it to improve the workflow for all users. OK to send?"**

**Do not send without explicit consent.**

## Step 3: Submit

Read the plugin version:

```bash
cat ~/.claude/plugins/marketplaces/dokime/VERSION
```

Then POST to the evolution API:

```bash
curl -s -X POST https://launchtest.app/api/dokime/evolution \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "observation": "THE OBSERVATION TEXT",
    "action_taken": "THE ACTION TEXT",
    "steps": ["B4", "Step 15"],
    "failure_class": "tautological_mock",
    "detection_method": "production_incident",
    "workflow_gap_type": "structural",
    "project_type": "brownfield Laravel",
    "plugin_version": "1.1.0"
  }'

The `failure_class`, `detection_method`, and `workflow_gap_type` fields are optional but strongly preferred — they let the maintainer see whether failure classes recur, whether rules are sticking, and which gaps are structural vs. discipline issues. Omit them only for positive observations.
```

Report the result to the user. If successful, thank them — their observation helps the workflow evolve for everyone.

If the request fails (network error, rate limit, server error), tell the user the submission failed and suggest they try again later or manually share the observation with the maintainer.
