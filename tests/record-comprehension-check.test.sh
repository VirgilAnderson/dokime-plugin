#!/usr/bin/env bash
# Test for bin/record-comprehension-check (dokime v2, ticket DKV2-T4).
# Run from anywhere: tests/record-comprehension-check.test.sh
#
# `set -uo pipefail` but NOT `-e` — cases below run the helper expecting
# failure and inspect $? afterward.
set -uo pipefail

cd "$(dirname "$0")/.."
HELPER="$(pwd)/bin/record-comprehension-check"   # absolute — cases cd elsewhere

pass=0
fail=0
check() { # <rc> <description>   — rc 0 = pass
  if [[ "$1" -eq 0 ]]; then echo "  ok      - $2"; pass=$((pass + 1))
  else echo "  NOT OK  - $2"; fail=$((fail + 1)); fi
}

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
export DOKIME_MEASUREMENT_STORE="$tmp"
store_file="$tmp/comprehension-checks.jsonl"

# 1 — a valid call appends exactly one line
"$HELPER" "DKV2-T4@2026-05-22T19:09:58" "DKV2-T4" "Step 3" "pass" "analyze" >/dev/null 2>&1
n=$(wc -l < "$store_file" 2>/dev/null | tr -d ' ')
[[ "$n" == "1" ]]; check $? "valid call appends exactly one line"

# 2 — the appended line is valid JSON
tail -1 "$store_file" 2>/dev/null | jq -e . >/dev/null 2>&1
check $? "appended line is valid JSON"

# 3 — record fields conform to the comprehension-checks schema
rec=$(tail -1 "$store_file" 2>/dev/null)
[[ "$(echo "$rec" | jq -r '.schema_version' 2>/dev/null)" == "1" \
   && "$(echo "$rec" | jq -r '.run_id' 2>/dev/null)" == "DKV2-T4@2026-05-22T19:09:58" \
   && "$(echo "$rec" | jq -r '.ticket_id' 2>/dev/null)" == "DKV2-T4" \
   && "$(echo "$rec" | jq -r '.step' 2>/dev/null)" == "Step 3" \
   && "$(echo "$rec" | jq -r '.result' 2>/dev/null)" == "pass" \
   && "$(echo "$rec" | jq -r '.difficulty' 2>/dev/null)" == "analyze" \
   && -n "$(echo "$rec" | jq -r '.timestamp' 2>/dev/null)" ]]
check $? "record fields conform to the schema"

# 4 — the record carries NO developer identifier (D5 / Q-T1-6)
echo "$rec" | jq -e 'has("dev") or has("developer") or has("user") | not' >/dev/null 2>&1
check $? "record carries no developer identifier (D5)"

# 5 — an invalid result exits non-zero and writes nothing
before=$(wc -l < "$store_file" 2>/dev/null | tr -d ' ')
"$HELPER" "DKV2-T4@2026-05-22T19:09:58" "DKV2-T4" "Step 3" "maybe" "analyze" >/dev/null 2>&1
rc=$?
after=$(wc -l < "$store_file" 2>/dev/null | tr -d ' ')
[[ "$rc" -ne 0 && "$before" == "$after" ]]
check $? "invalid result exits non-zero and writes nothing"

# 6 — an invalid difficulty exits non-zero and writes nothing
before=$(wc -l < "$store_file" 2>/dev/null | tr -d ' ')
"$HELPER" "DKV2-T4@2026-05-22T19:09:58" "DKV2-T4" "Step 3" "pass" "trivial" >/dev/null 2>&1
rc=$?
after=$(wc -l < "$store_file" 2>/dev/null | tr -d ' ')
[[ "$rc" -ne 0 && "$before" == "$after" ]]
check $? "invalid difficulty exits non-zero and writes nothing"

# 7 — a missing required arg exits non-zero
"$HELPER" "DKV2-T4@2026-05-22T19:09:58" "DKV2-T4" "Step 3" "pass" >/dev/null 2>&1
[[ $? -ne 0 ]]
check $? "missing required arg exits non-zero"

# 8 — store path resolved from ./.claude/dokime-config.json when env var unset
cfgdir="$(mktemp -d)"; cfgstore="$(mktemp -d)"
mkdir -p "$cfgdir/.claude"
echo "{\"measurement_store_path\": \"$cfgstore\"}" > "$cfgdir/.claude/dokime-config.json"
( cd "$cfgdir" && unset DOKIME_MEASUREMENT_STORE \
    && "$HELPER" "R" "T" "Step 3" "pass" "recall" >/dev/null 2>&1 )
[[ -f "$cfgstore/comprehension-checks.jsonl" ]]
check $? "store path resolved from ./.claude/dokime-config.json"
rm -rf "$cfgdir" "$cfgstore"

# 9 — default ~/.dokime/measurements/ when no env var and no config
homedir="$(mktemp -d)"
( cd "$homedir" && unset DOKIME_MEASUREMENT_STORE && HOME="$homedir" \
    "$HELPER" "R" "T" "Step 3" "pass" "recall" >/dev/null 2>&1 )
[[ -f "$homedir/.dokime/measurements/comprehension-checks.jsonl" ]]
check $? "default store ~/.dokime/measurements/ used when unconfigured"
rm -rf "$homedir"

echo
echo "passed: $pass   failed: $fail"
[[ "$fail" -eq 0 ]]
