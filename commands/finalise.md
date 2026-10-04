---
description: Close out the session — verify, sync vault + repo docs, then diff and commit. Commits and pushes the vault; pushes a code repo only for a STATE.md-only hand-off on main.
---

# Finalise the session

Run this when the user says **"finalise the session"**, "finalize the session", or `/finalise`.

Goal: leave the written record matching reality, so the next session (on any machine, in any
tool) can pick up from the docs alone.

**Never open a PR, and push a code repo only for the hand-off's own case:** a commit on `main`
that changes only `.agents/STATE.md` (`/workflow:handoff` step 6). Otherwise commit only.

> ℹ️ **The vault is now yours to commit — nothing else will.** The global post-commit hook
> (`core.hooksPath` → `~/.git_hooks/log-commit.ps1`, `post-commit` on Linux) appends one line to
> today's `02 Daily/` note and stops. It no longer runs `git add`, `commit`, `pull` or `push` in
> the vault.
>
> So committing a code repo is side-effect-free — no vault status check, no warning, no
> ordering dance. In exchange, **the vault only ever gets committed here**. If you skip the
> vault commit in Step 7, the session's notes stay uncommitted on one machine.
>
> `check-rule-drift.sh` reports `VAULT` at session start once the vault has been dirty for more
> than 2 days, which is the net under this. It is not a substitute for finishing Step 7.

---

## Step 0 — Config drift check (always, cheap)

Run the same check the `SessionStart` hook uses — don't reimplement it here, a second copy
drifts from the first:

```bash
bash ~/dotfiles/scripts/check-rule-drift.sh    # silent = clean
```

It covers rule files, commands, the git hook, `settings.json` keys a restore would
destroy, whether dotfiles is behind upstream, whether the vault has been left
uncommitted too long, and dotfiles changes the vault hasn't recorded (`UNRECORDED`).

Report the result. **Do not silently auto-fix**: if there is drift, say so and give the
remediation the script prints. Config flows dotfiles → local, never the reverse.

## Step 1 — Identify the project

- In a repo: read `AGENTS.md` for its `Obsidian: [[...]]` pointer → that's the vault project folder.
- No pointer: match the repo name against `03 Projects/` folders. Ask if ambiguous — never guess.
- Not in a repo: treat it as a **system/infra session**; the target docs are
  `04 Reference/System Setup/` and `SYSTEM_VERSION.md`.

## Step 2 — Hand off the repo (repo-kit repos only)

In a repo with `.agents/STATE.md`, run `/workflow:handoff` steps 1–4: verify, pick the branch,
rewrite STATE.md, update the repo docs. If the skill isn't loaded, follow those steps in
`~/dotfiles/plugins/workflow/skills/handoff/SKILL.md`. Stop before its commit: the diff is shown
and committed in Step 7, together with the vault. Don't restate the steps here: a second copy
drifts from the first, which is how this command lost the verify step.

In a repo without the kit, skip this step.

## Step 3 — Summarise from evidence, not memory

Build the summary from what actually happened: the session transcript plus `git log`, `git diff`,
and real command output.

**Include work from other sessions.** Cloud sessions change dotfiles but never reach the vault,
so "this session changed nothing" is not the test. List what the vault hasn't recorded:

```bash
bash ~/dotfiles/scripts/check-vault-record.sh    # silent = nothing to record
```

Each line is a commit on dotfiles `main` since `SYSTEM_VERSION.md`'s `dotfiles-recorded:` line;
read the merged PRs behind them. Any output, or a missing line, means Step 6 runs.

**Every factual claim must be verified or marked unverified.** Test counts come from a test run in
this session (Step 2's verify, in a repo-kit repo), branch state from real `git status`. If you
did not run it, write `not verified this session` — never a remembered or plausible-looking number.

## Step 4 — Write the session note

Create `07 Sessions/YYYY-MM-DD — <Project>.md` from `05 Templates/Claude Session.md`.
If a note for today + this project already exists, **append a new section** rather than overwrite it.

In a repo-kit repo (it has `.agents/STATE.md`), the session note is **history**: what happened
and why. Its *What's next* is one line pointing at the repo's `.agents/STATE.md` → *Next*, never
a copy of the list. STATE.md is the one live "next" for the repo, and cloud sessions update it
without ever reaching the vault, so a copy here would go stale.

## Step 5 — Sync the docs

Update only what actually changed — skip the rest and say you skipped it.

| Doc | Update when |
|---|---|
| `03 Projects/<P>/<P>.md` | status changed; or, in a repo without the kit, there's a new next-step |
| `03 Projects/<P>/Roadmap.md` | something shipped, slipped, or got added (the longer horizon; the immediate steps are STATE.md's) |
| `03 Projects/<P>/*Runbook.md` | a documented procedure's behaviour changed |
| `03 Projects/Projects HUB.md` | status symbol and/or Last Push date |
| repo `AGENTS.md` | project rules/conventions/stack changed (a repo-kit repo did this in Step 2) |
| repo `README` | user-facing usage changed (a repo-kit repo did this in Step 2) |

**Inbox:** move any standalone note in `01 Inbox/` into its proper folder and link it from that
folder's index; ask before deleting one. `Bugs.md`, `Ideas.md` and `Links.md` are running lists
and stay.

## Step 6 — System layer (if this session touched config or rules, or Step 3 found unrecorded changes)

Order matters — **source first, then deploy**:

1. Edit `~/dotfiles/configs/...` (the source of truth).
2. Redeploy from source: `bash ~/dotfiles/scripts/deploy.sh` (session start does it by itself
   once the change is on `main`). Don't restate the target list here; it lives in `deploy.sh`
   and `check-rule-drift.sh`, and a count written into prose goes stale.
3. Bump `04 Reference/System Setup/SYSTEM_VERSION.md` (one entry per meaningful system change;
   cosmetic edits don't warrant a bump), covering Step 3's unrecorded changes too. Then set its
   `dotfiles-recorded:` line (add it to the frontmatter if missing) to the `main` commit you
   recorded up to: `git -C ~/dotfiles rev-parse --short main@{u}`. Rerun the Step 3 script; it
   must be silent.
4. Update the affected `04 Reference/System Setup/` notes.

## Step 7 — Check, diff, commit, report

1. **Check the changed vault notes** against README → Note Modularity. Silent means clean; fix
   every error before committing, and pass warnings on in the report.
   ```bash
   python ~/dotfiles/scripts/check-vault-modularity.py    # python3 on Linux
   ```
2. `git diff` in each affected repo — **show it to the user before committing**.
3. **Commit the vault.** Nothing else does it any more. Use a real message describing the
   session's work, not a generic "update notes".
4. Commit the code repos separately, with real messages describing what changed. Order no
   longer matters — the hook has no vault side effects — but keeping the vault first still
   reads better in the log.
5. **Push the vault** (`git push origin main`). The hook used to do this; it does not now, so
   an unpushed vault is the one regression this design can produce. Push it.
6. **Stop. Do not push any code repo**, except a STATE.md-only hand-off on `main`, which goes
   out as `/workflow:handoff` step 6 says. Anything else: commit only, unless the user asks.
7. Final report, explicitly two lists:
   - **Updated:** every file touched.
   - **Skipped:** what you did not update *and why* ("Roadmap unchanged — no scope movement").

A finalise that quietly does nothing is worse than one that says "nothing needed updating."
