#!/usr/bin/env bash
# test.sh — exercises due.sh, grade.py and new.sh against every scenario they claim to handle.
# Runs in a scratch copy, so the real topics/ is never touched.
#
#   ./test.sh            run everything
#   ./test.sh -v         also print each passing assertion
# ok() ends in an explicit `return 0` and bad() ends in printf, so both always succeed.
# That makes `assertion && ok || bad` safe throughout this file: the bad branch cannot
# fire after a passing assertion.
# shellcheck disable=SC2015
set -uo pipefail        # deliberately NOT -e: a failing assertion must not stop the run

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERBOSE="${1:-}"
PASSED=0; FAILED=0; CASE="(none)"

WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
cp "$ROOT/due.sh" "$ROOT/grade.py" "$ROOT/new.sh" "$WORK/"
# || exit is load-bearing: without it a failed cd runs every assertion against the real
# topics/ directory instead of the sandbox copy.
cd "$WORK" || exit 1

TODAY="$(date +%F)"
day() { date -v"$1"d +%F 2>/dev/null || date -d "$1 days" +%F; }   # day +3 / day -1

case_() { CASE="$1"; }
ok()   { PASSED=$((PASSED+1)); [ "$VERBOSE" = "-v" ] && printf '  ok   %s: %s\n' "$CASE" "$1"; return 0; }
bad()  { FAILED=$((FAILED+1)); printf 'FAIL  %s: %s\n' "$CASE" "$1"; }

assert_has()  { printf '%s' "$1" | grep -qF -- "$2" && ok "contains '$2'" || bad "expected '$2' in: $1"; }
assert_not()  { printf '%s' "$1" | grep -qF -- "$2" && bad "did NOT expect '$2' in: $1" || ok "lacks '$2'"; }
assert_eq()   { [ "$1" = "$2" ] && ok "'$1'" || bad "expected '$2', got '$1'"; }
assert_exit() { [ "$1" -eq "$2" ] && ok "exit $2" || bad "expected exit $2, got $1"; }

# write a topic fixture directly — the only way to test dates the scripts cannot reach today
fixture() { # fixture <file> <status> <passes> <fails> <interval> <next_due> [ease]
  mkdir -p topics
  cat > "topics/$1.md" <<EOF
---
module: MOD
topic: $1
scope: "a fixed bar"
variant: A
status: $2
clean_passes: $3
ease: ${7:-2.0}
interval: $5
consec_fails: $4
last_result: none
last_checked: $TODAY
next_due: $6
---

# $1

## Log
EOF
}
reset() { rm -rf topics; mkdir -p topics; }

fm() { sed -n '/^---$/,/^---$/p' "topics/$1.md" | grep -E "^$2:" | head -1 | sed -E "s/^$2:[[:space:]]*//"; }

echo "== due.sh: listing and sorting =="
reset
case_ "empty topics/"
out="$(./due.sh)"; assert_has "$out" "no topics yet"; assert_exit $? 0

reset; fixture backlog queued 0 0 0 ""
case_ "queued topic goes to the backlog, not DUE"
out="$(./due.sh)"
assert_has "$out" "TO LEARN / RELEARN (no date, your choice): 1"
assert_has "$out" "DUE TODAY ($TODAY): 0"

reset; fixture pastdue learning 1 0 3 "$(day -1)"
case_ "past date is due"
assert_has "$(./due.sh)" "DUE TODAY ($TODAY): 1"

reset; fixture exactly learning 1 0 3 "$TODAY"
case_ "due exactly today is due (boundary)"
assert_has "$(./due.sh)" "DUE TODAY ($TODAY): 1"

reset; fixture tomorrow learning 1 0 3 "$(day +1)"
case_ "due tomorrow is not due (boundary)"
out="$(./due.sh)"; assert_has "$out" "DUE TODAY ($TODAY): 0"
assert_has "$(./due.sh all)" "SCHEDULED: 1"

reset; fixture sleepy dormant 4 0 120 "$(day +100)"
case_ "dormant appears only under 'all'"
assert_not "$(./due.sh)" "sleepy"
assert_has "$(./due.sh all)" "DORMANT: 1"

reset; fixture done_ retired 6 0 365 "$(day +300)"
case_ "retired hidden from due, shown in all"
assert_not "$(./due.sh)" "done_"
assert_has "$(./due.sh all)" "done_"

