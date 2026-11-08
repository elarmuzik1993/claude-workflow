---
description: Close out the session — verify, sync vault + repo docs, then diff and commit. Commits and pushes the vault; a code repo goes out as the hand-off sends it (STATE.md-only to main, work as a PR), the session's mistakes are noted in the vault (never in a repo), the open PRs are merged when you ask, and merged branches are deleted.
---

# Finalise the session

Run this when the user says **"finalise the session"**, "finalize the session", or `/finalise`.

Goal: leave the written record matching reality, so the next session (on any machine, in any
tool) can pick up from the docs alone.

**Push code repos and open PRs only as the hand-off does** (`/workflow:handoff` steps 6–7): a
hand-off that changes only `.agents/STATE.md` goes to `main` from any branch; other work is
pushed on its branch with its PR opened or updated, and nothing is left unpushed. **Merging
(Step 8) happens only when you ask for it. Deleting merged branches (Step 9) is the last step.**

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

### Mistakes and lessons

Every session note gets a **Mistakes and lessons** section, from evidence only: the transcript's
failed commands, things undone or redone, corrections from the user, rules that were broken and
caught, and checks that failed. One line each: *what went wrong → why → what to do instead*.
No blame, no guesses; if the session had none, write "none" rather than inventing some.

**Mistakes stay in the vault and in the project they happened in.** File each one in the note of
the project it belongs to (a session that touched two repos writes two notes, each with its own
mistakes). Never write a mistake into a repo file — `AGENTS.md`, `STATE.md` or a README — and
never into another project's note: a lesson from one repo is noise in the next. This step runs
no `/learn`, so a finalise changes no rule on its own.

If one mistake is likely to recur and costly to repeat, end the note with a single line
*Candidate rule: …*, and tell the user in the report. Whether it becomes a rule is theirs to
decide: they run `/learn` in that repo themselves.

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
6. **Push each code repo as `/workflow:handoff` step 6 says:** STATE.md-only to `main`, work on
   its branch with its PR opened or updated. Then run its step 7, so no commit, stash or branch
   stays only on this machine. Nothing else goes out.
7. Report, explicitly two lists:
   - **Updated:** every file touched.
   - **Skipped:** what you did not update *and why* ("Roadmap unchanged — no scope movement").

A finalise that quietly does nothing is worse than one that says "nothing needed updating."

## Step 8 — Merge the open PRs (only on request)

Last, after everything is pushed and reported. Merging is outward-facing and hard to undo, so
it never happens on its own, and a `/finalise` that says nothing about merging does not merge.

1. **List what could merge:** the PR of every branch Step 6 pushed or updated (the connector's
   `list_pull_requests` in the cloud, `gh pr list --state open --author @me` locally). For each,
   show number, title, draft or ready, CI state and whether it merges cleanly.
2. **Ask once** which to merge, unless the request already named them (`/finalise merge`
   means every PR that passes the gate below; `/finalise merge #12` only that one). No answer,
   or "no", ends the step: the PRs stay open and the report says so.
3. **Gate, per PR.** Merge only a PR that is ready (not draft), has green required checks, has
   no conflicts and no unresolved "changes requested". A PR that fails the gate is not merged
   and not forced: say which check blocks it. Never use admin override, never skip or disable
   a check, never merge a PR you did not push this session.
4. **Merge one at a time,** oldest first, with the repo's usual method (a merge commit unless
   `git log` shows squash merges). The message carries no AI attribution. Every PR rewrites
   `.agents/STATE.md`, so after each merge re-check the next: if it now conflicts, rebase on
   `main` as `/workflow:handoff` step 3 says, push, and let CI go green before merging it.
5. **Afterwards:** `git fetch origin` and fast-forward local `main` (`git switch main &&
   git pull --ff-only`); the vault is not touched again. Do not write merge or PR status into
   `.agents/STATE.md`; git has it. Branch cleanup is Step 9.
6. **Report** each PR as *merged* (with the merge commit), *left open* (with the blocking
   reason) or *not requested*.

## Step 9 — Delete merged branches (always, last)

Runs on every finalise, whether or not Step 8 merged anything: branches merged by hand or in
earlier sessions pile up otherwise. You asking for `/finalise` is the request to delete them.

1. `git fetch --prune origin`, and `git switch main` first: the branch you stand on is never deleted.
2. **Find them:** local branches that `git branch --merged origin/main` lists, plus remote ones
   from `git branch -r --merged origin/main`. A branch squash-merged or rebased does not show
   there, so also take any branch whose PR is *merged* and whose tip is the commit the PR merged
   (the connector's `list_pull_requests`, or `gh pr list --state merged`).
3. **Never delete:** `main`, the repo's default branch, a branch with an open PR, a branch with
   commits that are in no merged PR, or anything in doubt. Say which ones were skipped and why.
4. **Delete:** local with `git branch -d` (git refuses an unmerged one; only for a squash-merged
   branch whose PR you confirmed in step 2 use `-D`), remote with `git push origin --delete <branch>`.
   If the remote refuses, say so and move on; the local deletion still stands.
5. **Report** the branches deleted (local, remote) and the ones kept with the reason.
