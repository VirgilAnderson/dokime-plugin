---
name: review
description: Run a Dokime code review on a pull request branch. Verifies the PR meets its ticket's acceptance criteria, flags real bugs without producing noise, and outputs Bitbucket-flavored inline comments ready to paste. Executes Pass 3 (Rule 11, Rule 12, specialized-agent dispatch) against someone else's commits.
---

# Dokime Review

User request: "$ARGUMENTS"

You are executing the Dokime code review workflow. This is a structured review process designed to verify PR-to-ticket conformance, surface real bugs without low-signal noise, and produce output the human can paste directly into Bitbucket as inline comments.

Read the full review workflow definition from the `agents/dokime-review.md` file in this plugin, then execute it starting from R0 with the inputs described above (or collect them conversationally if none were provided).

**Configuration:** Check for project-specific configuration in `.claude/dokime-config.json` in the project root. Useful fields: `default_base_branch`, `test_paths`, `specialist_agents_dir`, `jira_project`, `bitbucket_workspace`. If the file doesn't exist, ask the human for the values you need and fall back to detection (project type from manifest files, test paths from globs, specialist agents from `.claude/agents/`).

**Key principles:**
- Verdict every acceptance criterion — Met / Partial / Missing with discriminating evidence (file:line + test). No silent partials.
- Diff comes from the merge-base: `git diff $(git merge-base origin/<base> origin/<branch>)..origin/<branch>`. Local base is stale.
- Only comment on changes in the diff. Pre-existing code is out of scope, even when it has real problems.
- Filter issues below confidence 80 by default. Noise destroys author trust; trust is what review depends on.
- One block per comment. The human pastes selectively.
- Specialized agents auto-dispatch from `.claude/agents/` when their domain matches the diff.
- Don't run tests, lint, or typecheck — CI does that. Don't post to Bitbucket — output stays local for paste.
- Any library claim in a review comment must be grep-and-read verified. Do the worrying the LLM can't.

**After the review (R7):** ask the human whether any session observations should be submitted via `/dokime:evolve` — new failure classes, recurrence of existing ones, review-skill gaps, review-skill noise, specialized-agent misses. Summarize candidates and let the human pick which to send, edit, or discard. Do not submit without explicit consent.
