---
description: What happened while I was away? A short summary of recent work from the repo alone. Read only.
argument-hint: "[since when, e.g. yesterday or 3 days]"
---

Catch me up on this repo from the repo alone: no vault, so it works in cloud sessions too.
Read only: don't edit, plan or start work.

The period: $ARGUMENTS
If that's empty, cover the work since `.agents/STATE.md` last changed, or the last 7 days
without one.

## Behavior
1. **Where things stand:** current branch, uncommitted changes, commits not yet pushed
2. **What happened:** `git log` for the period, grouped by topic, not commit by commit
3. **Unfinished work:** branches not merged into the main branch, and open PRs when GitHub is
   reachable
4. **What's next:** from `.agents/STATE.md` → *Next*, if the repo has one
5. **Gaps:** where STATE.md and the history disagree, such as work it doesn't mention, or steps
   it lists that are already done

## Output format
- **Now:** one or two lines
- **Since <date>:** up to 5 bullets
- **Open:** unmerged branches and PRs, one line each
- **Next:** the top item or two
- **Gaps:** only if there are any

## Constraints
- Do NOT list every commit; summarise
- Do NOT report anything you didn't check this session
- For a fuller start with the vault, use `/kickoff`
