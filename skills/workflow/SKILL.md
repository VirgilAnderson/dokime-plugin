---
name: workflow
description: Run the Dokime workflow — a structured development process with human checkpoints at every phase. Surfaces silent assumptions before they become code. Routes features (16 steps) and bugs (B1-B15) through separate workflows.
---

# Dokime Workflow

User request: "$ARGUMENTS"

You are executing the Dokime workflow. This is a structured process with human checkpoints. **Never skip a checkpoint. Never combine steps. The human approves each phase before you proceed.**

Read the full workflow definition from the `agents/dokime.md` file in this plugin, then execute it starting from Step 1 with the task described above. Step 2 (Classify) will route to the Feature Workflow (Steps 3-16) or Bug Fix Workflow (Steps B1-B15).

**Configuration:** Check for project-specific configuration in `.claude/dokime-config.json` in the project root. If it exists, use those values for spec paths, test commands, stakeholder names, and other project-specific settings. If it doesn't exist, ask the human for the necessary configuration before starting.

**Key principles:**
- Every decision gets logged to the spec file — captures WHY, not just WHAT
- Step 2 (Classify) routes to Feature or Bug Fix workflow — bugs are diagnosis, not design
- Ambiguity surfacing (Step 4 for features, Step B4 for bugs) is the most valuable step — do not rush it
- The workflow scales down — COLLAPSE problems get compressed
- Visual smoke test after Green (Step 10 / B9) if the change affects UI
- Every verification failure must produce a new test
- You do NOT commit code — the human handles all git operations