echo "== due.sh: circuit breakers =="
reset; fixture shaky learning 1 2 1 "$(day -1)"
case_ "SCAFFOLD at 2 fails on a due topic"
assert_has "$(./due.sh)" "SCAFFOLD (2 consecutive fails)"

reset; fixture neverpassed learning 0 2 0 ""
case_ "SCAFFOLD also fires for a backlog topic (regression: it used to be dropped)"
assert_has "$(./due.sh)" "SCAFFOLD (2 consecutive fails)"

reset; fixture broken learning 0 4 0 ""
case_ "BLOCKED at 4 fails"
out="$(./due.sh)"; assert_has "$out" "BLOCKED (4 consecutive fails)"; assert_not "$out" "SCAFFOLD"

echo "== due.sh: robustness =="
reset; fixture good queued 0 0 0 ""
sed 's/^status:/statuss:/' topics/good.md > topics/bent.md
case_ "a missing frontmatter key is flagged, and does not kill the run (regression)"
out="$(./due.sh)"; rc=$?
assert_exit $rc 0
assert_has "$out" "frontmatter malformed"
assert_has "$out" "good"

reset; fixture dropped learning 2 0 10 ""
case_ "a passed topic with no date is forced due, not silently backlogged"
assert_has "$(./due.sh)" "next_due missing or malformed, forced DUE"

# The discriminating case is a key ABSENT from the frontmatter but present in the body.
# With a body line placed after a real key, `head -1` picks the real one either way, so that
# arrangement proves nothing.
reset; fixture spoof queued 0 0 0 ""
grep -v '^consec_fails:' topics/spoof.md > topics/tmp && mv topics/tmp topics/spoof.md
printf '\nconsec_fails: 9\n' >> topics/spoof.md
case_ "a body line cannot supply a frontmatter key that is missing"
out="$(./due.sh)"; assert_has "$out" "spoof"; assert_not "$out" "BLOCKED"

reset; fixture ghost queued 0 0 0 ""
grep -v '^status:' topics/ghost.md > topics/tmp && mv topics/tmp topics/ghost.md
printf '\nstatus: retired\n' >> topics/ghost.md
case_ "a body status: cannot hide a topic by faking retirement"
out="$(./due.sh)"; assert_has "$out" "ghost"; assert_has "$out" "frontmatter malformed"

case_ "unknown command fails loudly"
./due.sh bogus >/dev/null 2>&1; assert_exit $? 1

echo "== due.sh: stats and calib =="
reset; fixture a queued 0 0 0 ""; fixture b learning 1 0 3 "$(day +1)"
fixture c dormant 4 0 120 "$(day +90)"; fixture d retired 6 0 365 "$(day +300)"
case_ "stats counts each status once"
out="$(./due.sh stats)"
assert_eq "$(printf '%s' "$out" | grep -c .)" "4"
assert_has "$out" "queued     1"; assert_has "$out" "dormant    1"

reset; fixture fresh_ learning 1 0 3 "$(day +1)"
case_ "calib pool is empty when nothing is claimed as known"
assert_has "$(./due.sh calib)" "pool empty"

reset; fixture known_ learning 2 0 10 "$(day +5)"
case_ "calib picks a topic with 2 passes and shows only its scope"
out="$(./due.sh calib)"; assert_has "$out" "known_"; assert_has "$out" "scope: \"a fixed bar\""

echo "== grade.py: the schedule =="
reset; fixture t queued 0 0 0 ""
case_ "pass 1 -> 3d, pass 2 -> 10d, pass 3 -> interval x ease"
./grade.py topics/t.md pass "n" >/dev/null; assert_eq "$(fm t interval)" "3"; assert_eq "$(fm t clean_passes)" "1"
./grade.py topics/t.md pass "n" >/dev/null; assert_eq "$(fm t interval)" "10"
./grade.py topics/t.md pass "n" >/dev/null; assert_eq "$(fm t interval)" "24"
assert_eq "$(fm t status)" "learning"

reset; fixture p learning 3 0 24 "$TODAY" 2.45
case_ "partial halves the interval and drops ease"
./grade.py topics/p.md partial "n" >/dev/null
assert_eq "$(fm p interval)" "12"; assert_eq "$(fm p ease)" "2.3"; assert_eq "$(fm p clean_passes)" "3"

