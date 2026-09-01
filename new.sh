#!/usr/bin/env bash
# new.sh — create a topic file with valid frontmatter.
# Exists because `scope:` is immutable and the schema is load-bearing. A hand-written file
# with a missing or misspelled key used to kill `due.sh` outright (pipefail + set -e, exit 1,
# no output). due.sh now flags such a file instead, but not producing one is still better.
#
# Usage:
#   ./new.sh <module> <topic-slug> <A|B|C> "<scope>" [start]
#
# start — when the FIRST test should happen. Default: learn.
#   learn        never studied it. No date. Sits in the backlog until worked through.
#   fresh        just learned it, still fragile. First test in 2 days.
#   known        used it for a while, confident. First test in 7 days.
#   <number>     first test in exactly that many days.
#
# Seeding sets WHEN the first test happens. It never counts as a pass: clean_passes stays 0
# until the user actually passes one, so a seeded topic that fails drops to the backlog like
# anything else. Confidence picks the date; only a passed check earns credit.
#
# Example:
#   ./new.sh MATH101 fraction-simplify A "simplify any fraction to lowest terms" known
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

[ $# -ge 4 ] && [ $# -le 5 ] || { sed -n '7,18p' "$0" >&2; exit 2; }
module="$1"; topic="$2"; variant="$3"; scope="$4"; start="${5:-learn}"

case "$variant" in A|B|C) ;; *) echo "new.sh: variant must be A (problem), B (theory) or C (coding)" >&2; exit 2 ;; esac
printf '%s' "$topic" | grep -qE '^[a-z0-9]+(-[a-z0-9]+)*$' \
  || { echo "new.sh: topic must be kebab-case, e.g. fraction-simplify" >&2; exit 2; }
case "$scope" in *'"'*) echo "new.sh: scope cannot contain a double quote" >&2; exit 2 ;; esac

case "$start" in
  learn)          interval=0 ;;
  fresh)          interval=2 ;;
  known)          interval=7 ;;
  ''|*[!0-9]*)    echo "new.sh: start must be learn, fresh, known, or a number of days" >&2; exit 2 ;;
  *)              interval="$start"
                  [ "$interval" -ge 1 ] && [ "$interval" -le 365 ] \
                    || { echo "new.sh: start in days must be 1-365" >&2; exit 2; } ;;
esac

if [ "$interval" -eq 0 ]; then
  status="queued"; next_due=""
else
  status="learning"; next_due="$(date -v+"${interval}"d +%F 2>/dev/null || date -d "+${interval} days" +%F)"
fi

slug="$(printf '%s' "$module" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/-*$//')"
file="$ROOT/topics/$slug-$topic.md"
[ -e "$file" ] && { echo "new.sh: $file already exists — scope: is immutable, edit it only via the BLOCKED path" >&2; exit 1; }

mkdir -p "$ROOT/topics"
cat > "$file" <<EOF
---
module: $module
topic: $topic
scope: "$scope"
variant: $variant
status: $status
clean_passes: 0
ease: 2.0
interval: $interval
consec_fails: 0
last_result: none
last_checked:
next_due: $next_due
---

# $topic

## Why it's here
(one line — what made this worth tracking)

## Log
EOF

echo "$file${next_due:+  (first test $next_due)}"
