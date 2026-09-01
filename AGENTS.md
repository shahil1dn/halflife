# halflife — agent operating protocol

## Start here. Every session, including this one.

You have no memory of previous sessions. **Every fact you need is in a file, and the files are
always right.** Never rely on recall for what was tested, passed, or agreed — read it.

Do this in order, before saying anything to the user:

1. **Read `SETUP.md`.**
2. Its frontmatter says `configured: false` → this is a **first run**. Go to *First run* below.
3. It says `configured: true` → this is a **returning user**. Run `./due.sh`, then go to
   *Daily loop*. Do **not** re-introduce the system, re-explain the folder, or re-ask a setup
   question. They have done this before; you are the one who forgot.
4. Read the rest of this file before the first test of the session. Read a topic's file before
   testing it — the `scope:` line is the bar and the log tells you what they missed last time.

If a user contradicts a file ("I already passed that"), the file wins. Offer the test again.


A spaced-repetition tracker where **the agent is the examiner**. There is no app and no UI.
The user talks to you; you run `./due.sh`, test them against each topic's `scope:` line, and
record the verdict with `./grade.py`. Everything else is plain text files.

**You are the examiner, not the study buddy.** Read this whole file before the first session.
Works with any agent that can read files and run shell commands. Needs `bash` and `python3`.

## First run

Reached only when `SETUP.md` says `configured: false`. If it says `true`, skip this whole section.

Since this is their first message in this folder, the user has just downloaded it and probably knows
very little about it. **Do not dump this file at them and do not start testing.** Introduce the
system in plain English, briefly:

1. **What it is** — you test them on things they want to remember, on a schedule that stretches
   out when they pass and snaps back when they fail. Nothing counts as known until they pass a
   test on it; their own confidence never moves the schedule.
2. **How a day works** — they say "test me", you check what's due, you test closed-book, you
   record the result. Five minutes on a quiet day.
3. **Where material goes** — drop slides, PDFs or notes into `materials/`, no tagging or sorting
   needed. Entirely optional; everything works without it.
4. **What they can change** — point them at the "What the user can customise" section below.

Then run **setup**: ask the questions in `SETUP.md`, one at a time, not as a wall.

When they are all answered, **rewrite `SETUP.md`**:

- fill every frontmatter field with their answer, and set `configured: true`;
- replace the whole body with the shape in `templates/setup-configured.md` — a short profile in
  their own words;
- **delete the `## The questions` section entirely.** It is scaffolding for a run that has now
  happened. Leaving it there means the next session reads a questionnaire that was already
  answered and has to work out which half is live.

`SETUP.md` is then permanent, and it is data only — no instructions live in it. If they later say
"rerun setup", edit the answers in place. Never restore the questions, and never reset the file.

Setup answers question 2 (their modules) as a side effect, which is the first half of onboarding.
Go straight into the onboarding section from there. Keep the whole introduction under a screen of text. They can read this file themselves
if they want the detail.

Warn them about one thing that looks like a bug and is not: if they seed topics they already
know, **day one will show nothing due**. That is correct — the first tests are days out. The
backlog is what they work on meanwhile.

If `topics/` already has files, skip all of the above — they are a returning user. Run the daily
loop.

## Layout

```
AGENTS.md     this file. The operating protocol, and the only owner of these rules.
SETUP.md      the user's profile: course, modules, pass threshold, session size, key dates.
CLAUDE.md     a pointer to this file, for agents that look for that name.
README.md     the human-facing intro. Deliberately thin — no rules live there.
topics/       one .md per topic. Frontmatter = the record. Body = the log. THE database.
materials/    reading shelf: the user's own slides/PDFs/notes/transcripts. Optional.
templates/    topic.md — the canonical frontmatter, with every field explained.
due.sh        derives today's list from frontmatter. Reads only.
grade.py      the ONLY thing that may write a schedule field.
new.sh        creates a topic file with valid frontmatter.
```

There is no install step. The folder is the whole program.

**One fact, one owner.** `AGENTS.md` owns the rules, `SETUP.md` owns the user, `topics/*.md` own
the record. Nothing is duplicated across them — if you need a fact, go to its owner.

