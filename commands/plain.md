---
description: Explain, sum up or condense, once, in plain words. Modes - default (explain), session (sum up this session), issue (the main problem), tldr (condense, keeps technical terms).
argument-hint: "[session | issue | tldr] [what to cover]"
---

Give ONE short, plain answer in the mode the first word picks, then answer as you normally would.

Arguments: $ARGUMENTS
First word `session`, `issue` or `tldr` picks that mode; anything else, or nothing, is the
default mode, with the arguments as the topic. No topic: use your last answer (default, tldr),
the whole session (session) or the problem blocking the most (issue). Nothing to work from: say
so in one line.

## Modes
- **default: explain** for someone with no technical background.
  1. **In short:** one sentence. 2. **Details:** a few bullets, only if needed.
  3. **What you need to do:** only if something is needed from me.
- **session: sum up this session**, from this conversation only.
  1. **In short:** what it achieved. 2. **How it went:** smooth, bumpy or stuck, and why.
  3. **What got done:** up to 5 bullets, results not steps. 4. **Still open:** only if any.
- **issue: the one main problem**, explained only, nothing fixed or retried.
  1. **The problem:** one sentence. 2. **Why:** say if the cause isn't proven.
  3. **What it blocks**, and what still can be done. 4. **Ways forward:** up to 3, one line
  each with its trade-off, your pick marked. 5. **What you need to do:** only if any.
  Several problems: pick the one blocking the most, list the rest in one line.
- **tldr: condense** a long answer, log, file or thread. Unlike the other modes it **keeps**
  exact terms, names, numbers and error text: shorten, don't simplify.
  **TL;DR:** one sentence, up to 3 bullets, **Next:** one line only if action is needed. For a
  log, the first real error and the final result.

## Rules
- Everyday words in default, session and issue: no jargon, paths, commands or code; a
  technical word that can't be avoided is explained the first time
- Draw only on what this session showed; never claim something finished or checked that wasn't;
  separate what is known from what is a guess
- No padding, no background that doesn't change what I do
- Don't show code, commands or logs unless I ask (tldr keeps quoted error text)
- Don't carry this style into later replies
