# halflife

Spaced-repetition study tracking where your coding agent runs the test and a script owns the schedule.

It is a folder of markdown files and three small scripts. There is no app, no account, no UI and
nothing to install. You point a terminal coding agent at the folder — Claude Code or similar — and
it tests you, judges the answer against a bar you wrote in advance, and records the result. Passing
pushes a topic further away, failing drags it back.

The part that makes it work: **nothing counts as known until you pass a test on it.** How confident
you feel never moves the schedule, because confidence does not predict what you will remember.

## Quickstart

```
git clone https://github.com/YOUR-USERNAME/halflife.git
cd halflife
```

Open your coding agent in that folder and paste this:

```
read AGENTS.md and set me up
```

The agent explains how the tool works, then asks about your course, your subjects, what mark counts
as a pass, how long a session should be, and any exam dates. It writes those answers into
`SETUP.md` and reads them at the start of every session afterwards.

Then it writes your first topics. For each one it asks whether you already know it, learned it
recently, or have never learned it. That decides whether the first test is a week away, two days
away, or has no date at all and waits in the backlog.

`SETUP.md` ships as a questionnaire and is rewritten in place during setup. To get the blank one
back, run `git checkout SETUP.md`.

## A day of use

Say `test me`. The agent runs `due.sh`, which reads the topic files and prints what is due:

```
=== DUE TODAY (2026-09-01) — 1 ===
MATH101      long-division                    [A] learning p:1 f:0  topics/math101-long-division.md

=== TO LEARN / RELEARN (no date — your choice) — 1 ===
compilers    nfa-nondeterminism               [B] queued p:0 f:0  topics/compilers-nfa-nondeterminism.md
```

It then tests you on the due topic, closed book, against that topic's `scope:` line — one sentence
written when the topic was created, naming exactly what counts as knowing it. You answer in the
chat. It grades pass, partial or fail, and records it:

```
topics/math101-long-division.md
  pass: ease 2.15->2.3  interval 15d->34d  passes 1->2  consec_fails 0->0  status->learning  next_due 2026-10-05
```

That topic was passed once before, so the gap widens from 15 days to 34. A partial would have halved
it; a fail would have sent it back to tomorrow. Hence the name: everything you know has a half-life,
and the point of the tool is to keep extending it.

If a topic has never been passed, or you have failed it twice, the agent teaches instead of testing:
worked example, then a shuffled-lines version, then fill-in-the-blanks, then a fresh problem.

## How the schedule works

The agent's only input is one word. Every date after that is computed by `grade.py`, so the schedule
cannot be talked into going easy on you.

| Grade | Effect |
|---|---|
| pass | first pass 3 days, then 10, then the interval multiplies by an ease factor, capped at a year |
| partial | interval halves |
| fail | back to 1 day, or back to the undated backlog if it drops to zero passes |

A topic moves through four states, and the interval decides which:

```
  backlog  ──pass──>  learning  ──pass──>  dormant  ──pass──>  retired
 (no date)            (< 90d)              (90-364d)           (365d+)
     ^                    │                    │                   │
     └────────────────────┴────────────────────┴───────────────────┘
                    any fail returns it to 1 day
```

Topics leave. There is no review queue that grows forever.

Two circuit breakers are printed before a session starts, so they cannot be argued away mid-session.
Fail the same topic twice and the agent is told to teach rather than test. Fail it four times and it
is told the topic is too big and must be rewritten smaller.

## What is in the folder

```
AGENTS.md      the agent's operating rules. The only place the rules live
SETUP.md       your profile: subjects, pass mark, session size, key dates
topics/        one markdown file per thing you are learning. This is the database
materials/     optional: your own slides, PDFs and notes. No sorting needed
due.sh         prints what is due today
grade.py       records a result and computes the next review date
new.sh         creates a topic
```

## Customising it

Ask the agent. It knows what is adjustable and where each setting lives, so you can say things in
plain English and it will make the change:

```
make the reviews come back sooner, I am forgetting things between them
test me on fewer topics per session
be harsher, I am getting passes I do not deserve
stop retiring things, I want everything to come back eventually
```

Review intervals, how quickly topics retire, how many fails before the agent switches from testing
to teaching, how you get taught, and your pass mark are all settings. After changing anything that
affects the schedule, the agent shows you the before and after curves so you can see what you
actually changed.

One part is not a setting. Nothing counts as known without a passed test, and the agent will say so
if you ask it to take your word instead. Remove that and this is a to-do list with dates on it.

## Requirements

Bash and Python 3, both already present on macOS and Linux.

Plus a terminal coding agent — Claude Code or one of its equivalents. Built with Claude Code; the
instructions live in `AGENTS.md`, the filename this class of tool reads by convention, so anything
that follows it and can run shell commands should work.

## Limits

- The quality of the testing depends on the agent you point at it.
- No sync, no mobile app, no notifications. It runs when you open it.
- Topic files are plain markdown you can edit or break by hand. Keep them in git.
- The interval numbers are a reasonable bet, not a proven optimum. No research gives a schedule for
  indefinite retention. They err long, because a gap that is too long is cheaper than one that is
  too short.

## Contributing

Issues and pull requests are welcome. If you are changing how grading or scheduling behaves, run
`./grade.py --simulate` and include the before and after curves.

## License

MIT. See [LICENSE](LICENSE).
