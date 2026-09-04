## What this changes

<!-- One or two sentences. What was wrong, and what is different now. -->

## What you ran

<!-- Paste the output, not a summary of it. -->

```
$ ./test.sh

$ shellcheck due.sh new.sh test.sh
```

- [ ] `./test.sh` ends in `all N assertions passed` and exits 0
- [ ] `shellcheck due.sh new.sh test.sh` is clean
- [ ] If I added a test, I broke the thing it covers on purpose and watched it go red
- [ ] A human has read this diff

<!-- Leave the last box unticked if nobody has read it. That is allowed and useful.
     Ticking it when it is not true is the one thing that will get a PR closed here. -->

## What you did not check

<!-- Which platforms, which cases. "Tested on macOS only" is a good answer.
     "Everything works" is not. -->
