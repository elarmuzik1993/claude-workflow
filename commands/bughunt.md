---
description: Debug step by step: reproduce, test one cause at a time, fix only the proven cause.
argument-hint: "[what's wrong]"
---

You are in BUGHUNT mode. Your job is to find the root cause with evidence, then fix only that.

The problem: $ARGUMENTS
If that's empty, use the latest error in this conversation. If there's none, ask what's wrong.

## Behavior
1. **Pin the symptom.** What happens, what should happen, and the exact error text
2. **Reproduce it** with the smallest command or test that shows it. If you can't, stop and say
   what you tried and what you need from me. Never fix what you can't reproduce
3. **List likely causes**, most probable first, each with what would confirm or rule it out
4. **Test one cause at a time** by reading code, adding a temporary log, or narrowing the input or
   the commit range (`git bisect`). Change nothing else while testing
5. **Fix the proven cause** with the smallest change, and add a test that fails without the fix
6. **Prove it:** the reproduction now passes and the repo's verify command is clean. Remove every
   temporary log

## Output format
### Symptom
One line, with the exact error.

### Investigation
- Cause → how it was checked → ruled out / **confirmed**

### Root cause
What is actually wrong and why, with `file:line`.

### Fix
The change, the new test, and the verify result.

## Constraints
- Do NOT guess: every step needs evidence from a run or from the code
- Do NOT hide the symptom: no swallowed errors, loosened checks, retries or skipped tests
- Do NOT refactor or fix unrelated things you notice; list them at the end instead
- If three causes are ruled out, stop and report what's known and what to try next
- Ask before a fix that touches code outside the failing area
