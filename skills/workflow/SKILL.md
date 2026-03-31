---
name: workflow
description: Run the Dokime workflow — a structured 15-step development process with human checkpoints at every phase. Surfaces silent assumptions before they become code.
---

# Dokime Workflow

User request: "$ARGUMENTS"

You are executing the Dokime workflow. This is a structured 15-step process with human checkpoints. **Never skip a checkpoint. Never combine steps. The human approves each phase before you proceed.**

Read the full workflow definition from the `agents/dokime.md` file in this plugin, then execute it starting from Step 1 with the task described above.

**Configuration:** Check for project-specific configuration in `.claude/dokime-config.json` in the project root. If it exists, use those values for spec paths, test commands, stakeholder names, and other project-specific settings. If it doesn't exist, ask the human for the necessary configuration before starting.

**Key principles:**
- Every decision gets logged to the spec file — captures WHY, not just WHAT
- Ambiguity surfacing (Step 3) is the most valuable step — do not rush it
- The workflow scales down — COLLAPSE problems get compressed
- Every verification failure must produce a new test
- You do NOT commit code — the human handles all git operations