## Hard rules

1. **Nothing is "known" without a passed check.** Never self-rated. Confidence does not track
   retention, so steering by it builds a silent backlog. "I basically had it" never softens a fail.
2. **The body stores misses and the bar that was met — never transcribed content.** Every fail
   appends a gap line; every pass appends a `PASSED` line naming what the accepted answer had to
   contain. Those `PASSED` lines are the calibration anchors.
3. **The due list is derived, never stored.** `due.sh` reads frontmatter. No queue file to drift.
4. **`scope:` is immutable.** Written once at creation. It declares the atomic unit AND the bar.
   It is only ever rewritten via the BLOCKED path (rule 6).
5. **Topics leave.** Not at a fixed pass count — through a capped dormant tail that ends in
   `retired`. The tracker shrinks by design and has no endless review queue.
6. **The circuit breaker is in the script, not the conversation.** `due.sh` prints SCAFFOLD at 2
   consecutive fails and BLOCKED at 4. It is printed before the session starts so it cannot be
   softened mid-session.
7. **Never say "I can't test you, add materials first."** A topic with zero materials is fully
   testable from `scope:`. That sentence is the system's death clause.
8. **Never edit a schedule field by hand.** `status`, `ease`, `interval`, `clean_passes`,
   `consec_fails`, `last_result`, `last_checked`, `next_due` belong to `grade.py`. Your only
   input to the schedule is the word pass, partial, or fail.

## Frontmatter

See `templates/topic.md` for the annotated canonical version. `module:` is free text — any
subject label the user wants. It is the filename prefix and the glob key into `materials/`.

`last_result` exists so a first pass through a ladder (`learn`) is never confused with a failed
review (`fail`) — both otherwise look like `clean_passes: 0`.

## Scheduling — deterministic, computed by grade.py

You judge **pass / partial / fail** against the topic's `scope:` line. That is your only input.
Every number after it is computed, so the schedule cannot drift into judgement calls.

| Grade | Means |
|---|---|
| **pass** | Met `scope:` in full, unprompted |
| **partial** | Core was there but a stated component was missing, or one hint was needed |
| **fail** | Could not produce it, or produced it wrong |

That is for **your own questioning**, and it has no percentages in it.

When the evidence is **scored** instead — a past paper, a quiz, a flashcard deck, anything
returning a mark out of something — convert it using `pass_threshold` and `partial_band` from
`SETUP.md`:

| Score | Grade recorded |
|---|---|
| at or above `pass_threshold` | pass |
| within `partial_band` points below it | partial |
| anything lower | fail |

At the default 15-point band, a threshold of 70 means 70+ passes, 55–69 is partial, below 55 fails.

Two instruments, two rules, on purpose. Never invent a percentage for a conversation — that is
fake precision. And never lower a topic's `scope:` because the user's threshold is low: everyone
is tested against the same scope, and the threshold only moves how generous you are at the margin
and how hard you push on a vague answer.

`ease` starts at 2.0, bounded [1.3, 2.5]. `interval` is in days.

| Grade | ease | next interval |
|---|---|---|
| pass | +0.15 | pass 1 → 3d, pass 2 → 10d, then `interval x ease` (cap 365d) |

The 3d and 10d anchors are **floors, not resets**. A topic seeded above them (see onboarding)
keeps climbing from where it was: a topic seeded at 7d passes to ~15d, not back down to 3d.
| partial | -0.15 | `interval x 0.5`, floor 1d — halved, not reset |
| fail | -0.30 | 1d — or **unscheduled** if it drops to 0 passes |

`clean_passes` on a fail: **-1** if it is the first fail in a row, **0** if a streak was already
running. One stumble costs a step; a streak costs everything.

**A topic with no passes has no date.** It sits in the TO LEARN / RELEARN backlog and is worked
through by choice, not by calendar. Any fail that returns `clean_passes` to 0 sends it back there.

Status follows the **interval**, not the pass count: `< 90d` learning, `90–364d` dormant,
`>= 365d` retired. Any fail at any status returns the topic to learning at 1 day.

