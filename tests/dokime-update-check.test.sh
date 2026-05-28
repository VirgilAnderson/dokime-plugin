#!/usr/bin/env bash
# Test for bin/dokime-update-check (dokime v2, ticket DKV2-T14).
#
# dokime-update-check is the SessionStart hook helper. It compares the
# installed plugin version (${CLAUDE_PLUGIN_ROOT}/VERSION) against the latest
# (raw VERSION on main, or the DOKIME_LATEST_VERSION test seam) and prints a
# one-line nudge to stdout iff installed < latest. It NEVER blocks: exit 0
# always, fail-silent on any network/parse failure.
#
# Test seams (no network in CI):
#   CLAUDE_PLUGIN_ROOT     temp dir holding the installed VERSION file
#   DOKIME_LATEST_VERSION  injects "latest" directly (skips curl)
#   DOKIME_LATEST_URL      points curl at an endpoint (a dead one → fail-silent)
set -uo pipefail

cd "$(dirname "$0")/.."
HELPER="$(pwd)/bin/dokime-update-check"

pass=0
fail=0
check() {
  if [[ "$1" -eq 0 ]]; then echo "  ok      - $2"; pass=$((pass + 1))
  else echo "  NOT OK  - $2"; fail=$((fail + 1)); fi
}

roots=()
trap 'for r in "${roots[@]}"; do rm -rf "$r"; done' EXIT

# Sets global $root to a fresh temp plugin root holding the given VERSION.
# Global (not command-substitution) so the cleanup-trap array append lands in
# the parent shell.
setup_installed() {
  root="$(mktemp -d)"
  roots+=("$root")
  printf '%s\n' "$1" > "$root/VERSION"
}

# 1 — behind → one-line nudge naming both versions + the update command (AC3)
setup_installed 1.20.0
out=$(CLAUDE_PLUGIN_ROOT="$root" DOKIME_LATEST_VERSION="1.22.0" "$HELPER" 2>/dev/null); rc=$?
[[ $rc -eq 0 && "$out" == *"1.20.0"* && "$out" == *"1.22.0"* && "$out" == *"/dokime:update"* ]]
check $? "behind → nudge naming both versions + /dokime:update (AC3); exit 0"

# 2 — equal → silent (AC2)
setup_installed 1.20.0
out=$(CLAUDE_PLUGIN_ROOT="$root" DOKIME_LATEST_VERSION="1.20.0" "$HELPER" 2>/dev/null); rc=$?
[[ $rc -eq 0 && -z "$out" ]]
check $? "equal → silent (AC2); exit 0"

# 3 — ahead of latest (local dev) → silent (A4)
setup_installed 1.21.0
out=$(CLAUDE_PLUGIN_ROOT="$root" DOKIME_LATEST_VERSION="1.20.0" "$HELPER" 2>/dev/null); rc=$?
[[ $rc -eq 0 && -z "$out" ]]
check $? "ahead of latest → silent (A4); exit 0"

# 4 — numeric (NOT lexicographic) compare: 1.9.0 < 1.10.0 → nudge
setup_installed 1.9.0
out=$(CLAUDE_PLUGIN_ROOT="$root" DOKIME_LATEST_VERSION="1.10.0" "$HELPER" 2>/dev/null); rc=$?
[[ $rc -eq 0 && "$out" == *"1.9.0"* && "$out" == *"1.10.0"* ]]
check $? "numeric compare 1.9.0 < 1.10.0 → nudge (not lexicographic)"

# 5 — patch-level behind: 1.20.0 < 1.20.1 → nudge
setup_installed 1.20.0
out=$(CLAUDE_PLUGIN_ROOT="$root" DOKIME_LATEST_VERSION="1.20.1" "$HELPER" 2>/dev/null); rc=$?
[[ $rc -eq 0 && -n "$out" ]]
check $? "patch-level behind 1.20.0 < 1.20.1 → nudge"

# 6 — dead-URL fetch (real curl, connection refused) → silent + exit 0 (AC4)
setup_installed 1.20.0
out=$(CLAUDE_PLUGIN_ROOT="$root" DOKIME_LATEST_URL="http://127.0.0.1:1/VERSION" "$HELPER" 2>/dev/null); rc=$?
[[ $rc -eq 0 && -z "$out" ]]
check $? "dead-URL fetch → silent + exit 0 (AC4)"

# 7 — malformed remote value → silent + exit 0
setup_installed 1.20.0
out=$(CLAUDE_PLUGIN_ROOT="$root" DOKIME_LATEST_VERSION="not-a-version" "$HELPER" 2>/dev/null); rc=$?
[[ $rc -eq 0 && -z "$out" ]]
check $? "malformed remote version → silent + exit 0"

# 8 — exit code is 0 even when behind (AC5)
setup_installed 1.20.0
CLAUDE_PLUGIN_ROOT="$root" DOKIME_LATEST_VERSION="2.0.0" "$HELPER" >/dev/null 2>&1
check $? "exit code 0 even when behind (AC5)"

echo
echo "passed: $pass   failed: $fail"
[[ "$fail" -eq 0 ]]
