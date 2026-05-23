#!/usr/bin/env bash
# Test for the --review extension of bin/dokime-checkpoint (dokime v2, T7).
#
# A review:
#   - looks up an existing card by concept slug
#   - emits ONE comprehension-check record with step ending in ":review"
#   - emits ONE card update via capture-card (using the card's existing description)
#   - DOES NOT emit a checkpoint-outcomes record (Q-T7-6)
#
# Each test gets a fresh temp dir as BOTH HOME and DOKIME_MEASUREMENT_STORE.
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
  mkdir -p "$state_dir/.dokime/knowledge"
}

count_lines() { [[ -f "$1" ]] && wc -l < "$1" | tr -d ' ' || echo 0; }
count_cards() { [[ -f "$1" ]] && jq 'length' "$1" 2>/dev/null || echo 0; }

# Helper: pre-create an existing card so --review can find it.
seed_skill_card() {
  cat > "$state_dir/.dokime/knowledge/cards.json" <<EOF
[
  {"schema_version":1,"concept":"$1","description":"$2","deck":"skill","leitner_box":2,"last_seen":"2026-05-22T00:00:00Z","created":"2026-05-22T00:00:00Z","history":[{"result":"pass","timestamp":"2026-05-22T00:00:00Z"}]}
]
EOF
}

# 1 — single --review on existing skill card: 1 comprehension record (step:review), 1 card updated, NO new checkpoint-outcomes record beyond the advance itself
reset_state
seed_skill_card "tautological_test" "A test that cannot fail."
"$HELPER" "T7_R" "DKV2-T7" "Step 7" "approved-clean" \
  --review "tautological_test" "skill" "pass" "analyze" >/dev/null 2>&1
[[ "$(count_lines "$state_dir/checkpoint-outcomes.jsonl")" == "1" \
   && "$(count_lines "$state_dir/comprehension-checks.jsonl")" == "1" \
   && "$(count_cards "$state_dir/.dokime/knowledge/cards.json")" == "1" ]]
check $? "single --review → 1 checkpoint + 1 comprehension + 1 card-updated"

# 2 — the comprehension record's step ends in ":review"
step_val=$(tail -1 "$state_dir/comprehension-checks.jsonl" 2>/dev/null | jq -r '.step' 2>/dev/null)
[[ "$step_val" == "Step 7:review" ]]
check $? "comprehension record's step ends in ':review'"

# 3 — the card was promoted (box 2 → 3 on pass)
new_box=$(jq '.[0].leitner_box' "$state_dir/.dokime/knowledge/cards.json" 2>/dev/null)
[[ "$new_box" == "3" ]]
check $? "pass review promotes the existing card's Leitner box (2 → 3)"

# 4 — multiple --review flags in one call
reset_state
cat > "$state_dir/.dokime/knowledge/cards.json" <<EOF
[
  {"schema_version":1,"concept":"tautological_test","description":"A","deck":"skill","leitner_box":1,"last_seen":"2026-05-22T00:00:00Z","created":"2026-05-22T00:00:00Z","history":[]},
  {"schema_version":1,"concept":"untested_resolution_branch","description":"B","deck":"skill","leitner_box":1,"last_seen":"2026-05-22T00:00:00Z","created":"2026-05-22T00:00:00Z","history":[]}
]
EOF
"$HELPER" "T7_R" "DKV2-T7" "Step 7" "approved-clean" \
  --review "tautological_test" "skill" "pass" "analyze" \
  --review "untested_resolution_branch" "skill" "fail" "apply" >/dev/null 2>&1
[[ "$(count_lines "$state_dir/comprehension-checks.jsonl")" == "2" \
   && "$(count_lines "$state_dir/checkpoint-outcomes.jsonl")" == "1" ]]
check $? "two --reviews → 2 comprehension records + still 1 checkpoint record"

# 5 — review on a missing card → non-zero (reviews are for existing cards only)
reset_state
echo '[]' > "$state_dir/.dokime/knowledge/cards.json"
"$HELPER" "T7_R" "DKV2-T7" "Step 7" "approved-clean" \
  --review "nonexistent_concept" "skill" "pass" "analyze" >/dev/null 2>&1
rc=$?
[[ "$rc" -ne 0 ]]
check $? "review on missing card → non-zero"

# 6 — backward compatibility: a bare advance still works (no --review, no checkpoint pollution)
reset_state
"$HELPER" "T7_R" "DKV2-T7" "Step 7" "approved-clean" >/dev/null 2>&1
[[ "$(count_lines "$state_dir/checkpoint-outcomes.jsonl")" == "1" \
   && "$(count_lines "$state_dir/comprehension-checks.jsonl")" == "0" ]]
check $? "bare advance still works (no --review) — backward compatible"

# 7 — --review with 5th positional <target_difficulty> → v2 record carrying the target (T8)
reset_state
cat > "$state_dir/.dokime/knowledge/cards.json" <<EOF
[
  {"schema_version":1,"concept":"tautological_test","description":"d","deck":"skill","leitner_box":4,"last_seen":"2026-05-22T00:00:00Z","created":"2026-05-22T00:00:00Z","history":[]}
]
EOF
"$HELPER" "T7_R" "DKV2-T7" "Step 7" "approved-clean" \
  --review "tautological_test" "skill" "pass" "analyze" "analyze" >/dev/null 2>&1
tail -1 "$state_dir/comprehension-checks.jsonl" 2>/dev/null \
  | jq -e '.schema_version == 2 and .target_difficulty == "analyze"' >/dev/null 2>&1
check $? "--review with per-review target → v2 record carries the target"

# 8 — two --reviews with DIFFERENT per-review targets → two v2 records with distinct targets (T8)
reset_state
cat > "$state_dir/.dokime/knowledge/cards.json" <<EOF
[
  {"schema_version":1,"concept":"low_box","description":"d","deck":"skill","leitner_box":1,"last_seen":"2026-05-22T00:00:00Z","created":"2026-05-22T00:00:00Z","history":[]},
  {"schema_version":1,"concept":"high_box","description":"d","deck":"skill","leitner_box":5,"last_seen":"2026-05-22T00:00:00Z","created":"2026-05-22T00:00:00Z","history":[]}
]
EOF
"$HELPER" "T7_R" "DKV2-T7" "Step 7" "approved-clean" \
  --review "low_box" "skill" "pass" "recall" "recall" \
  --review "high_box" "skill" "pass" "evaluate" "evaluate" >/dev/null 2>&1
recs=$(jq -s -c '[.[] | .target_difficulty] | sort' "$state_dir/comprehension-checks.jsonl" 2>/dev/null)
[[ "$recs" == '["evaluate","recall"]' ]]
check $? "two --reviews with distinct per-review targets → two v2 records with distinct targets"

# 9 — --review's optional 5th arg invalid bloom → non-zero, no records (T8)
reset_state
cat > "$state_dir/.dokime/knowledge/cards.json" <<EOF
[{"schema_version":1,"concept":"tautological_test","description":"d","deck":"skill","leitner_box":2,"last_seen":"2026-05-22T00:00:00Z","created":"2026-05-22T00:00:00Z","history":[]}]
EOF
"$HELPER" "T7_R" "DKV2-T7" "Step 7" "approved-clean" \
  --review "tautological_test" "skill" "pass" "apply" "BOGUS" >/dev/null 2>&1
rc=$?
[[ "$rc" -ne 0 && "$(count_lines "$state_dir/comprehension-checks.jsonl")" == "0" ]]
check $? "--review with invalid 5th-arg target → non-zero, no records"

echo
echo "passed: $pass   failed: $fail"
[[ "$fail" -eq 0 ]]
