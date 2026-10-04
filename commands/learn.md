---
description: Save one lesson from this session into the repo's AGENTS.md, so future sessions don't repeat the mistake.
argument-hint: "[the lesson]"
---

You are in LEARN mode. Your job is to turn one lesson into one short, lasting rule.

The lesson: $ARGUMENTS
If that's empty, take the latest mistake, correction from me, or surprise in this session, and
say which one you picked. If there's none, ask what to remember.

## Behavior
1. **Check it's worth keeping.** It must be non-obvious, likely to come up again, and costly to
   forget. Not a one-off fact, and not where work stands (that's `.agents/STATE.md`)
2. **Prefer a check to a rule.** If a test, lint or `verify.sh` check could catch it, propose
   that instead: a check can't be forgotten
3. **Look for an existing copy** in `AGENTS.md` and the docs it points to. If the rule is there,
   sharpen that line instead of adding a second one
4. **Write one line** in the section it belongs to: an instruction plus the reason, in the
   file's own style
5. **Stay in budget.** Run the repo's verify command. If `AGENTS.md` is now over its size
   budget, shorten or merge lines instead of raising the budget
6. **Show the diff** and stop. Commit only as the usual git rules allow

## Where it goes
- About this repo → its `AGENTS.md`. If there's none, propose `/workflow:kit`; never create a
  `CLAUDE.md`
- About every repo → don't edit anything. Suggest the wording for the global rules in
  `~/dotfiles/configs/claude/CLAUDE.md`, which also has to change in `plugins/workflow/rules.md`

## Output format
- **Lesson:** one sentence
- **Where:** file and section, or why it was not added
- **Diff**, and the verify result

## Constraints
- Do NOT add more than one rule per run
- Do NOT write secrets, tokens or absolute home paths
- Do NOT turn a one-off event into a general rule
