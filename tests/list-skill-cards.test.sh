#!/usr/bin/env bash
# Test for bin/list-skill-cards (dokime v2, ticket DKV2-T7).
set -uo pipefail

cd "$(dirname "$0")/.."
HELPER="$(pwd)/bin/list-skill-cards"

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

write_cards() { printf '%s' "$1" > "$home/.dokime/knowledge/cards.json"; }

# 1 — empty deck → []
reset_home
write_cards '[]'
result=$("$HELPER" 2>/dev/null)
[[ "$result" == "[]" ]]
check $? "empty deck → []"

# 2 — multiple skill cards returned
reset_home
write_cards '[
  {"schema_version":1,"concept":"tautological_test","description":"d","deck":"skill","leitner_box":2,"last_seen":"2026-05-22T00:00:00Z","created":"2026-05-22T00:00:00Z","history":[]},
  {"schema_version":1,"concept":"untested_resolution_branch","description":"d","deck":"skill","leitner_box":1,"last_seen":"2026-05-22T00:00:00Z","created":"2026-05-22T00:00:00Z","history":[]}
]'
result=$("$HELPER" 2>/dev/null)
count=$(echo "$result" | jq 'length' 2>/dev/null)
[[ "$count" == "2" ]]
check $? "multiple skill cards returned"

# 3 — codebase cards filtered out (skill = deck only)
reset_home
write_cards '[
  {"schema_version":1,"concept":"tautological_test","description":"d","deck":"skill","leitner_box":1,"last_seen":"2026-05-22T00:00:00Z","created":"2026-05-22T00:00:00Z","history":[]},
  {"schema_version":1,"concept":"my-app:src/Foo.php","description":"d","deck":"codebase","project":"my-app","leitner_box":1,"last_seen":"2026-05-22T00:00:00Z","created":"2026-05-22T00:00:00Z","history":[]}
]'
result=$("$HELPER" 2>/dev/null)
count=$(echo "$result" | jq 'length' 2>/dev/null)
[[ "$count" == "1" ]]
check $? "codebase cards filtered from skill list"

# 4 — sorted by leitner_box ascending
reset_home
write_cards '[
  {"schema_version":1,"concept":"tautological_test","description":"d","deck":"skill","leitner_box":4,"last_seen":"2026-05-22T00:00:00Z","created":"2026-05-22T00:00:00Z","history":[]},
  {"schema_version":1,"concept":"untested_resolution_branch","description":"d","deck":"skill","leitner_box":1,"last_seen":"2026-05-22T00:00:00Z","created":"2026-05-22T00:00:00Z","history":[]}
]'
result=$("$HELPER" 2>/dev/null)
first_box=$(echo "$result" | jq '.[0].leitner_box' 2>/dev/null)
[[ "$first_box" == "1" ]]
check $? "results sorted ascending by leitner_box"

# 5 — missing cards.json → []
reset_home   # no write_cards call
result=$("$HELPER" 2>/dev/null)
[[ "$result" == "[]" ]]
check $? "missing cards.json → []"

echo
echo "passed: $pass   failed: $fail"
[[ "$fail" -eq 0 ]]
