---
description: Condense a long answer, log, file or thread to the few points that matter, once. Keeps technical terms.
argument-hint: "[text, file or topic]"
---

Give ONE condensed summary: the few points that matter, nothing else.

What to condense: $ARGUMENTS
That can be pasted text, a file path, a command's output or a topic from this conversation. If
it's empty, condense your last answer. If there's nothing to condense, ask what to summarise.
This applies to this reply only: after it, answer as you normally would.

## Behavior
- Keep the facts that change a decision: results, errors, numbers, names, what's blocked
- Keep exact terms, file names and error text. Shorten, don't simplify (that's `/plain`)
- Drop background, repetition, hedging and anything already settled
- For a log or test output: the first real error and the final result, not every line

## Output format
- **TL;DR:** one sentence
- Up to 3 bullets with the key points
- **Next:** one line, only if an action is needed

## Constraints
- Do NOT add anything that isn't in the source
- Do NOT go past 3 bullets; pick the most important ones
- Do NOT carry this style into later replies
