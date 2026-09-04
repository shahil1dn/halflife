#!/usr/bin/env python3
"""grade.py — deterministic scheduler. The ONLY thing that may change a topic's schedule.

The agent judges pass/partial/fail against the topic's `scope:` line. Everything after
that — ease, interval, status, next_due — is computed here, so it cannot be softened
in conversation.

  ./grade.py <file> <pass|partial|fail> "<note>"
  ./grade.py <file> <grade> --dry-run
  ./grade.py --simulate
"""
import sys, re, datetime

EASE_START, EASE_MIN, EASE_MAX = 2.0, 1.3, 2.5
D_PASS, D_PARTIAL, D_FAIL = +0.15, -0.15, -0.30
FIRST, SECOND = 3, 10          # fixed anchors; ease takes over from pass 3
INTERVAL_MAX = 365
DORMANT_AT = 90                # interval >= this -> dormant
RETIRE_AT = 365                # pass at >= this -> retired

def step(ease, interval, passes, grade, consec_fails=0):
    """Pure. (ease, interval, clean_passes, status) for the next review.
    consec_fails is the count BEFORE this grade."""
    if grade == "pass":
        ease = min(EASE_MAX, ease + D_PASS)
        passes += 1
        # FIRST/SECOND are FLOORS, not resets. A topic seeded at an interval (the user
        # already knew it when it was created) must keep climbing from there — otherwise
        # passing a 7d topic would drag it back to 3d.
        if passes == 1:   interval = max(FIRST, round(interval * ease))
        elif passes == 2: interval = max(SECOND, round(interval * ease))
        else:             interval = min(INTERVAL_MAX, round(interval * ease))
        interval = min(INTERVAL_MAX, interval)
    elif grade == "partial":
        ease = max(EASE_MIN, ease + D_PARTIAL)
        interval = max(1, round(interval * 0.5))     # halve, don't reset
    else:  # fail — council ruling: one stumble costs a step, a streak costs everything
        ease = max(EASE_MIN, ease + D_FAIL)
        passes = max(0, passes - 1) if consec_fails == 0 else 0
        # never passed -> not "due", just unlearned. interval 0 == unscheduled backlog
        interval = 0 if passes == 0 else 1
    if grade == "pass" and interval >= RETIRE_AT: status = "retired"
    elif grade == "pass" and interval >= DORMANT_AT: status = "dormant"
    else: status = "learning"
    return round(ease, 2), interval, passes, status

def simulate():
    rows = [("EASY  (always pass)", ["pass"]*9),
            ("MIXED (pass,partial alternating)", ["pass","pass","pass","partial","pass","partial","pass","pass","pass"]),
            ("HARD  (pass then keeps failing)", ["pass","pass","fail","fail","pass","fail","pass","pass","pass"])]
    for label, grades in rows:
        e, i, p, st = EASE_START, 0, 0, "queued"
        cf_sim = cf_prev = 0
        cum, out = 0, []
        for g in grades:
            cf_sim = cf_sim + 1 if g == "fail" else 0
            e, i, p, st = step(e, i, p, g, cf_prev)
            cf_prev = cf_sim
            cum += i
            out.append(f"{g[:4]:>4}->{i:>3}d(e{e:.2f},{st[:3]})")
        print(f"{label}\n  " + "  ".join(out) + f"\n  reaches day ~{cum} cumulative, final: {st}\n")

def fm_get(s, k, default=""):
    m = re.search(rf"^{k}:\s*(.*)$", s, re.M)
    return m.group(1).strip() if m else default

def fm_set(s, k, v):
    if re.search(rf"^{k}:", s, re.M):
        return re.sub(rf"^{k}:.*$", f"{k}: {v}", s, count=1, flags=re.M)
    return s.replace("---\n", f"---\n{k}: {v}\n", 1)

def main():
    if "--simulate" in sys.argv: return simulate()
    path, grade = sys.argv[1], sys.argv[2]
    if grade not in ("pass", "partial", "fail"): sys.exit(f"bad grade: {grade}")
    note = sys.argv[3] if len(sys.argv) > 3 and not sys.argv[3].startswith("--") else ""
    dry = "--dry-run" in sys.argv

    # encoding is explicit on both ends: Python defaults to the platform locale, which on
    # Windows is cp1252, and a UTF-8 topic file round-tripped through it comes back corrupted.
    s = open(path, encoding="utf-8").read()
    ease = float(fm_get(s, "ease", EASE_START) or EASE_START)
    interval = int(fm_get(s, "interval", 0) or 0)
    passes = int(fm_get(s, "clean_passes", 0) or 0)
    cf = int(fm_get(s, "consec_fails", 0) or 0)

    ne, ni, np_, nst = step(ease, interval, passes, grade, cf)
    ncf = cf + 1 if grade == "fail" else 0
    today = datetime.date.today()
    # interval 0 means unscheduled: it sits in the backlog until worked, not on a date
    nd = "" if ni == 0 else today + datetime.timedelta(days=ni)

    print(f"{path}\n  {grade}: ease {ease}->{ne}  interval {interval}d->{ni}d  "
          f"passes {passes}->{np_}  consec_fails {cf}->{ncf}  status->{nst}  "
          f"next_due {nd if nd else '(unscheduled — backlog)'}")
    if dry: return

    for k, v in [("ease", ne), ("interval", ni), ("clean_passes", np_),
                 ("consec_fails", ncf), ("status", nst), ("last_result", grade),
                 ("last_checked", today), ("next_due", nd)]:
        s = fm_set(s, k, v)
    tag = {"pass": "PASSED", "partial": "PARTIAL", "fail": "MISSED"}[grade]
    s = s.rstrip() + f"\n- {tag} {today} — {note}\n"
    open(path, "w", encoding="utf-8").write(s)

main()
