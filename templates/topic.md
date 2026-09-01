---
# module: free text. Any subject/course label you like — MATH101, spanish, guitar.
# It becomes the filename prefix AND the glob key for materials/, so keep it consistent.
module: MODULE
# topic: kebab-case. Unique within the module.
topic: kebab-case-name
# scope: IMMUTABLE. Written once. Declares the atomic unit AND the bar that counts as a pass.
scope: "the exact task that counts as knowing this"
# variant: A = problem (work it), B = theory (explain it), C = coding (build it)
variant: A
status: queued          # queued | learning | dormant | retired
clean_passes: 0
ease: 2.0               # bounded [1.3, 2.5]; grade.py owns this
interval: 0             # days; 0 == unscheduled backlog. May be SEEDED at creation when the
                        # user already knows the topic — that sets when the first test lands,
                        # and never counts as a pass (clean_passes stays 0 until one is earned).
consec_fails: 0
last_result: none       # none | learn | pass | partial | fail
last_checked:           # YYYY-MM-DD
next_due:               # YYYY-MM-DD, or empty when unscheduled
---

# kebab-case-name

## Why it's here
(one line — what made this worth tracking)

## Log
