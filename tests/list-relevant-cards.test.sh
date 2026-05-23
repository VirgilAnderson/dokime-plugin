#!/usr/bin/env bash
# Test for bin/list-relevant-cards (dokime v2, ticket DKV2-T7).
set -uo pipefail

cd "$(dirname "$0")/.."
HELPER="$(pwd)/bin/list-relevant-cards"

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
result=$("$HELPER" "my-app" "src/Foo.php" 2>/dev/null)
[[ "$result" == "[]" ]]
check $? "empty deck → []"

# 2 — one matching codebase card returned
reset_home
write_cards '[{"schema_version":1,"concept":"my-app:src/Foo.php","description":"d","deck":"codebase","project":"my-app","leitner_box":2,"last_seen":"2026-05-22T00:00:00Z","created":"2026-05-22T00:00:00Z","history":[]}]'
result=$("$HELPER" "my-app" "src/Foo.php" 2>/dev/null)
count=$(echo "$result" | jq 'length' 2>/dev/null)
[[ "$count" == "1" ]]
check $? "one matching codebase card returned"

# 3 — skill cards filtered (narrow = codebase only)
reset_home
write_cards '[{"schema_version":1,"concept":"tautological_test","description":"d","deck":"skill","leitner_box":1,"last_seen":"2026-05-22T00:00:00Z","created":"2026-05-22T00:00:00Z","history":[]}]'
result=$("$HELPER" "my-app" "src/Foo.php" 2>/dev/null)
count=$(echo "$result" | jq 'length' 2>/dev/null)
[[ "$count" == "0" ]]
check $? "skill cards filtered from narrow result"

# 4 — sorted by leitner_box ascending
reset_home
write_cards '[
  {"schema_version":1,"concept":"my-app:src/Foo.php","description":"d","deck":"codebase","project":"my-app","leitner_box":3,"last_seen":"2026-05-22T00:00:00Z","created":"2026-05-22T00:00:00Z","history":[]},
  {"schema_version":1,"concept":"my-app:src/Bar.php","description":"d","deck":"codebase","project":"my-app","leitner_box":1,"last_seen":"2026-05-22T00:00:00Z","created":"2026-05-22T00:00:00Z","history":[]}
]'
result=$("$HELPER" "my-app" "src/Foo.php" "src/Bar.php" 2>/dev/null)
first_box=$(echo "$result" | jq '.[0].leitner_box' 2>/dev/null)
[[ "$first_box" == "1" ]]
check $? "results sorted ascending by leitner_box"

# 5 — different-project cards filtered
reset_home
write_cards '[{"schema_version":1,"concept":"other-project:src/Foo.php","description":"d","deck":"codebase","project":"other-project","leitner_box":1,"last_seen":"2026-05-22T00:00:00Z","created":"2026-05-22T00:00:00Z","history":[]}]'
result=$("$HELPER" "my-app" "src/Foo.php" 2>/dev/null)
count=$(echo "$result" | jq 'length' 2>/dev/null)
[[ "$count" == "0" ]]
check $? "different-project codebase cards filtered"

# 6 — missing project arg → non-zero
reset_home
"$HELPER" 2>/dev/null
[[ $? -ne 0 ]]
check $? "missing project arg → non-zero"

# 7 — empty cards.json (no file) → []
reset_home   # no write_cards call → cards.json absent
result=$("$HELPER" "my-app" "src/Foo.php" 2>/dev/null)
[[ "$result" == "[]" ]]
check $? "missing cards.json → []"

echo
echo "passed: $pass   failed: $fail"
[[ "$fail" -eq 0 ]]
