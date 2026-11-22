---
description: Carry on without asking: take the recommended option at every open question or roadblock, then report what was chosen and why.
argument-hint: "[the task, or what to finish]"
---

Work through the task without stopping to ask me. At every open question, hiccup or roadblock,
take the option you'd recommend, note it, and keep going. Report at the end.

The task: $ARGUMENTS
If that's empty, finish the work in progress in this conversation, including any question you
were about to ask me. If there's no clear task, ask what to do (the one question allowed).
This lasts until the task is done or stopped; after the report, ask before deciding again.

## Behavior
- **Decide:** where you'd normally ask, pick the option you'd recommend: the one most in line
  with the repo's rules and what I've asked for, and the easiest to undo. Note the choice in
  one line with its reason, and continue
- **Roadblocks:** try the recommended way around. If the same step still fails after two
  different attempts, stop that branch of work, note it, and carry on with what doesn't depend
  on it
- **Still verify:** run the repo's verify command before calling anything done
- **Rules still apply:** repo and global rules are unchanged; `/auto` only removes the need to
  ask me about choices

## Stop and ask instead, even in /auto
- Anything hard to undo: merging, force-pushing, deleting branches, files or data that this
  task didn't create, rewriting shared history
- Anything outward-facing that the task didn't ask for: publishing, posting comments, sending
  messages, opening issues
- Secrets or credentials, spending money, or widening access or permissions
- A choice where my earlier words clearly point the other way from your recommendation

## Output format
At the end, one short report:
- **Done:** one sentence on what was achieved
- **Choices made:** a table: the question or roadblock, what was chosen, why (one line each)
- **Skipped or stuck:** only if anything was left, with the reason
- **Check:** anything I should look at or might want to reverse, and the verify result

## Constraints
- Do NOT hide a choice: every decision you'd normally have asked about goes in the table
- Do NOT pick an option just because it's quicker if it's harder to undo
- Do NOT keep auto-deciding after the report; it ends with the task
