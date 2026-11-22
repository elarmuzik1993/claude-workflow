---
description: Where does this repo stand? Git state, what happened lately, open work, and progress against the roadmap. Read only.
argument-hint: "[git | since <period> | roadmap]"
---

Report where this repo stands. Read only: don't commit, push, switch, edit, plan or start work.
The repo's rules and hand-off note are already in this session; don't re-read them, build on
them.

Focus: $ARGUMENTS
`git` = the git snapshot only. `since <period>` = what happened in that period (default: since
the hand-off note last changed, or 7 days). `roadmap` = progress against the plan. Nothing =
all of it, briefly.

## Behavior
1. **Refresh:** `git fetch --prune origin` (fetch only). If it fails, say so and use local state
2. **Git now:** branch, clean or dirty, ahead/behind, stashes, other worktrees, any merge or
   rebase in progress; each local branch with its upstream and whether it is merged into main
3. **Lately:** `git log` for the period, grouped by topic, not commit by commit
4. **Open work:** unmerged branches and open PRs (number, title, draft or ready, merges cleanly;
   `gh` locally, the GitHub connector in the cloud). GitHub unreachable: say so
5. **Against the plan:** the roadmap (`ROADMAP.md`, `docs/roadmap*`) or, without one, the hand-off
   note's *Next*: each milestone done, in progress or not started, with evidence. Done means
   merged and checked, not just written down
6. **Gaps:** where the hand-off note, roadmap and history disagree: work done but not recorded,
   steps listed that are already done

## Output format
- **Now:** one or two lines
- **Lately:** up to 5 bullets
- **Open:** branches and PRs, one line each
- **Plan:** a table (milestone, status, evidence), only with a roadmap
- **Next:** the top item or two
- **Worth a look / Gaps:** only if any, one line each

## Constraints
- Do NOT change anything; suggest a command at most, never run it
- Do NOT report anything not checked this session
- Group many merged branches into a count instead of listing them; summarise commits
- Fixing gaps is `/workflow:handoff`'s job
