#!/usr/bin/env bash
# Smoke test for bin/dokime-cross-check (dokime v2, BL4).
set -uo pipefail

cd "$(dirname "$0")/.."
HELPER="$(pwd)/bin/dokime-cross-check"
RC="$(pwd)/bin/record-checkpoint"

pass=0
fail=0
check() {
  if [[ "$1" -eq 0 ]]; then echo "  ok      - $2"; pass=$((pass + 1))
  else echo "  NOT OK  - $2"; fail=$((fail + 1)); fi
}

state_dir="$(mktemp -d)"
trap 'rm -rf "$state_dir"' EXIT
export DOKIME_MEASUREMENT_STORE="$state_dir"

# Build a fixture spec with three ✓ PASSED markers.
spec="$state_dir/fake.spec.md"
cat > "$spec" <<'EOF'
# DKV2-FAKE

## Step 3
**CHECKPOINT — Step 3. ✓ PASSED (2026-05-22).** ok

## Step 4
**CHECKPOINT — Step 4. ✓ PASSED (2026-05-22).** ok

## Step 5
**CHECKPOINT — Step 5. ✓ PASSED (2026-05-22).** ok
EOF

# Three matching checkpoint records.
"$RC" "FAKE@2026-05-22T00:00:00" "DKV2-FAKE" "Step 3" "approved-clean" >/dev/null 2>&1
"$RC" "FAKE@2026-05-22T00:00:00" "DKV2-FAKE" "Step 4" "approved-clean" >/dev/null 2>&1
"$RC" "FAKE@2026-05-22T00:00:00" "DKV2-FAKE" "Step 5" "approved-clean" >/dev/null 2>&1

# 1 — match case: 3 ✓ PASSED in spec, 3 records → exit 0
"$HELPER" "$spec" "FAKE@2026-05-22T00:00:00" >/dev/null 2>&1
check $? "match — exit 0 when spec count == record count"

# 2 — mismatch case: add a 4th ✓ PASSED but no 4th record → exit 1
printf '\n**CHECKPOINT — Step 6. ✓ PASSED (2026-05-22).** ok\n' >> "$spec"
"$HELPER" "$spec" "FAKE@2026-05-22T00:00:00" >/dev/null 2>&1
[[ $? -ne 0 ]]
check $? "mismatch — non-zero when spec count > record count"

# 3 — missing spec file → exit 2
"$HELPER" "/nonexistent/spec.md" "RUN" >/dev/null 2>&1
[[ $? -ne 0 ]]
check $? "missing spec file → non-zero"

# 4 — missing args → exit 2
"$HELPER" "$spec" >/dev/null 2>&1
[[ $? -ne 0 ]]
check $? "missing args → non-zero"

echo
echo "passed: $pass   failed: $fail"
[[ "$fail" -eq 0 ]]
