#!/usr/bin/env bash
# Test for bin/dokime-rule-versions (dokime v2, ticket DKV2-T15).
#
# dokime-rule-versions reports, per failure_class, the plugin_version the rule
# was created in — recovered from GIT HISTORY of agents/dokime.md (the version
# is not in the Evolution-Log prose). For each class: the first commit that
# introduced the backticked `class` string → VERSION at that commit. No commit
# or no VERSION → null. Output: JSON { class: version|null }.
#
# This test builds a FIXTURE GIT REPO (real `git log -S`); it does not depend
# on the live agents/dokime.md history.
set -uo pipefail

cd "$(dirname "$0")/.."
HELPER="$(pwd)/bin/dokime-rule-versions"

pass=0
fail=0
check() {
  if [[ "$1" -eq 0 ]]; then echo "  ok      - $2"; pass=$((pass + 1))
  else echo "  NOT OK  - $2"; fail=$((fail + 1)); fi
}

repos=()
trap 'for r in "${repos[@]}"; do rm -rf "$r"; done' EXIT

# Build a fixture plugin repo; sets global $repo.
#   c0: class_early introduced BEFORE a VERSION file exists
#   c1: VERSION 1.4.0  + class_a
#   c2: VERSION 1.19.0 + class_b + a bare (untagged) `evaluate` token
build_fixture() {
  repo="$(mktemp -d)"; repos+=("$repo")
  git -C "$repo" init -q
  git -C "$repo" config user.email t@example.com
  git -C "$repo" config user.name tester
  git -C "$repo" config commit.gpgsign false
  mkdir -p "$repo/agents"

  printf 'New failure class: `class_early`\n' > "$repo/agents/dokime.md"
  git -C "$repo" add -A && git -C "$repo" commit -qm "c0: class_early (pre-VERSION)"

  printf '1.4.0\n' > "$repo/VERSION"
  printf 'New failure class: `class_a`\n' >> "$repo/agents/dokime.md"
  git -C "$repo" add -A && git -C "$repo" commit -qm "c1: VERSION 1.4.0 + class_a"

  printf '1.19.0\n' > "$repo/VERSION"
  # class_b is NEW here; class_a is RE-MENTIONED here (so it appears in 2 commits —
  # this is what makes test #1 discriminate the --reverse / first-commit logic:
  # without --reverse, class_a would resolve to THIS commit's 1.19.0, not 1.4.0).
  printf 'Tagged class: `class_b`\nclass_a refined again here, see `class_a`\nsome prose mentioning `evaluate` (no tag prefix)\n' >> "$repo/agents/dokime.md"
  git -C "$repo" add -A && git -C "$repo" commit -qm "c2: VERSION 1.19.0 + class_b, re-mention class_a"
}

build_fixture

# 1 — no args: extract + version all doc-tagged classes
out=$(CLAUDE_PLUGIN_ROOT="$repo" "$HELPER" 2>/dev/null)
[[ "$(printf '%s' "$out" | jq -r '.class_a')" == "1.4.0" \
   && "$(printf '%s' "$out" | jq -r '.class_b')" == "1.19.0" ]]
check $? "no-args: class_a=1.4.0, class_b=1.19.0"

# 2 — explicit arg → only that class
out=$(CLAUDE_PLUGIN_ROOT="$repo" "$HELPER" class_b 2>/dev/null)
[[ "$(printf '%s' "$out" | jq -r '.class_b')" == "1.19.0" \
   && "$(printf '%s' "$out" | jq 'has("class_a")')" == "false" ]]
check $? "explicit arg class_b → only class_b"

# 3 — unresolvable class arg → null
out=$(CLAUDE_PLUGIN_ROOT="$repo" "$HELPER" nope_class 2>/dev/null)
[[ "$(printf '%s' "$out" | jq -r '.nope_class')" == "null" ]]
check $? "unresolvable class → null"

# 4 — precision: bare (untagged) `evaluate` is NOT extracted in no-args mode
out=$(CLAUDE_PLUGIN_ROOT="$repo" "$HELPER" 2>/dev/null)
[[ "$(printf '%s' "$out" | jq 'has("evaluate")')" == "false" ]]
check $? "precision: bare-backtick 'evaluate' not extracted"

# 5 — class introduced before any VERSION existed → null
out=$(CLAUDE_PLUGIN_ROOT="$repo" "$HELPER" class_early 2>/dev/null)
[[ "$(printf '%s' "$out" | jq -r '.class_early')" == "null" ]]
check $? "class introduced before VERSION existed → null"

echo
echo "passed: $pass   failed: $fail"
[[ "$fail" -eq 0 ]]
