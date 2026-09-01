#!/usr/bin/env bash
# due.sh — what to study today. DERIVED from topic frontmatter, never stored.
# Exists so the due list can't drift from the records it describes.
#
# Usage:
#   ./due.sh            due + backlog
#   ./due.sh all        everything incl. scheduled, dormant, retired
#   ./due.sh stats      counts by status
#   ./due.sh calib      3 random topics for a blind re-test (run in a FRESH session)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"
TODAY="$(date +%F)"

# read one frontmatter field — scoped to the first --- block, so body text can't spoof it
# `|| true` is load-bearing: under `set -o pipefail` a missing key makes grep return 1,
# which under `set -e` killed the whole run with no output and no error. One typo'd
# frontmatter field must degrade to one flagged line, not take down the entire due list.
fm() { sed -n '/^---$/,/^---$/p' "$1" | grep -E "^$2:" | head -1 | sed -E "s/^$2:[[:space:]]*//" || true ; }

shopt -s nullglob
FILES=(topics/*.md)
[ ${#FILES[@]} -eq 0 ] && { echo "no topics yet — create some with ./new.sh"; exit 0; }

cmd="${1:-due}"

case "$cmd" in
  stats)
    # counted via fm() so a body line can never be mistaken for frontmatter
    for s in queued learning dormant retired; do
      n=0
      for f in "${FILES[@]}"; do [ "$(fm "$f" status)" = "$s" ] && n=$((n+1)); done
      printf '%-10s %s\n' "$s" "$n"
    done
    ;;

  calib)
    # blind re-test pool: things the log claims are known
    pool=()
    for f in "${FILES[@]}"; do
      st="$(fm "$f" status)"; cp="$(fm "$f" clean_passes)"; cp="${cp:-0}"
      if [ "$st" = "dormant" ] || { [ "$st" = "learning" ] && [ "$cp" -ge 2 ] 2>/dev/null; }; then
        pool+=("$f")
      fi
    done
    [ ${#pool[@]} -eq 0 ] && { echo "calib: nothing claimed as known yet — pool empty"; exit 0; }
    echo "=== BLIND RE-TEST — run these in a FRESH session, no history ==="
    echo "Give the tester ONLY the scope: line. Withhold the stored verdict."
    echo
    printf '%s\n' "${pool[@]}" | sort -R | head -3 | while read -r f; do
      printf '%s\n  scope: %s\n' "$f" "$(fm "$f" scope)"
    done
    ;;

  all|due)
    due=(); new=(); soon=(); later=()
    for f in "${FILES[@]}"; do
      st="$(fm "$f" status)"
      [ "$st" = "retired" ] && [ "$cmd" != "all" ] && continue
      mod="$(fm "$f" module)"; top="$(fm "$f" topic)"; var="$(fm "$f" variant)"
      nd="$(fm "$f" next_due)"; cp="$(fm "$f" clean_passes)"; cp="${cp:-0}"
      cf="$(fm "$f" consec_fails)"; cf="${cf:-0}"

      if [ -z "$st" ]; then
        # no readable status: -> the frontmatter is broken, not the schedule. Say so loudly.
        due+=("$(printf '%-12s %-32s [%s] %s p:%s f:%s  %s' "$mod" "$top" "$var" "?" "$cp" "$cf" "$f")  !! frontmatter malformed — no readable status: field")
        continue
      fi

      flag=""
      [ "$cf" -ge 2 ] 2>/dev/null && flag="
      ** SCAFFOLD (${cf} consecutive fails) — drop a rung, no cold test this time"
      [ "$cf" -ge 4 ] 2>/dev/null && flag="
      ** BLOCKED (${cf} consecutive fails) — scope: is too broad, rewrite it before retesting"

      line="$(printf '%-12s %-32s [%s] %s p:%s f:%s  %s' "$mod" "$top" "$var" "$st" "$cp" "$cf" "$f")"

      if [ "$st" = "queued" ] || { [ "$cp" -eq 0 ] && [ -z "$nd" ]; }; then
        # never passed -> backlog, no date. Worked through by choice, not by calendar.
        # $flag still applies: a topic can hit SCAFFOLD/BLOCKED before it ever passes,
        # and that is exactly when the user most needs to see it.
        new+=("$line$flag")
      elif ! printf '%s' "$nd" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'; then
        # once a topic HAS been passed, a missing date is a dropped write, not a backlog item
        due+=("$line  !! next_due missing or malformed — forced DUE$flag")
      elif [ ! "$nd" \> "$TODAY" ]; then
        due+=("$line$flag")
      elif [ "$st" = "dormant" ]; then
        later+=("$(printf '%s  (dormant until %s)' "$line" "$nd")")
      else
        soon+=("$(printf '%s  (due %s)' "$line" "$nd")")
      fi
    done

    echo "=== DUE TODAY ($TODAY) — ${#due[@]} ==="
    printf '%s\n' "${due[@]:-  (none)}"
    echo; echo "=== TO LEARN / RELEARN (no date — your choice) — ${#new[@]} ==="
    printf '%s\n' "${new[@]:-  (none)}"
    if [ "$cmd" = "all" ]; then
      echo; echo "=== SCHEDULED — ${#soon[@]} ==="
      printf '%s\n' "${soon[@]:-  (none)}"
      echo; echo "=== DORMANT — ${#later[@]} ==="
      printf '%s\n' "${later[@]:-  (none)}"
    fi
    ;;

  *) echo "due.sh: unknown command '$cmd' — try: due | all | stats | calib" >&2; exit 1 ;;
esac
