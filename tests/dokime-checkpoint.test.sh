#!/usr/bin/env bash
# Test for bin/dokime-checkpoint (dokime v2, ticket DKV2-BL4).
# Run from anywhere: tests/dokime-checkpoint.test.sh
#
# dokime-checkpoint is the thin-dispatch consolidator that BL4 introduces.
# It always calls record-checkpoint; --escaped-ambiguity adds an
# escaped-ambiguity record; --comprehension adds a comprehension-checks
# record; --card additionally adds a card via capture-card (sharing the
# result from --comprehension).
#
# Each test gets a freshly minted temp dir used as BOTH HOME (so capture-card
# writes to $tmp/.dokime/knowledge) AND DOKIME_MEASUREMENT_STORE (so the
# three record-* helpers write to $tmp directly). This prevents cross-test
# leakage and keeps the real ~/.dokime untouched.
set -uo pipefail

cd "$(dirname "$0")/.."
HELPER="$(pwd)/bin/dokime-checkpoint"

pass=0
fail=0
check() {
  if [[ "$1" -eq 0 ]]; then echo "  ok      - $2"; pass=$((pass + 1))
  else echo "  NOT OK  - $2"; fail=$((fail + 1)); fi
}

state_dirs=()
trap 'for d in "${state_dirs[@]}"; do rm -rf "$d"; done' EXIT

reset_state() {
  state_dir="$(mktemp -d)"
  state_dirs+=("$state_dir")
  export DOKIME_MEASUREMENT_STORE="$state_dir"
  export HOME="$state_dir"
}

count_lines() { [[ -f "$1" ]] && wc -l < "$1" | tr -d ' ' || echo 0; }
count_cards() { [[ -f "$1" ]] && jq 'length' "$1" 2>/dev/null || echo 0; }

# 1 — bare advance: one checkpoint record, nothing else
reset_state
"$HELPER" "BL4_R" "DKV2-BL4" "Step 4" "approved-clean" >/dev/null 2>&1
[[ "$(count_lines "$state_dir/checkpoint-outcomes.jsonl")" == "1" \
   && "$(count_lines "$state_dir/escaped-ambiguity.jsonl")" == "0" \
   && "$(count_lines "$state_dir/comprehension-checks.jsonl")" == "0" \
   && "$(count_cards "$state_dir/.dokime/knowledge/cards.json")" == "0" ]]
check $? "bare advance — 1 checkpoint, no others"

# 2 — --note carries through to the checkpoint record
reset_state
"$HELPER" "BL4_R" "DKV2-BL4" "Step 4" "approved-with-changes" --note "added an AC" >/dev/null 2>&1
tail -1 "$state_dir/checkpoint-outcomes.jsonl" 2>/dev/null | jq -e '.note == "added an AC"' >/dev/null 2>&1
check $? "--note carries through to the checkpoint record"

# 3 — --escaped-ambiguity adds one escaped-ambiguity record
reset_state
"$HELPER" "BL4_R" "DKV2-BL4" "B4" "approved-clean" \
  --escaped-ambiguity "ICOV3-1588" "Step 4" "Discount stacking unspecified" >/dev/null 2>&1
[[ "$(count_lines "$state_dir/checkpoint-outcomes.jsonl")" == "1" \
   && "$(count_lines "$state_dir/escaped-ambiguity.jsonl")" == "1" ]]
check $? "--escaped-ambiguity → checkpoint + escaped-ambiguity records"

# 4 — --comprehension alone (no --card — cross-cutting concept skip)
reset_state
"$HELPER" "BL4_R" "DKV2-BL4" "Step 3" "approved-clean" \
  --comprehension "pass" "analyze" >/dev/null 2>&1
[[ "$(count_lines "$state_dir/checkpoint-outcomes.jsonl")" == "1" \
   && "$(count_lines "$state_dir/comprehension-checks.jsonl")" == "1" \
   && "$(count_cards "$state_dir/.dokime/knowledge/cards.json")" == "0" ]]
check $? "--comprehension only (no --card) → check recorded, no card"

# 5 — --comprehension + --card on skill deck → 1 checkpoint + 1 check + 1 skill card
reset_state
"$HELPER" "BL4_R" "DKV2-BL4" "Step 3" "approved-clean" \
  --comprehension "pass" "analyze" \
  --card "tautological_test" "skill" "A test that cannot fail." >/dev/null 2>&1
[[ "$(count_lines "$state_dir/checkpoint-outcomes.jsonl")" == "1" \
   && "$(count_lines "$state_dir/comprehension-checks.jsonl")" == "1" \
   && "$(count_cards "$state_dir/.dokime/knowledge/cards.json")" == "1" ]] \
   && jq -e '.[0] | .deck=="skill" and (has("project")|not)' "$state_dir/.dokime/knowledge/cards.json" >/dev/null 2>&1
check $? "--comprehension + --card skill → check + skill card (no project)"

# 6 — --card codebase requires --card-project
reset_state
"$HELPER" "BL4_R" "DKV2-BL4" "Step 3" "approved-clean" \
  --comprehension "pass" "analyze" \
  --card "my-app:src/Foo.php" "codebase" "How Foo works." \
  --card-project "my-app" >/dev/null 2>&1
