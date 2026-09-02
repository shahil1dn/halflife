---
configured: false
# Everything below is set once, on first run, by answering the agent's questions.
# The agent rewrites this file with the answers and flips `configured` to true.
# To change any of it later, say "rerun setup" — the agent edits the answers in place.

course:            # e.g. BSc Computer Science, Year 2
institution:       # optional. Helps the agent read your material in the right conventions
goal:              # e.g. a First, 70%+, just pass, understand it properly
pass_threshold:    # 50 | 70 | 80 | 100 — the mark that counts as a pass on SCORED work
partial_band: 15   # a score this many points below the threshold counts as partial, not fail
session_size:      # topics per sitting, e.g. 5 — or `ask` to be asked each session
modules: []        # the labels used as `module:` on every topic
key_dates: []      # exams and deadlines that matter, as "YYYY-MM-DD — what it is"
---

# Setup

**Not yet configured.** On first run the agent asks the questions below, then rewrites this file
with your answers. After that this is your profile: **data only, no instructions**, read at the
start of every session.

## The questions

> **Agent: delete this entire section once it is answered.** It is scaffolding for a run that has
> happened. Leaving it makes the next session read a questionnaire it must first work out is
> stale. The rule for how `pass_threshold` converts a score into a grade lives in `AGENTS.md`,
> not here.

**1. What are you studying?** Course or programme name, and the institution if it matters. This is
context only — it tells the agent whose conventions and notation to use when it reads your
material.

**2. What are your modules or subjects?** Give a short label for each. These become the `module:`
field on every topic, the prefix on every topic filename, and the way material in `materials/` is
matched to what you are being tested on. Short and stable beats descriptive: `MATH101`, `spanish`,
`compilers`.

**3. What are you actually going for?** A first, a bare pass, or "I want to genuinely understand
this". This changes how hard the agent pushes on a borderline answer, not the arithmetic.

**4. What mark counts as a pass for you?** 50, 70, 80, 100 — your call, and it should follow from
your answer to question 3. This is the threshold applied to **scored** work only: past papers,
quizzes, flashcard decks, anything that comes back as a mark out of something.

**5. How many topics do you want in one sitting?** A realistic number for a normal day. The agent
uses it to decide how much of a long due list to work through before stopping. Answer `ask` instead
of a number if it varies, and the agent will ask how much time you have at the start of each
session.

**6. Any dates that matter?** Exams, coursework deadlines, a resit. Say so if there are none.