reset; fixture f1 learning 2 0 10 "$TODAY"
case_ "first fail costs one pass and drops to 1 day"
./grade.py topics/f1.md fail "n" >/dev/null
assert_eq "$(fm f1 clean_passes)" "1"; assert_eq "$(fm f1 interval)" "1"; assert_eq "$(fm f1 consec_fails)" "1"

reset; fixture f2 learning 3 1 1 "$TODAY"
case_ "a fail during a streak costs every pass"
./grade.py topics/f2.md fail "n" >/dev/null
assert_eq "$(fm f2 clean_passes)" "0"; assert_eq "$(fm f2 consec_fails)" "2"

case_ "dropping to zero passes unschedules the topic"
assert_eq "$(fm f2 interval)" "0"; assert_eq "$(fm f2 next_due)" ""
assert_has "$(./due.sh)" "TO LEARN / RELEARN (no date, your choice): 1"

reset; fixture d1 learning 4 0 60 "$TODAY" 2.5
case_ "interval >= 90 becomes dormant"
./grade.py topics/d1.md pass "n" >/dev/null
assert_eq "$(fm d1 interval)" "150"; assert_eq "$(fm d1 status)" "dormant"

reset; fixture r1 dormant 5 0 150 "$TODAY" 2.5
case_ "interval reaching the cap retires the topic"
./grade.py topics/r1.md pass "n" >/dev/null
assert_eq "$(fm r1 interval)" "365"; assert_eq "$(fm r1 status)" "retired"

reset; fixture r2 retired 6 0 365 "$TODAY" 2.5
case_ "interval never exceeds the 365 cap"
./grade.py topics/r2.md pass "n" >/dev/null; assert_eq "$(fm r2 interval)" "365"

case_ "a fail returns even a retired topic to learning"
./grade.py topics/r2.md fail "n" >/dev/null; assert_eq "$(fm r2 status)" "learning"

reset; fixture e1 learning 5 0 10 "$TODAY" 2.45
case_ "ease is capped at 2.5"
./grade.py topics/e1.md pass "n" >/dev/null; assert_eq "$(fm e1 ease)" "2.5"
./grade.py topics/e1.md pass "n" >/dev/null; assert_eq "$(fm e1 ease)" "2.5"

reset; fixture e2 learning 1 0 1 "$TODAY" 1.4
case_ "ease has a floor of 1.3"
./grade.py topics/e2.md fail "n" >/dev/null; assert_eq "$(fm e2 ease)" "1.3"
./grade.py topics/e2.md fail "n" >/dev/null; assert_eq "$(fm e2 ease)" "1.3"

echo "== grade.py: seeded topics =="
reset
case_ "a seeded topic climbs from its seed instead of resetting to 3d (regression)"
./new.sh MOD seeded A "a fixed bar" known >/dev/null
assert_eq "$(fm mod-seeded interval)" "7"; assert_eq "$(fm mod-seeded clean_passes)" "0"
./grade.py topics/mod-seeded.md pass "n" >/dev/null
assert_eq "$(fm mod-seeded interval)" "15"
./grade.py topics/mod-seeded.md pass "n" >/dev/null
assert_eq "$(fm mod-seeded interval)" "34"

reset
case_ "seeding is not a pass: a seeded topic that fails drops to the backlog"
./new.sh MOD trusted A "a fixed bar" known >/dev/null
./grade.py topics/mod-trusted.md fail "n" >/dev/null
assert_eq "$(fm mod-trusted clean_passes)" "0"; assert_eq "$(fm mod-trusted next_due)" ""

echo "== grade.py: writes and guards =="
reset; fixture w queued 0 0 0 ""
case_ "the log line records the grade, the date and the note"
./grade.py topics/w.md pass "named the common factor" >/dev/null
assert_has "$(cat topics/w.md)" "- PASSED $TODAY: named the common factor"
./grade.py topics/w.md fail "no method recalled" >/dev/null
assert_has "$(cat topics/w.md)" "- MISSED $TODAY: no method recalled"
./grade.py topics/w.md partial "half of it" >/dev/null
assert_has "$(cat topics/w.md)" "- PARTIAL $TODAY: half of it"

case_ "last_checked and last_result are written"
assert_eq "$(fm w last_result)" "partial"; assert_eq "$(fm w last_checked)" "$TODAY"