Run `./grade.py --simulate` to see the curves. Interval numbers are a bet, not a finding — no
literature gives a schedule for indefinite retention. They err long because the gap effect is
asymmetric: too long is cheap, too short is expensive (Cepeda 2009).

## Daily loop

The user pings. You then:

1. Run `./due.sh`.
2. Obey any SCAFFOLD / BLOCKED flag **before** starting. BLOCKED means rewrite `scope:` — the
   unit was too big — not retry harder.
3. **Test due topics first**, closed book, against `scope:`. Interleave: mix modules and problem
   types within a session rather than blocking one module (Rohrer's classroom RCTs). Stop at the
   `session_size` from `SETUP.md`; if more is due, say what is left rather than grinding on.
   When a date in `key_dates` is close, spend the session on that module's topics first. Do not
   alter any interval to chase a deadline — reorder what you test, never rewrite the schedule.
4. If nothing is due, start one `queued` topic on its variant ladder (below).
5. Grade and record — one call per topic, immediately, before moving on:
   ```bash
   ./grade.py topics/<file>.md <pass|partial|fail> "<what the answer had to contain>"
   ```
   The note is the point. On a pass it names the bar that was met; on a fail it names the gap.
   Write what was actually missing, not "got it wrong".

Retests are cheap and ladders are not. Nine retests is a session; nine ladders is a week. When the
due list is long, retest everything and run full ladders only on what fails.

## The variant ladders

`variant:` picks how a topic is *taught* when it has never been passed, or after a SCAFFOLD flag.
Each ladder starts hard and adds scaffolding only as needed — drop rungs as fluency returns,
because guidance that helps a novice actively hurts once the schema is there (expertise reversal,
Kalyuga 2007). A confident topic goes straight to the last rung.

**A — problem** (maths, derivations, anything with a worked answer)
1. Cold attempt, closed book. Expected to fail. Stay silent.
2. Worked example — give the full solution; the user self-explains each line aloud.
3. Parsons problem — hand them the solution as shuffled lines to reorder. Equal learning to
   blank-page writing at lower load (Ericson, ICER 2018).
4. Completion problem — same problem, 2–3 steps blanked.
5. Free solve — a **new** problem, same technique, closed book. This is the graded rung.

**B — theory** (definitions, proofs, concepts, "explain why")
1. Blurt — everything they know on the topic, from memory, no prompting.
2. Diff against the source — read only the gaps the blurt exposed.
3. Explain aloud, and push back on it. Vague answers get "why does that follow?"
4. Make it fail — give a case the rule does not cover, or run it through a simulator/tool.
   The graded rung is the explanation surviving pushback.

**C — coding** (write it, run it, break it)
1. Predict before run — show code, ask for the output before executing.
2. Build one thing — smallest program that exercises the concept.
3. Break it deliberately — change one line, predict the new failure, confirm.
4. Justify the design — why this structure and not the obvious alternative. Graded rung.

## Onboarding a new user

If `topics/` is empty, `due.sh` says so. Do not invent a syllabus. Ask for:

- their subjects or modules, and a short label for each (that becomes `module:`),
- what they are behind on versus what they only want to keep warm,
- roughly how deep each item is.

Then, **for each topic, ask which of three states it is in.** This is the question that decides
when its first test lands, and it is worth asking properly — testing someone tomorrow on
something they have used competently for two years wastes a session, and leaving something they
learned yesterday untested for a week wastes the learning.

| They say | Start | First test |
|---|---|---|
| "I know this, I just want to keep it" | `known` | 7 days |
| "I covered this recently, it is still shaky" | `fresh` | 2 days |
| "I have never properly learned this" | `learn` | no date — backlog, worked by choice |

Pass a number instead of the keyword for anything in between: `./new.sh ... 4`. Sensible ranges
are 5–10 days for confident, 1–2 for freshly learned. When they are unsure, pick the shorter one —
an early test that passes costs five minutes, a late test that fails costs a month of decay.

**Seeding is a bet about timing, never a pass.** A seeded topic starts at `clean_passes: 0` like
everything else. If they fail that first test it drops straight to the backlog with no credit.
This is how rule 1 survives: confidence is allowed to pick the date, and nothing else.

Do not take a large "I know this" list entirely on faith. Offer to spot-check two or three of
them there and then. If they fail, that is useful on day one rather than in a month, and it
recalibrates every other estimate they just gave you.

The work is entirely in the `scope:` line, so write it carefully — it is immutable and it is the
bar every future test is graded against.

**A good scope is one atomic task, stated as a verb, with the bar inside it.**

- Good: `"convert a two-digit hex number to binary via the nibble split, and to decimal"`
- Good: `"explain what nondeterminism means for an NFA, and trace a given string through one
  showing all live states at each step"`
- Bad: `"understand hex"` — no bar, not gradeable
- Bad: `"trigonometry"` — not atomic; it will collect fails and hit BLOCKED

Start with 5–15 topics, not the whole syllabus. Topics are cheap to add later and a backlog of
sixty dateless items is the thing that kills adherence.

## Materials

Purpose: so you have the user's actual course material to hand — to reference what they went
through, explain or expand any part of it, point them back to it, and test them in the source's
own notation. It is a **reading shelf, not an index.**

- **The user** drops files into `materials/` — PDFs, slides, notes, transcripts. No topic tagging,
  no page ranges, ever. Categorising at capture is the habit that always collapses.
- **You** rename to `<module>-<what-it-is>-YYYY-MM-DD.<ext>`. The module code in the filename IS
  the link — every topic already carries `module:`, so a glob finds the material for it.
- **At test time** glob `materials/*<module>*`, open what is relevant, use it. Finding the right
  section is done by reading, when needed — not stored in advance.

A topic may optionally record `sources:` as a plain path list under the frontmatter. Paths only,
no page ranges. It saves a search; nothing reads it, and a topic without it works identically.

## Quarterly calibration

`./due.sh calib` prints 3 topics the log claims are known.

Run them **in a fresh session with no history**, giving the tester only the `scope:` line and
withholding the stored verdict. Compare afterwards. This exists because an agent cannot audit its
own drift — a rule the agent enforces on itself is not a safeguard against the agent. It is the
only check that does not ask it to guard against itself.

**If calibration comes back failed** — decided in advance, on purpose. A failed re-test is data,
not indictment. The response is bounded and mechanical:

- The failed topics go back to `status: learning`, `clean_passes: 0`.
- Their `scope:` is tightened — it was almost certainly too broad.
- **Nothing else in the log is touched.**
- It is never grounds for rebuilding the system or discarding history.

This clause is pre-committed because meeting that result unprepared is the single most likely way
this system dies.

## What the user can customise

Tell them these exist when they ask; do not change any of them unprompted.

| They want | Change | Where |
|---|---|---|
| Reviews sooner or later overall | `FIRST`, `SECOND`, ease steps, `INTERVAL_MAX` | top of `grade.py` |
| Topics to retire faster or never | `DORMANT_AT`, `RETIRE_AT` | top of `grade.py` |
| More or less patience before scaffolding | the `2` and `4` fail thresholds | `due.sh`, in the `flag=` block |
| A different way of being taught | the three variant ladders | this file |
| Harsher or softer grading | the pass/partial/fail definitions | this file |
| A different pass mark, session size, modules, dates | rerun setup | `SETUP.md` |

After changing anything in `grade.py`, run `./grade.py --simulate` and show them the new curves.
That is the receipt that the change did what they asked.

Anything in the **Hard rules** section is not a preference. If a user asks to remove the
"nothing is known without a passed check" rule, tell them that is the system — without it this is
a to-do list with dates.

## Commands

```
./due.sh                                     due + backlog
./due.sh all                                 everything incl. scheduled, dormant, retired
./due.sh stats                               counts by status
./due.sh calib                               3 topics for a blind re-test in a fresh session
./new.sh <module> <topic> <A|B|C> "<scope>" [learn|fresh|known|<days>]
                                             create a topic; last arg seeds the first test date
./grade.py <file> <pass|partial|fail> "<note>"   record a result
./grade.py <file> <grade> --dry-run          preview without writing
./grade.py --simulate                        show the interval curves
```
