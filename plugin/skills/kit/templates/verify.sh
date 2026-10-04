#!/usr/bin/env bash
# The one verification command for this repo: tests, lint, type checks, whatever "done" means
# here. The same command runs locally, in CI and in cloud sessions.
#
#   bash scripts/verify.sh           full run; print what passed and what failed
#   bash scripts/verify.sh --quick   SessionStart subset: a few seconds, no network, silent when clean
#
# Exit 0 when everything passes, non-zero otherwise.
#
# This is the repo kit's placeholder, and it fails on purpose until it is replaced, so the
# SessionStart hook keeps asking for it. Replace everything below with this repo's checks.

set -u
echo "scripts/verify.sh is still the repo-kit placeholder; replace it with this repo's checks (AGENTS.md > Commands)."
exit 1
