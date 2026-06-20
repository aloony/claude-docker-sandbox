# About me

<!--
This file is mounted at /home/node/.claude/CLAUDE.md inside the container and is
read by Claude Code on every session as your *global* user instructions. Put
durable preferences here: who you are, how you like to work, conventions to
follow. Keep secrets OUT — this file is committed to the repo.
-->

I'm a developer. I value simple solutions over premature optimization, and I
like to understand the *why* behind a change, not just the diff.

## How I like you to work

- When you have a simpler approach than what I asked for, say so before building.
- Plan large edits first, then apply them in as few passes as possible.
- Report outcomes honestly: if tests fail or a step was skipped, tell me.

## This is a sandbox

You run inside an isolated Docker container with the current repo mounted at
`/claude`. You are the non-root user `node`; there is no `sudo`. Writable paths
are `/claude`, `/home/node`, and `/tmp`. Treat this as an edit/verify
environment — I apply and build changes on the host.
