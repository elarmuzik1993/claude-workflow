---
name: handoff
description: End the session so the next one, on any device, local or cloud, can resume from the repo alone. Use when the user says "hand off", "wrap up", "finish the session" or runs /workflow:handoff.
---

# Hand off

Works the same locally and in cloud sessions: nothing here depends on this machine. (Locally,
`/finalise` runs these steps and then syncs the Obsidian vault.)

The hand-off never needs a PR of its own. It rides in the work's PR, or, when there is no other
work, goes straight to `main`.

1. **Verify.** Run `bash scripts/verify.sh`. If it fails, fix it or record the failure under
   *Known issues*. Never hand off a claim you didn't check.
2. **Pick where it goes.** Decide by what changed, not by the branch you are on: a cloud
   session always starts on a branch of its own, even when it does no work.
   `git fetch origin main`, then list what this branch changed since it left `main`:
   `git diff --name-only origin/main...HEAD` (committed; the same comparison the branch guard
   makes) and `git status --short` (not yet committed). Others' new commits on `main` don't count.
   - *Nothing but `.agents/STATE.md`* (a review, a redeploy recorded, a step done, a plan
     changed): the hand-off goes to `main`, from any branch, locally or in the cloud. It never
     goes on a branch of its own: that would need a PR of its own, and the branch guard refuses
     the push.
   - *Anything else:* the hand-off rides with the work on its `<type>/<work>` branch, so the
     branch's PR carries it. On `main`, move the work to a branch first
     (`git switch -c <type>/<work>`); in repos with the kit, the pre-push guard refuses anything
     but STATE.md on `main`.
3. **Rewrite `.agents/STATE.md`.** Replace it; don't append. History belongs in git. Create it
   if the repo has none yet.
   - *Now*: what the repo does and where it is deployed or rolled out, **as it will be once this
     branch merges** (on `main`: as it is).
   - *Next*: ordered, concrete steps. A fresh session must be able to start the first one cold.
     Steps that can only happen after the merge (redeploy, paste a block) go here.
   - *Decisions*: only those still shaping the work, each with its reason.
   - *Known issues*: failing checks, workarounds, anything a fresh session would trip on.

   Never write a branch or PR's status ("merged", "pushed", "PR #N open") or a list of merged
   PRs: git has those, and merging makes them wrong. Take facts from this session's command
   output and `git log`, not memory. Mark anything else `unverified`. Keep it under ~40 lines.

   Every PR rewrites STATE.md, so one merged first makes the next conflict. Then rebase on
   `main`, keep `main`'s STATE.md, and redo only this branch's changes to it.
4. **Update docs that changed,** in the same commit: `AGENTS.md` if rules, commands or layout
   changed; README if usage changed. Skip the rest and say you skipped them.
5. **Commit.** Show `git diff --stat`, then commit with a message saying what changed and why.
   Follow the repo's commit rules in `AGENTS.md` (message style, commit identity).
6. **Push,** to where step 2 picked. Running the hand-off is the request to push it.
   - *STATE.md only:* put the commit on top of `main` and push it there, from whatever branch
     you are on: `git rebase origin/main` (on `main`: `git pull --rebase origin main`), then
     `git push origin HEAD:main`. No branch is created, so a generated branch name doesn't
     matter and needs no rename. Never fall back to pushing a branch: the guard refuses it.
     If the remote refuses the push in the cloud, write the file to `main` through the GitHub
     connector instead (its create-or-update-file tool, with this commit's message), so the
     hand-off survives the container. If that fails too, or locally, stop and say so; in the
     cloud, also put the new STATE.md in full in the report.
   - *Work, in the cloud* (`CLAUDE_CODE_REMOTE=true`): push the session's branch: the container
     is discarded and unpushed work is lost. The branch must be named `<type>/<work>`; if it
     still has a generated name, rename it first with `git branch -m <type>/<work>`.
   - *Work, locally:* push only when asked.

   The hand-off itself pushes nothing else.
7. **Report** two lists: *Updated* (every file touched) and *Skipped* (with the reason).
