#!/usr/bin/env bash
# Test for bin/target-bloom (dokime v2, ticket DKV2-T8).
#
# target-bloom <concept> reads ~/.dokime/knowledge/cards.json, finds the
# card by concept slug, and applies the Q-T8-1 mapping:
#   box 1 → recall      box 4 → analyze
#   box 2 → apply       box 5 → evaluate
#   box 3 → apply
# Cold-start (no card) → recall.
set -uo pipefail

cd "$(dirname "$0")/.."
HELPER="$(pwd)/bin/target-bloom"

pass=0
fail=0
check() {
  if [[ "$1" -eq 0 ]]; then echo "  ok      - $2"; pass=$((pass + 1))
  else echo "  NOT OK  - $2"; fail=$((fail + 1)); fi
}

homes=()
trap 'for h in "${homes[@]}"; do rm -rf "$h"; done' EXIT

reset_home() {
  home="$(mktemp -d)"
  homes+=("$home")
  export HOME="$home"
  mkdir -p "$home/.dokime/knowledge"
}

seed_card_at_box() {
  # $1 = concept, $2 = leitner_box
  cat > "$home/.dokime/knowledge/cards.json" <<EOF
[{"schema_version":1,"concept":"$1","description":"d","deck":"skill","leitner_box":$2,"last_seen":"2026-05-22T00:00:00Z","created":"2026-05-22T00:00:00Z","history":[]}]
EOF
}

# 1 — box 1 → recall
reset_home; seed_card_at_box "c1" 1
result=$("$HELPER" "c1" 2>/dev/null)
[[ "$result" == "recall" ]]
check $? "box 1 → recall"

# 2 — box 2 → apply
reset_home; seed_card_at_box "c2" 2
result=$("$HELPER" "c2" 2>/dev/null)
[[ "$result" == "apply" ]]
check $? "box 2 → apply"

# 3 — box 3 → apply (doubled-up consolidation)
reset_home; seed_card_at_box "c3" 3
result=$("$HELPER" "c3" 2>/dev/null)
[[ "$result" == "apply" ]]
check $? "box 3 → apply (consolidation)"

# 4 — box 4 → analyze
reset_home; seed_card_at_box "c4" 4
result=$("$HELPER" "c4" 2>/dev/null)
[[ "$result" == "analyze" ]]
check $? "box 4 → analyze"

# 5 — box 5 → evaluate
reset_home; seed_card_at_box "c5" 5
result=$("$HELPER" "c5" 2>/dev/null)
[[ "$result" == "evaluate" ]]
check $? "box 5 → evaluate"

# 6 — cold-start: no card for the concept → recall
reset_home
echo '[]' > "$home/.dokime/knowledge/cards.json"
result=$("$HELPER" "never_seen" 2>/dev/null)
[[ "$result" == "recall" ]]
check $? "cold-start (no card for concept) → recall"

# 7 — cold-start: no cards.json at all → recall
reset_home   # don't create cards.json
result=$("$HELPER" "anything" 2>/dev/null)
[[ "$result" == "recall" ]]
check $? "cold-start (no cards.json) → recall"

# 8 — missing arg → non-zero
reset_home
"$HELPER" 2>/dev/null
[[ $? -ne 0 ]]
check $? "missing concept arg → non-zero"

echo
echo "passed: $pass   failed: $fail"
[[ "$fail" -eq 0 ]]
