# Study tracker

A spaced-repetition tracker where **an AI agent is the examiner**. There is no app, no account
and no UI — it is a folder of text files plus two small scripts.

You tell your agent to test you. It checks what is due, tests you closed-book, judges the answer
against a fixed bar you wrote in advance, and records the result. Pass and the topic comes back
later. Fail and it comes back tomorrow. **Nothing counts as known until you pass a test on it** —
how confident you feel never moves the schedule, because confidence does not predict what you
will actually remember.

## Getting started

1. Download this folder.
2. Point a coding agent at it — Claude Code, Codex, Cursor, Gemini CLI, anything that can read
   files and run shell commands.
3. Say: **"Read AGENTS.md and set me up."**

The agent will explain how it works, then walk you through setup — your course, your modules,
what mark you count as a pass, how long a session should be, and any exam dates. It writes those
answers into `SETUP.md`, which is permanent from then on and read at the start of every session.
Say "rerun setup" any time to change them.

Then it writes your first topics.
For each one it asks whether you already know it, learned it recently, or have never learned it —
that decides whether the first test lands in a week, in two days, or has no date at all and just
waits in the backlog. Saying you know something never counts as passing it; it only picks when
you get asked.

After that, "test me" is the whole daily interface.

Needs `bash` and `python3`. Nothing to install.

## What is in here

| | |
|---|---|
| `AGENTS.md` | the agent's instructions — all the rules live here |
| `SETUP.md` | your profile. Ships as a questionnaire; the agent fills it in on first run |
| `CLAUDE.md` | a pointer to `AGENTS.md`, for agents that look for that filename |
| `topics/` | one file per thing you are learning. This is the database |
| `materials/` | optional: drop your slides, PDFs and notes here, no sorting needed |
| `due.sh` | prints what is due today |
| `grade.py` | records a result and computes the next review date |
| `new.sh` | creates a topic |

You can run the scripts yourself, but you do not need to. The agent drives them.

## Why it works this way

- **The schedule is arithmetic, not a judgement call.** `grade.py` owns every date. The agent's
  only input is one word: pass, partial, or fail. It cannot be talked into going easy on you.
- **Every topic has an immutable `scope:` line** — one sentence naming exactly what counts as
  knowing it, written before the first test and never edited afterwards. That is the bar.
- **Topics leave.** Pass something enough times and it goes dormant, then retires. There is no
  review queue that grows forever.
- **A circuit breaker.** Fail the same topic twice and the agent is told to teach instead of
  test. Fail it four times and it is told your topic is too big — rewrite it smaller.
- **It is all plain text.** Read it, edit it, put it in git, walk away with it.

## Customising

Review intervals, retirement thresholds, how patient the circuit breaker is, and how you get
taught are all adjustable — ask your agent, or see the customising section in `AGENTS.md`.

## Licence

MIT.
