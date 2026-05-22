# bin/lib/resolve-store-path.sh
#
# Sourced by the record-* helpers (record-checkpoint,
# record-escaped-ambiguity, record-comprehension-check). Extracted
# from inline duplication in those three helpers by dokime v2 BL4
# (which subsumed BL3).
#
# Exposes one function:
#
#   resolve_store_path  →  prints the resolved measurement-store directory
#
# Precedence:
#   $DOKIME_MEASUREMENT_STORE
#   → measurement_store_path in ./.claude/dokime-config.json
#   → ~/.dokime/measurements/   (default)
#
# Requires: jq

resolve_store_path() {
  local store=""
  if [[ -n "${DOKIME_MEASUREMENT_STORE:-}" ]]; then
    store="$DOKIME_MEASUREMENT_STORE"
  elif [[ -f ./.claude/dokime-config.json ]]; then
    store="$(jq -r '.measurement_store_path // empty' ./.claude/dokime-config.json)"
  fi
  if [[ -z "$store" ]]; then
    store="$HOME/.dokime/measurements"
  fi
  store="${store/#\~/$HOME}"   # expand a leading ~ from config
  printf '%s' "$store"
}