jq -e '.[0] | .deck=="codebase" and .project=="my-app"' "$state_dir/.dokime/knowledge/cards.json" >/dev/null 2>&1
check $? "--comprehension + --card codebase + --card-project → codebase card with project"

# 7 — invalid outcome propagates non-zero (sub-call rejects)
reset_state
"$HELPER" "BL4_R" "DKV2-BL4" "Step 4" "bogus" >/dev/null 2>&1
rc=$?
[[ "$rc" -ne 0 && "$(count_lines "$state_dir/checkpoint-outcomes.jsonl")" == "0" ]]
check $? "invalid outcome → non-zero, no records written"

# 8 — missing required positional → non-zero
reset_state
"$HELPER" "BL4_R" "DKV2-BL4" "Step 4" >/dev/null 2>&1
[[ $? -ne 0 ]]
check $? "missing required positional → non-zero"

# 9 — --card without --comprehension → non-zero (no result to share with the card)
reset_state
"$HELPER" "BL4_R" "DKV2-BL4" "Step 3" "approved-clean" \
  --card "tautological_test" "skill" "desc" >/dev/null 2>&1
[[ $? -ne 0 ]]
check $? "--card without --comprehension → non-zero"

# 10 — --target-difficulty with --comprehension → v2 record carrying the target (T8)
reset_state
"$HELPER" "BL4_R" "DKV2-BL4" "Step 3" "approved-clean" \
  --comprehension "pass" "recall" --target-difficulty "analyze" >/dev/null 2>&1
tail -1 "$state_dir/comprehension-checks.jsonl" 2>/dev/null \
  | jq -e '.schema_version == 2 and .target_difficulty == "analyze"' >/dev/null 2>&1
check $? "--target-difficulty + --comprehension → v2 record with target"

# 11 — --comprehension without --target-difficulty → v1 record (backward-compat; T8)
reset_state
"$HELPER" "BL4_R" "DKV2-BL4" "Step 3" "approved-clean" \
  --comprehension "pass" "recall" >/dev/null 2>&1
tail -1 "$state_dir/comprehension-checks.jsonl" 2>/dev/null \
  | jq -e '.schema_version == 1' >/dev/null 2>&1
check $? "--comprehension alone → v1 record (backward-compat)"

# 12 — invalid --target-difficulty bloom → non-zero (T8)
reset_state
"$HELPER" "BL4_R" "DKV2-BL4" "Step 3" "approved-clean" \
  --comprehension "pass" "recall" --target-difficulty "BOGUS" >/dev/null 2>&1
[[ $? -ne 0 ]]
check $? "invalid --target-difficulty → non-zero"

# 13 — --comprehension-pass + --comprehension → v3 record with pass (T9)
reset_state
"$HELPER" "T9_R" "DKV2-T9" "Step 3" "approved-clean" \
  --comprehension "pass" "recall" --comprehension-pass "silent" >/dev/null 2>&1
tail -1 "$state_dir/comprehension-checks.jsonl" 2>/dev/null \
  | jq -e '.schema_version == 3 and .pass == "silent"' >/dev/null 2>&1
check $? "--comprehension-pass + --comprehension → v3 record with pass (T9)"

# 14 — --comprehension-pass + --comprehension + --target-difficulty → v3 with both fields (T9)
reset_state
"$HELPER" "T9_R" "DKV2-T9" "Step 7" "approved-clean" \
  --comprehension "pass" "apply" --target-difficulty "apply" --comprehension-pass "how" >/dev/null 2>&1
tail -1 "$state_dir/comprehension-checks.jsonl" 2>/dev/null \
  | jq -e '.schema_version == 3 and .pass == "how" and .target_difficulty == "apply"' >/dev/null 2>&1
check $? "--comprehension-pass + --target-difficulty + --comprehension → v3 with both (T9)"

# 15 — invalid --comprehension-pass enum → non-zero (T9)
reset_state
"$HELPER" "T9_R" "DKV2-T9" "Step 3" "approved-clean" \
  --comprehension "pass" "recall" --comprehension-pass "BOGUS" >/dev/null 2>&1
[[ $? -ne 0 ]]
check $? "invalid --comprehension-pass → non-zero (T9)"

# 16 — --card-label forwarded to capture-card → card written at v2 with label (T9)
reset_state
"$HELPER" "T9_R" "DKV2-T9" "Step 3" "approved-clean" \
  --comprehension "pass" "recall" \
  --card "t9_concept" "skill" "MCM-tagged via dokime-checkpoint." \
  --card-label "most_common_mistake" >/dev/null 2>&1
jq -e '.[] | select(.concept=="t9_concept") | .schema_version==2 and .label=="most_common_mistake"' \
  "$state_dir/.dokime/knowledge/cards.json" >/dev/null 2>&1
check $? "--card-label forwarded to capture-card → v2 with label (T9)"

# 17 — invalid --card-label enum → non-zero (T9)
reset_state
"$HELPER" "T9_R" "DKV2-T9" "Step 3" "approved-clean" \
  --comprehension "pass" "recall" \
  --card "bogus_label" "skill" "Bad label test." \
  --card-label "BOGUS" >/dev/null 2>&1
[[ $? -ne 0 ]]
check $? "invalid --card-label → non-zero (T9)"

echo
echo "passed: $pass   failed: $fail"
[[ "$fail" -eq 0 ]]
