# Security

## What this tool can reach

It runs on your machine and stays there. There is no server, no account, no telemetry, no
network call, and no dependency to install. Your topic files, your grades and your `SETUP.md`
never leave the folder they are in.

## The part worth thinking about

The real risk here is not the scripts. It is that using this tool means pointing a coding
agent with shell access at a directory and letting it run commands. That is a decision about
the agent you use and what you have allowed it to do, not something these scripts can control.

Two habits worth keeping:

- Read `AGENTS.md` yourself before letting an agent act on it. It is the file the agent obeys.
- Do not put anything in `topics/` or `materials/` that you would not want an agent to read.

## Reporting something

Email ldnshahil@gmail.com with what you found and how to reproduce it. Expect a reply within
about a week. There is no bounty. If it is serious, please give me a chance to fix it before
posting it publicly.
