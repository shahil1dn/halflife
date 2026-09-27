# halflife

[![CI](https://github.com/shahil1dn/halflife/actions/workflows/ci.yml/badge.svg)](https://github.com/shahil1dn/halflife/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

**A study tool where an AI agent tests you, and a script decides when you see each topic again.**

Most AI study tools let the model decide whether you know something. That is the weak spot: a model
can be talked round, and so can you. halflife splits the job in two:

- **The agent tests.** It quizzes you closed book against a pass bar you wrote in advance, then
  grades the answer pass, partial or fail.
- **A script schedules.** That one word is the agent's only say. A small Python script works out
  every review date from it, so nothing said in the chat can move a date.

Nothing counts as known until you pass a test on it. Feeling confident never changes the schedule,
because confidence is a poor guide to what you will remember.

It is a folder of markdown files and three small scripts. No app, no account, nothing to install.

## Getting started

```
git clone https://github.com/shahil1dn/halflife.git
cd halflife
```

Open a terminal coding agent (Claude Code or similar) in the folder and say:

```
read AGENTS.md and set me up
```

The agent explains how the tool works, then asks about:

- your course and subjects
- the mark that counts as a pass
- how long a session should be
- any exam dates

It saves your answers in `SETUP.md` and reads them at the start of every session.

Next it helps you add your first topics. For each one it asks how well you know it already:

| You say | First test |
|---|---|
| I know it well | in 7 days |
| I learned it recently | in 2 days |
| I have never learned it | no date; it waits in the backlog until you choose to learn it |

`SETUP.md` starts as a blank questionnaire and is filled in during setup. To reset it, run
`git checkout SETUP.md`.

## A normal session

Say `test me`. The agent runs `due.sh`, which lists what is due today:

```
=== DUE TODAY (2026-09-01): 1 ===
MATH101      long-division                    [A] learning p:1 f:0  topics/math101-long-division.md

=== TO LEARN / RELEARN (no date, your choice): 1 ===
compilers    nfa-nondeterminism               [B] queued p:0 f:0  topics/compilers-nfa-nondeterminism.md
```

Every topic has a `scope:` line, written when the topic was created, that says exactly what knowing
it means. The agent tests you against that line with no notes, you answer in the chat, and it
records the grade:

```
topics/math101-long-division.md
  pass: ease 2.15->2.3  interval 15d->34d  passes 1->2  consec_fails 0->0  status->learning  next_due 2026-10-05
```

This topic had been passed once before, so the gap grew from 15 days to 34. A partial would have
halved the gap, and a fail would have brought it back to tomorrow.

That is where the name comes from: everything you know has a half-life, and the tool's job is to keep
making it longer.

If you have never passed a topic, or have just failed it twice, the agent teaches it instead of
testing it. It shows a worked example, then the same solution with its lines shuffled for you to
reorder, then a version with blanks to fill in, then a fresh problem.

## How the schedule works

The agent gives `grade.py` one word. The script does the rest.

| Grade | What happens to the gap before the next test |
|---|---|
| pass | at least 3 days after the first pass and 10 after the second; after that it grows by a multiplier (the "ease"), up to one year |
| partial | halves |
| fail | drops to 1 day, or back to the undated backlog if the topic no longer has any passes |

Each topic moves through four stages as its gap grows:

```
  backlog  ──pass──>  learning  ──pass──>  dormant  ──pass──>  retired
 (no date)            (< 90d)              (90-364d)           (365d+)
     ^                    │                    │                   │
     └────────────────────┴────────────────────┴───────────────────┘
                    any fail returns it to 1 day
```

Topics you know well retire, so the review pile does not grow forever.

Two safety rules are printed before each session starts, so they cannot be argued away halfway
through:

- **Fail a topic twice in a row** and the agent is told to teach it, not test it.
- **Fail it four times in a row** and the agent is told the topic is too big and must be split into
  smaller ones.

## What is in the folder

```
AGENTS.md      the agent's rules. This is the only place they live
SETUP.md       your profile: subjects, pass mark, session length, key dates
topics/        one markdown file per thing you are learning. This is the database
materials/     optional: your own slides, PDFs and notes, in any order
due.sh         lists what is due today
grade.py       records a grade and works out the next review date
new.sh         creates a new topic
```

## Changing how it works

Ask the agent in plain English. It knows which settings exist and where they live:

```
make the reviews come back sooner, I am forgetting things between them
test me on fewer topics per session
be harsher, I am getting passes I do not deserve
stop retiring things, I want everything to come back eventually
```

You can change the review gaps, when topics retire, how many fails it takes before the agent starts
teaching, how it teaches, and your pass mark. After any change to the schedule, the agent shows you
the old and new review curves side by side so you can see what you actually changed.

One rule is not a setting: nothing counts as known without a passed test. If you ask the agent to
take your word for it instead, it will point you back to this rule. Without it, this is just a
to-do list with dates.

## Requirements

- Bash and Python 3. Both come with macOS and Linux. On Windows, use Git Bash (it comes with Git for
  Windows) or WSL.
- A terminal coding agent that can run shell commands. halflife was built with Claude Code. Its
  rules live in `AGENTS.md`, the file most of these agents read by default, so others should work
  too.

The tests run on Ubuntu, macOS and Windows (Git Bash) on every push; the CI badge above links to the
results. The repository forces Unix line endings, because Windows line endings stop the bash scripts
from running at all.

## Limits

- The tests are only as good as the agent giving them.
- No sync, no mobile app, no reminders. It only runs when you open it.
- Topic files are plain markdown, so you can edit them by hand and also break them by hand. Keep
  them in git.
- The review gaps are a sensible guess, not a proven best. No research gives an ideal schedule for
  remembering something forever. The gaps lean long on purpose: a gap that is a bit too long costs
  less than one that is too short.

## Contributing

Issues and pull requests are welcome. [CONTRIBUTING.md](CONTRIBUTING.md) covers what to run before
you open one, the few rules that will get a change turned down, and a section for coding agents,
since many pull requests now come from them.

## License

MIT. See [LICENSE](LICENSE).
