#!/usr/bin/env bash
# Test for bin/dokime-evolution-signal (dokime v2, ticket DKV2-T13).
#
# The sensor reads the evolution corpus and prints a Markdown recurrence report:
# per failure_class — total count, distinct submitter_hash (cross-dev), and
# first/last plugin_version. Sorted by total desc. Null failure_class records
# (positive/unclassified) are excluded from the ranking and footnoted.
#
# Test seam: DOKIME_EVOLUTION_FIXTURE = path to a JSON array of records; when
# set, the helper reads it instead of hitting the network (no network in CI).
# Table column order asserted: | Failure class | Total | Devs | ... |
set -uo pipefail

cd "$(dirname "$0")/.."
HELPER="$(pwd)/bin/dokime-evolution-signal"

pass=0
fail=0
check() {
  if [[ "$1" -eq 0 ]]; then echo "  ok      - $2"; pass=$((pass + 1))
  else echo "  NOT OK  - $2"; fail=$((fail + 1)); fi
}

tmps=()
trap 'for t in "${tmps[@]}"; do rm -rf "$t"; done' EXIT

# Sets global $fix to a temp file holding the given JSON corpus.
mkfix() {
  fix="$(mktemp)"
  tmps+=("$fix")
  printf '%s' "$1" > "$fix"
}

# 1 — aggregate: per-class total + distinct-dev (cross-dev) counts
mkfix '[
  {"failure_class":"class_x","plugin_version":"1.18.0","submitter_hash":"aaa","created_at":"2026-05-01T00:00:00Z"},
  {"failure_class":"class_x","plugin_version":"1.19.0","submitter_hash":"bbb","created_at":"2026-05-10T00:00:00Z"},
  {"failure_class":"class_x","plugin_version":"1.19.0","submitter_hash":"bbb","created_at":"2026-05-12T00:00:00Z"},
  {"failure_class":"class_y","plugin_version":"1.20.0","submitter_hash":"ccc","created_at":"2026-05-20T00:00:00Z"}
]'
out=$(DOKIME_EVOLUTION_FIXTURE="$fix" "$HELPER" 2>/dev/null)
norm=$(printf '%s' "$out" | tr -s ' ')
printf '%s' "$norm" | grep -q '| class_x | 3 | 2 |' && printf '%s' "$norm" | grep -q '| class_y | 1 | 1 |'
check $? "aggregate: class_x total=3 devs=2; class_y total=1 devs=1"

# 2 — missing key (no fixture, no key, empty HOME) → non-zero exit + the RIGHT
# error (asserting the message, not just non-zero — else 'command not found'
# would satisfy it for the wrong reason).
emptyhome="$(mktemp -d)"; tmps+=("$emptyhome")
err=$(unset DOKIME_MAINTAINER_KEY; HOME="$emptyhome" DOKIME_EVOLUTION_FIXTURE="" "$HELPER" 2>&1 >/dev/null)
rc=$?
[[ $rc -ne 0 ]] && printf '%s' "$err" | grep -qi 'maintainer key'
check $? "missing maintainer key (no fixture) → non-zero exit + 'maintainer key' message"

# 3 — empty feed → A7 hedge (NOT a confident 'no signal'); exit 0
mkfix '[]'
out=$(DOKIME_EVOLUTION_FIXTURE="$fix" "$HELPER" 2>/dev/null); rc=$?
printf '%s' "$out" | grep -qi 'no records returned' && [[ $rc -eq 0 ]]
check $? "empty feed → A7 hedge ('no records returned…'); exit 0"

# 4 — sort order: higher total first
mkfix '[
  {"failure_class":"low","plugin_version":"1.20.0","submitter_hash":"a","created_at":"2026-05-20T00:00:00Z"},
  {"failure_class":"high","plugin_version":"1.20.0","submitter_hash":"a","created_at":"2026-05-01T00:00:00Z"},
  {"failure_class":"high","plugin_version":"1.20.0","submitter_hash":"b","created_at":"2026-05-02T00:00:00Z"},
  {"failure_class":"high","plugin_version":"1.20.0","submitter_hash":"c","created_at":"2026-05-03T00:00:00Z"}
]'
out=$(DOKIME_EVOLUTION_FIXTURE="$fix" "$HELPER" 2>/dev/null)
hi=$(printf '%s' "$out" | grep -n '| high ' | head -1 | cut -d: -f1)
lo=$(printf '%s' "$out" | grep -n '| low ' | head -1 | cut -d: -f1)
[[ -n "$hi" && -n "$lo" && "$hi" -lt "$lo" ]]
check $? "sort: higher-total class (high) appears before lower (low)"

# 5 — cross-dev distinct count: 2 distinct submitters vs 1 (repeated)
mkfix '[
  {"failure_class":"shared","plugin_version":"1.20.0","submitter_hash":"dev1","created_at":"2026-05-01T00:00:00Z"},
  {"failure_class":"shared","plugin_version":"1.20.0","submitter_hash":"dev2","created_at":"2026-05-02T00:00:00Z"},
  {"failure_class":"solo","plugin_version":"1.20.0","submitter_hash":"dev1","created_at":"2026-05-03T00:00:00Z"},
  {"failure_class":"solo","plugin_version":"1.20.0","submitter_hash":"dev1","created_at":"2026-05-04T00:00:00Z"}
]'
out=$(DOKIME_EVOLUTION_FIXTURE="$fix" "$HELPER" 2>/dev/null)
norm=$(printf '%s' "$out" | tr -s ' ')
printf '%s' "$norm" | grep -q '| shared | 2 | 2 |' && printf '%s' "$norm" | grep -q '| solo | 2 | 1 |'
check $? "cross-dev: shared devs=2, solo devs=1 (distinct submitter_hash)"

# 6 — null failure_class excluded from ranking, footnoted
mkfix '[
  {"failure_class":"real","plugin_version":"1.20.0","submitter_hash":"a","created_at":"2026-05-01T00:00:00Z"},
  {"failure_class":null,"plugin_version":"1.20.0","submitter_hash":"b","created_at":"2026-05-02T00:00:00Z"}
]'
out=$(DOKIME_EVOLUTION_FIXTURE="$fix" "$HELPER" 2>/dev/null)
printf '%s' "$out" | grep -q '| real ' \
  && ! printf '%s' "$out" | grep -qiE '\| *null *\|' \
  && printf '%s' "$out" | grep -qiE '1 (positive|unclassified)'
check $? "null failure_class: excluded from ranking, counted in footnote"

echo
echo "passed: $pass   failed: $fail"
[[ "$fail" -eq 0 ]]
