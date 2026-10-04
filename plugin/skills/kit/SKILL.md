---
name: kit
description: Install the repo kit (AGENTS.md, .agents/STATE.md, scripts/verify.sh) into the current repo and fill it in from that repo alone. Use when the user says "install the kit", "set up this repo for the workflow", or runs /workflow:kit, or when session start reports kit problems.
---

# Install and fill in the repo kit

The kit is what a session in this repo starts from, so a wrong fact here misleads every later
session. **Take every fact from this repo's files and from commands you run in it.** Nothing
from other repos, from earlier in this conversation, or from what similar projects usually do.
If this session has worked in another repo, say so and suggest a fresh session started on this
one; stop if the user agrees.

1. **Scope.** `git rev-parse --show-toplevel` names the repo; say which one you are setting up.
   If the tree has uncommitted changes, ask before going on. Work on a `chore/repo-kit` branch;
   in a cloud session that means renaming the assigned `claude/...` branch.
2. **Install.** Run `bash "${CLAUDE_SKILL_DIR}/install-repo-kit.sh" .` (the installer sits in
   this skill's base directory). It creates only what is missing and never overwrites.
   - An existing `AGENTS.md` stays. Add the template's *Current state* and *Session workflow*
     sections to it (`${CLAUDE_SKILL_DIR}/templates/AGENTS.md.tmpl`), and ask before adding
     its *Rules*: the repo may have conventions of its own.
   - An existing `CLAUDE.md` that doesn't import `AGENTS.md`: add a line `@AGENTS.md`. Ask
     before deleting anything.
3. **Fill in `AGENTS.md`** from the README, the manifests (`package.json`, `pyproject.toml`,
   `Makefile`, ...), the CI workflows and the top-level layout. A command goes in *Commands*
   only if it appears in one of those files or you ran it. Where the repo gives no answer,
   delete the placeholder and add a question under *Next* in STATE.md; never fill it with a
   guess. Keep the file short: it loads in every session.
4. **The `Obsidian:` line.** The vault exists only on the user's machines. Ask for the vault
   project name; with no answer, delete the line.
5. **Replace `scripts/verify.sh`** with the checks CI or the manifests already run. If the repo
   has none, write the smallest checks that catch real breakage, and build any list they walk
   (assets, pages, routes) from the source files when the script runs, never typed out: a
   typed list misses the next file that changes. `--quick` is the session-start subset: a few
   seconds, no network, and no output at all when clean. Run both modes.
   A check that fails on today's code stays and goes under *Known issues*; never drop a check
   to get green. If the checks need dependencies a fresh clone lacks, add `.agents/bootstrap.sh`
   with the repo's install command; cloud sessions run it at start.
6. **Write `.agents/STATE.md`** as `/workflow:handoff` step 2 describes, from this session's
   evidence. *Now* names the kit branch as awaiting review. *Next* starts with reviewing and
   merging it, then the owner's open questions from steps 3 and 4. Concrete steps only; a line
   like "incoming feature requests" tells the next session nothing.
7. **Check.** `bash "${CLAUDE_SKILL_DIR}/install-repo-kit.sh" --check .` must print nothing, and
   `bash scripts/verify.sh` must pass or have its failures recorded as step 5 says.
8. **Commit and report.** Show `git diff`, commit, and in a cloud session push the branch. Don't
   merge: the first `AGENTS.md` shapes every later session, so the user reviews it, ideally as
   a PR. Report what you filled in, which commands you ran and which you only found in files,
   and the questions left for the owner.
