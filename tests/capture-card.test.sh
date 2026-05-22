#!/usr/bin/env bash
# Test for bin/capture-card (dokime v2, ticket DKV2-T6).
# Run from anywhere: tests/capture-card.test.sh
#
# `set -uo pipefail` but NOT `-e` — negative cases inspect $?.
set -uo pipefail

cd "$(dirname "$0")/.."
HELPER="$(pwd)/bin/capture-card"   # absolute — tests use HOME override

pass=0
fail=0
check() {
  if [[ "$1" -eq 0 ]]; then echo "  ok      - $2"; pass=$((pass + 1))
  else echo "  NOT OK  - $2"; fail=$((fail + 1)); fi
}

# Shared overridden HOME for stateful tests; tmp lives till the end.
shared_home="$(mktemp -d)"
trap 'rm -rf "$shared_home"' EXIT
store="$shared_home/.dokime/knowledge/cards.json"

# Run with the shared overridden HOME.
run() { HOME="$shared_home" "$HELPER" "$@"; }

# 1 — create a skill card
run "tautological_test" "skill" "fail" "A test that cannot fail." >/dev/null 2>&1
[[ -f "$store" && "$(jq 'length' "$store" 2>/dev/null)" == "1" ]]
check $? "create-new skill card — store has 1 card"

# 2 — skill card fields (no project field)
jq -e '.[0] | .concept=="tautological_test" and .deck=="skill" and .leitner_box==1 and (.history|length)==1 and .history[0].result=="fail" and (has("project")|not)' "$store" >/dev/null 2>&1
check $? "skill card fields conform (no project)"

# 3 — create a codebase card with project
run "my-app:src/Foo.php" "codebase" "fail" "How Foo works." "my-app" >/dev/null 2>&1
[[ "$(jq 'length' "$store" 2>/dev/null)" == "2" ]]
check $? "create-new codebase card — store has 2 cards"

# 4 — codebase card has project + box 1
jq -e '.[] | select(.concept=="my-app:src/Foo.php") | .deck=="codebase" and .project=="my-app" and .leitner_box==1' "$store" >/dev/null 2>&1
check $? "codebase card has project field and box 1"

# 5 — pass on existing skill card promotes box (1→2) and appends history
run "tautological_test" "skill" "pass" "A test that cannot fail." >/dev/null 2>&1
jq -e '.[] | select(.concept=="tautological_test") | .leitner_box==2 and (.history|length)==2' "$store" >/dev/null 2>&1
check $? "pass on existing card promotes box and appends history"

# 6 — fail on existing card resets box to 1
run "tautological_test" "skill" "fail" "A test that cannot fail." >/dev/null 2>&1
jq -e '.[] | select(.concept=="tautological_test") | .leitner_box==1 and (.history|length)==3' "$store" >/dev/null 2>&1
check $? "fail on existing card resets box to 1"

# 7 — pass at box 5 stays capped (drive to 5, then one more pass)
run "tautological_test" "skill" "pass" "X" >/dev/null 2>&1  # 1→2
run "tautological_test" "skill" "pass" "X" >/dev/null 2>&1  # 2→3
run "tautological_test" "skill" "pass" "X" >/dev/null 2>&1  # 3→4
run "tautological_test" "skill" "pass" "X" >/dev/null 2>&1  # 4→5
box_before=$(jq '.[] | select(.concept=="tautological_test") | .leitner_box' "$store" 2>/dev/null)
run "tautological_test" "skill" "pass" "X" >/dev/null 2>&1  # 5→5 capped
box_after=$(jq '.[] | select(.concept=="tautological_test") | .leitner_box' "$store" 2>/dev/null)
[[ "$box_before" == "5" && "$box_after" == "5" ]]
check $? "pass at box 5 stays capped at 5"

# 8 — invalid deck exits non-zero, no new card
count_before=$(jq 'length' "$store" 2>/dev/null)
run "some_concept" "category" "pass" "desc" >/dev/null 2>&1
rc=$?
count_after=$(jq 'length' "$store" 2>/dev/null)
[[ "$rc" -ne 0 && "$count_before" == "$count_after" ]]
check $? "invalid deck → non-zero, no write"

# 9 — invalid result exits non-zero, no new card
count_before=$(jq 'length' "$store" 2>/dev/null)
run "some_concept" "skill" "maybe" "desc" >/dev/null 2>&1
rc=$?
count_after=$(jq 'length' "$store" 2>/dev/null)
[[ "$rc" -ne 0 && "$count_before" == "$count_after" ]]
check $? "invalid result → non-zero, no write"

# 10 — missing required arg exits non-zero (no description)
run "concept_x" "skill" "pass" >/dev/null 2>&1
[[ $? -ne 0 ]]
check $? "missing required arg → non-zero"

# 11 — codebase deck without project exits non-zero, no write
count_before=$(jq 'length' "$store" 2>/dev/null)
run "some_concept" "codebase" "pass" "desc" >/dev/null 2>&1
rc=$?
count_after=$(jq 'length' "$store" 2>/dev/null)
[[ "$rc" -ne 0 && "$count_before" == "$count_after" ]]
check $? "codebase without project → non-zero, no write"

# 12 — cards.json remains valid JSON after all calls (atomic-write outcome)
jq -e . "$store" >/dev/null 2>&1
check $? "cards.json remains valid JSON throughout"

echo
echo "passed: $pass   failed: $fail"
[[ "$fail" -eq 0 ]]
