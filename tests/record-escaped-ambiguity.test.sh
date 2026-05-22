#!/usr/bin/env bash
# Test for bin/record-escaped-ambiguity (dokime v2, ticket DKV2-T3).
# Run from anywhere: tests/record-escaped-ambiguity.test.sh
#
# Note: `set -uo pipefail` but NOT `-e` — a case deliberately runs the
# helper expecting failure and inspects $? afterward.
set -uo pipefail

cd "$(dirname "$0")/.."
HELPER="$(pwd)/bin/record-escaped-ambiguity"   # absolute — cases below cd elsewhere

pass=0
fail=0
check() { # <rc> <description>   — rc 0 = pass
  if [[ "$1" -eq 0 ]]; then echo "  ok      - $2"; pass=$((pass + 1))
  else echo "  NOT OK  - $2"; fail=$((fail + 1)); fi
}

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
export DOKIME_MEASUREMENT_STORE="$tmp"
store_file="$tmp/escaped-ambiguity.jsonl"

# 1 — a valid call appends exactly one line
"$HELPER" "DKV2-T3@2026-05-22T18:48:17" "ICOV3-1601" "ICOV3-1588" "Step 4" \
  "Discount stacking order was never specified" >/dev/null 2>&1
n=$(wc -l < "$store_file" 2>/dev/null | tr -d ' ')
[[ "$n" == "1" ]]; check $? "valid call appends exactly one line"

# 2 — the appended line is valid JSON
tail -1 "$store_file" 2>/dev/null | jq -e . >/dev/null 2>&1
check $? "appended line is valid JSON"

# 3 — record fields conform to the escaped-ambiguity schema
rec=$(tail -1 "$store_file" 2>/dev/null)
[[ "$(echo "$rec" | jq -r '.schema_version' 2>/dev/null)" == "1" \
   && "$(echo "$rec" | jq -r '.run_id' 2>/dev/null)" == "DKV2-T3@2026-05-22T18:48:17" \
   && "$(echo "$rec" | jq -r '.ticket_id' 2>/dev/null)" == "ICOV3-1601" \
   && "$(echo "$rec" | jq -r '.origin_ticket_id' 2>/dev/null)" == "ICOV3-1588" \
   && "$(echo "$rec" | jq -r '.origin_step' 2>/dev/null)" == "Step 4" \
   && "$(echo "$rec" | jq -r '.description' 2>/dev/null)" == "Discount stacking order was never specified" \
   && -n "$(echo "$rec" | jq -r '.timestamp' 2>/dev/null)" ]]
check $? "record fields conform to the schema"

# 4 — origin_ticket_id "unknown" is accepted and recorded
"$HELPER" "DKV2-T3@2026-05-22T18:48:17" "ICOV3-1602" "unknown" "unknown" \
  "A boundary condition that was never specified" >/dev/null 2>&1
tail -1 "$store_file" 2>/dev/null | jq -e '.origin_ticket_id == "unknown"' >/dev/null 2>&1
check $? "origin_ticket_id 'unknown' accepted and recorded"

# 5 — a missing required arg exits non-zero
"$HELPER" "DKV2-T3@2026-05-22T18:48:17" "ICOV3-1601" "ICOV3-1588" "Step 4" >/dev/null 2>&1
[[ $? -ne 0 ]]
check $? "missing required arg exits non-zero"

# 6 — store path resolved from ./.claude/dokime-config.json when env var unset
cfgdir="$(mktemp -d)"; cfgstore="$(mktemp -d)"
mkdir -p "$cfgdir/.claude"
echo "{\"measurement_store_path\": \"$cfgstore\"}" > "$cfgdir/.claude/dokime-config.json"
( cd "$cfgdir" && unset DOKIME_MEASUREMENT_STORE \
    && "$HELPER" "R" "T" "O" "Step 4" "d" >/dev/null 2>&1 )
[[ -f "$cfgstore/escaped-ambiguity.jsonl" ]]
check $? "store path resolved from ./.claude/dokime-config.json"
rm -rf "$cfgdir" "$cfgstore"

# 7 — default ~/.dokime/measurements/ when no env var and no config
homedir="$(mktemp -d)"
( cd "$homedir" && unset DOKIME_MEASUREMENT_STORE && HOME="$homedir" \
    "$HELPER" "R" "T" "O" "Step 4" "d" >/dev/null 2>&1 )
[[ -f "$homedir/.dokime/measurements/escaped-ambiguity.jsonl" ]]
check $? "default store ~/.dokime/measurements/ used when unconfigured"
rm -rf "$homedir"

echo
echo "passed: $pass   failed: $fail"
[[ "$fail" -eq 0 ]]
