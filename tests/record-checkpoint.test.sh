#!/usr/bin/env bash
# Test for bin/record-checkpoint (dokime v2, ticket DKV2-T2).
# Run from anywhere: tests/record-checkpoint.test.sh
#
# Note: uses `set -uo pipefail` but NOT `-e` — several cases deliberately
# run the helper expecting failure and inspect $? afterward.
set -uo pipefail

cd "$(dirname "$0")/.."
HELPER="$(pwd)/bin/record-checkpoint"   # absolute — cases below cd elsewhere

pass=0
fail=0
check() { # <rc> <description>   — rc 0 = pass
  if [[ "$1" -eq 0 ]]; then echo "  ok      - $2"; pass=$((pass + 1))
  else echo "  NOT OK  - $2"; fail=$((fail + 1)); fi
}

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
export DOKIME_MEASUREMENT_STORE="$tmp"
store_file="$tmp/checkpoint-outcomes.jsonl"

# 1 — a valid call appends exactly one line
"$HELPER" "DKV2-T2@2026-05-22T16:00:00" "DKV2-T2" "Step 4" "approved-clean" >/dev/null 2>&1
n=$(wc -l < "$store_file" 2>/dev/null | tr -d ' ')
[[ "$n" == "1" ]]; check $? "valid call appends exactly one line"

# 2 — the appended line is valid JSON
tail -1 "$store_file" 2>/dev/null | jq -e . >/dev/null 2>&1
check $? "appended line is valid JSON"

# 3 — record fields conform to the checkpoint-outcomes schema
rec=$(tail -1 "$store_file" 2>/dev/null)
[[ "$(echo "$rec" | jq -r '.schema_version' 2>/dev/null)" == "1" \
   && "$(echo "$rec" | jq -r '.run_id' 2>/dev/null)" == "DKV2-T2@2026-05-22T16:00:00" \
   && "$(echo "$rec" | jq -r '.ticket_id' 2>/dev/null)" == "DKV2-T2" \
   && "$(echo "$rec" | jq -r '.step' 2>/dev/null)" == "Step 4" \
   && "$(echo "$rec" | jq -r '.outcome' 2>/dev/null)" == "approved-clean" \
   && -n "$(echo "$rec" | jq -r '.timestamp' 2>/dev/null)" ]]
check $? "record fields conform to the schema"

# 4 — note key omitted when no note is given
echo "$rec" | jq -e 'has("note") | not' >/dev/null 2>&1
check $? "note key omitted when no note given"

# 5 — note recorded when given
"$HELPER" "DKV2-T2@2026-05-22T16:00:00" "DKV2-T2" "Step 7" "approved-with-changes" "added a config key" >/dev/null 2>&1
tail -1 "$store_file" 2>/dev/null | jq -e '.note == "added a config key"' >/dev/null 2>&1
check $? "note recorded when given"

# 6 — an invalid outcome exits non-zero and writes nothing
before=$(wc -l < "$store_file" 2>/dev/null | tr -d ' ')
"$HELPER" "DKV2-T2@2026-05-22T16:00:00" "DKV2-T2" "Step 9" "bogus" >/dev/null 2>&1
rc=$?
after=$(wc -l < "$store_file" 2>/dev/null | tr -d ' ')
[[ "$rc" -ne 0 && "$before" == "$after" ]]
check $? "invalid outcome exits non-zero and writes nothing"

# 7 — missing required args exits non-zero
"$HELPER" "DKV2-T2@2026-05-22T16:00:00" >/dev/null 2>&1
[[ $? -ne 0 ]]
check $? "missing required args exits non-zero"

# 8 — store path resolved from ./.claude/dokime-config.json when env var unset
cfgdir="$(mktemp -d)"; cfgstore="$(mktemp -d)"
mkdir -p "$cfgdir/.claude"
echo "{\"measurement_store_path\": \"$cfgstore\"}" > "$cfgdir/.claude/dokime-config.json"
( cd "$cfgdir" && unset DOKIME_MEASUREMENT_STORE \
    && "$HELPER" "R" "T" "Step 1" "approved-clean" >/dev/null 2>&1 )
[[ -f "$cfgstore/checkpoint-outcomes.jsonl" ]]
check $? "store path resolved from ./.claude/dokime-config.json"
rm -rf "$cfgdir" "$cfgstore"

# 9 — default ~/.dokime/measurements/ when no env var and no config
homedir="$(mktemp -d)"
( cd "$homedir" && unset DOKIME_MEASUREMENT_STORE && HOME="$homedir" \
    "$HELPER" "R" "T" "Step 1" "approved-clean" >/dev/null 2>&1 )
[[ -f "$homedir/.dokime/measurements/checkpoint-outcomes.jsonl" ]]
check $? "default store ~/.dokime/measurements/ used when unconfigured"
rm -rf "$homedir"

echo
echo "passed: $pass   failed: $fail"
[[ "$fail" -eq 0 ]]
