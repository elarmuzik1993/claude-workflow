---
description: Open a session — load project context from the vault before touching code.
---

# Kick off the session

Run this when the user says **"kick off"**, "start the session", or `/kickoff`.

The mirror of `/finalise`. Finalising is only worth the effort if the next session reads what it
wrote — this is the read side.

**Read only. Do not edit, plan, or write code during kickoff.** End by stating where things stand
and asking what to work on.

---

## Step 1 — Locate the project

In a repo, read `AGENTS.md` for its `Obsidian: [[...]]` pointer. Otherwise match the repo name
against `03 Projects/`. Ask if ambiguous.

## Step 2 — Load context, in this order

1. `03 Projects/Projects HUB.md` — the entry for this project: status and next moves.
2. `03 Projects/<P>/<P>.md` — the project note.
3. `03 Projects/<P>/Roadmap.md` — what's in flight.
4. **Where the work stands** — one source, depending on the repo:
   - Repo-kit repo (has `.agents/STATE.md`): **STATE.md is the live Now/Next**; `AGENTS.md`
     already imports it. Cloud sessions update it and never reach the vault, so it is always
     at least as current as any session note. Read the most recent session note for history only.
   - Any other repo: the **most recent** `07 Sessions/YYYY-MM-DD — <P>.md`, especially its
     "What's next" / "State".
5. The repo's `AGENTS.md`.

## Step 3 — Check docs against reality

Compare what the docs claim to `git log --oneline -10`, `git status`, and the current branch.

Where they disagree, **say so explicitly** — that gap is the most valuable thing kickoff produces.
The docs describe the last *finalised* state; anything after that is unrecorded work.

## Step 4 — Report

Keep it short:

- **Where things stand:** branch, working tree, last commit.
- **What's next** — from STATE.md in a repo-kit repo, otherwise from the session note.
- **Gaps:** anything the docs claim that the repo contradicts, or work in the repo the docs missed.
- **Then ask** what to work on. Don't start.