reset; fixture dr queued 0 0 0 ""
before="$(cat topics/dr.md)"
case_ "--dry-run changes nothing on disk"
./grade.py topics/dr.md pass --dry-run >/dev/null
assert_eq "$(cat topics/dr.md)" "$before"

case_ "an invalid grade is refused"
./grade.py topics/dr.md excellent "n" >/dev/null 2>&1; assert_exit $? 1

case_ "--simulate runs and prints all three curves"
out="$(./grade.py --simulate)"; rc=$?
assert_exit $rc 0
assert_has "$out" "EASY"; assert_has "$out" "MIXED"; assert_has "$out" "HARD"

echo "== new.sh =="
reset
case_ "a created topic has every field the schema requires"
./new.sh MATH101 long-division A "divide a 4-digit number by a 2-digit one" >/dev/null
for k in module topic scope variant status clean_passes ease interval consec_fails last_result next_due; do
  sed -n '/^---$/,/^---$/p' topics/math101-long-division.md | grep -q "^$k:" \
    && ok "has $k:" || bad "missing $k:"
done
assert_eq "$(fm math101-long-division status)" "queued"

case_ "a duplicate is refused, because scope: is immutable"
./new.sh MATH101 long-division A "something else" >/dev/null 2>&1; assert_exit $? 1

case_ "bad input is refused"
./new.sh MOD Bad_Slug A "x" >/dev/null 2>&1;      assert_exit $? 2
./new.sh MOD ok-slug D "x" >/dev/null 2>&1;       assert_exit $? 2
./new.sh MOD ok-slug A 'has "quotes"' >/dev/null 2>&1; assert_exit $? 2
./new.sh MOD ok-slug A "x" sometime >/dev/null 2>&1;   assert_exit $? 2
./new.sh MOD ok-slug A "x" 400 >/dev/null 2>&1;   assert_exit $? 2
./new.sh MOD ok-slug A "x" 0 >/dev/null 2>&1;     assert_exit $? 2
./new.sh MOD toofew >/dev/null 2>&1;              assert_exit $? 2

reset
case_ "each start state produces the right first-test date"
./new.sh MOD a A "x" learn >/dev/null; assert_eq "$(fm mod-a next_due)" ""; assert_eq "$(fm mod-a status)" "queued"
./new.sh MOD b A "x" fresh >/dev/null; assert_eq "$(fm mod-b next_due)" "$(day +2)"; assert_eq "$(fm mod-b status)" "learning"
./new.sh MOD c A "x" known >/dev/null; assert_eq "$(fm mod-c next_due)" "$(day +7)"
./new.sh MOD d A "x" 30    >/dev/null; assert_eq "$(fm mod-d next_due)" "$(day +30)"

reset
case_ "a module with spaces and capitals becomes a clean filename"
./new.sh "Intro Python" mutable-default C "x" >/dev/null
[ -f topics/intro-python-mutable-default.md ] && ok "slugged" || bad "expected topics/intro-python-mutable-default.md"

reset
case_ "the printed path is usable verbatim by grade.py"
f="$(./new.sh MOD chain A "x" | awk '{print $1}')"
./grade.py "$f" pass "n" >/dev/null; assert_exit $? 0
assert_eq "$(fm mod-chain clean_passes)" "1"

echo "== end to end =="
reset
case_ "create, pass, and see it move out of the backlog into the schedule"
./new.sh MOD lifecycle A "x" learn >/dev/null
assert_has "$(./due.sh)" "TO LEARN / RELEARN (no date, your choice): 1"
./grade.py topics/mod-lifecycle.md pass "n" >/dev/null
out="$(./due.sh all)"
assert_has "$out" "SCHEDULED: 1"
assert_has "$out" "TO LEARN / RELEARN (no date, your choice): 0"

case_ "an easy topic reaches retired and leaves the daily list"
for _ in 1 2 3 4 5 6; do ./grade.py topics/mod-lifecycle.md pass "n" >/dev/null; done
assert_eq "$(fm mod-lifecycle status)" "retired"
assert_not "$(./due.sh)" "lifecycle"

echo
if [ "$FAILED" -eq 0 ]; then
  echo "all $PASSED assertions passed"
else
  echo "$FAILED failed, $PASSED passed"
fi
exit $((FAILED > 0))
