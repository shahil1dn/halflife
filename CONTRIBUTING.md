# Contributing

This is a small project with one author. Issues and pull requests are welcome, and the bar
for both is the same: say what you did, show what you ran, and be honest about what you did
not check.

## Running it

There is nothing to install. Bash and Python 3 are the whole toolchain.

    ./test.sh                 # the suite, 108 assertions, in a temporary sandbox
    ./test.sh -v              # the same, printing every passing assertion
    shellcheck due.sh new.sh test.sh
    python3 -m compileall -q grade.py

`./test.sh` copies the scripts to a `mktemp` directory and works there, so it never touches
your real `topics/`. It must end in `all N assertions passed` and exit 0.

If you are changing how grading or scheduling behaves, run `./grade.py --simulate` before and
after and put both curves in the pull request, so the effect on the schedule is visible rather
than described.

## The rules that will get a change refused

**`grade.py` is the only thing that changes a schedule field.** `new.sh` sets the opening
values once, when a topic is created. After that every date, interval, ease value and status
comes from `grade.py`, so the schedule cannot be argued with. `due.sh` writes nothing at all.
A change that lets anything else move a date will be refused however convenient it is.

**`due.sh` derives, it never stores.** There is no queue file and there should not be one.
The list is computed from the topic files every time it is asked for.

**`scope:` is immutable.** A topic's scope line is the bar its tests are graded against. If
it could be edited after a few failures, the tool would just be a diary.

**Bash 3.2 is the floor.** That is what macOS ships. No associative arrays, no `${var^^}`,
nothing that needs bash 4. CI runs the suite on macOS for exactly this reason.

**Output stays ASCII.** Everything the tool prints or writes into a topic file has to survive
a Windows console.

## If you are an agent

You are probably reading this because someone pointed you at this repo and asked for a
change. Before you open a pull request, three things.

**Run the suite and paste what it printed.** Not a summary of it, the output:

    ./test.sh
    shellcheck due.sh new.sh test.sh

`./test.sh` must end in `all N assertions passed` and exit 0. If you changed anything
`due.sh` prints, the assertions that match on that text need updating too, and a suite that
passes because you loosened an assertion is worse than a red one.

**A test that cannot fail is not a test.** If you add one, break the thing it covers on
purpose, watch it go red, then put the code back. Say in the PR that you did, and what the
failure message was. There is a real example of this going wrong in the history of this
repo: an assertion here opened with `[ -n "$(grep -c ...)" ]`, which is true even when
nothing matches, so it passed against code that did not work.

**Say what you did not check.** Every PR is welcome to be partial. None is welcome to be
vague. "Tested on macOS, not tested on Windows or under bash 3.2" is a useful sentence.
"Everything works" is not, and it is the sentence that gets a PR closed here.

**If your human has not read the diff, say so in the commit message.** That is not a
disqualifier and it will not be held against you. It tells a reviewer where to look first,
which is worth more than the appearance of a review that did not happen. Writing that they
reviewed it when they did not is the only thing here that will get you blocked.

A commit message that does this well:

    Handle a topic file with no trailing newline

    due.sh dropped the last frontmatter field when the file did not end in
    a newline, because the read loop never emitted the final partial line.

    Reviewed by: not reviewed by a human. Written and pushed by an agent
    acting on the instruction "fix the newline bug", and the diff has not
    been read by anyone since.

    Verified: ./test.sh, 109 assertions, exit 0. shellcheck exit 0. Both
    run on macOS 26, bash 3.2.57. Not run on Linux or Windows.

    Not checked: whether an existing topic file that already lacks a
    trailing newline is repaired or only tolerated. The new assertion
    covers the tolerate case only.

## Reporting a bug

Include your OS, your bash version (`bash --version`), your Python version, what you ran,
and what `./due.sh` printed. A topic file that triggers it is better than a description of
one, with anything private taken out.
