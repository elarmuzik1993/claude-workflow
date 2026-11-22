#!/usr/bin/env bash
# Commit guard: two rules that are absolute and cheap to check, enforced on every commit.
#
#   pre-commit   refuses a commit that adds a .env file (.env.example and the like are fine) or
#                a line shaped like a credential: a GitHub token, an API key, a private key.
#                A line holding the words "allow-secret" is let through (test fixtures).
#   commit-msg   refuses AI attribution in the message: a Co-Authored-By naming a model, agent
#                or bot, a "Generated with/by" line naming one, or a claude.ai session link.
#
# Source: dotfiles/plugins/workflow/scripts/. Deployed alone as ~/.git_hooks/pre-commit and
# ~/.git_hooks/commit-msg by deploy.sh, and run from the plugin's git-hooks/ in cloud sessions
# (session-start.sh points git there), so it must stay self-contained. The credential patterns
# repeat scripts/check-public.py's; test_commit_guard.py fails when the two differ.
# Fails open without a Python to read the diff. Never bypass it (--no-verify): the branch guard
# refuses that too.

set -u

mode="${WORKFLOW_HOOK:-$(basename "$0")}"
PY=""
for p in python3 python; do "$p" -c '' >/dev/null 2>&1 && { PY=$p; break; }; done
[ -n "$PY" ] || exit 0

case "$mode" in
pre-commit)
    git diff --cached --name-only --diff-filter=A -z 2>/dev/null > "${TMPDIR:-/tmp}/cg.$$.names"
    git diff --cached -U0 --no-color --diff-filter=AM 2>/dev/null | "$PY" -c '
import re, sys
CREDENTIALS = [
    ("GitHub token", r"\b(?:gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,})"),
    ("API key", r"\b(?:sk-(?:ant-)?[A-Za-z0-9_-]{20,}|xox[abprs]-[A-Za-z0-9-]{10,}|AKIA[0-9A-Z]{16}|sbp_[A-Za-z0-9]{20,})"),
    ("private key", r"-----BEGIN [A-Z ]*PRIVATE KEY-----"),
]
ENV_OK = re.compile(r"\.env\.(?:example|sample|template|dist)$")
hits = []
for name in open(sys.argv[1], encoding="utf-8", errors="replace").read().split("\0"):
    base = name.rsplit("/", 1)[-1]
    if (base == ".env" or base.startswith(".env.")) and not ENV_OK.search(base):
        hits.append(f"{name}: an .env file")
path = None
for line in sys.stdin.read().splitlines():
    if line.startswith("+++ "):
        path = line[6:] if line.startswith("+++ b/") else line[4:]
    elif line.startswith("+") and "allow-secret" not in line:
        for what, pattern in CREDENTIALS:
            if re.search(pattern, line):
                hits.append(f"{path}: a line that looks like a {what} (value not shown)")
if hits:
    print("Blocked by the commit guard: this commit would add a secret.", file=sys.stderr)
    for h in hits:
        print("  " + h, file=sys.stderr)
    print("Unstage it (git restore --staged <file>) and keep secrets out of the repo. A fake one in a "
          "test can carry the words allow-secret on its line.", file=sys.stderr)
    sys.exit(1)
' "${TMPDIR:-/tmp}/cg.$$.names"
    status=$?
    rm -f "${TMPDIR:-/tmp}/cg.$$.names"
    exit $status
    ;;
commit-msg)
    [ -f "${1:-}" ] || exit 0
    "$PY" -c '
import re, sys
AGENT = r"(?:claude|anthropic|openai|chatgpt|gpt-?\d|codex|copilot|gemini|cursor|\[bot\]|\bai\b)"
RULES = [
    ("a Co-Authored-By naming a model or bot", re.compile(r"^\s*co-authored-by:.*" + AGENT, re.I)),
    ("a Generated-with line naming a model", re.compile(r"generated (?:with|by)\b.*" + AGENT, re.I)),
    ("a claude.ai session link", re.compile(r"claude\.ai/code", re.I)),
]
hits = []
for line in open(sys.argv[1], encoding="utf-8", errors="replace").read().splitlines():
    if line.startswith("#"):
        continue
    for what, pattern in RULES:
        if pattern.search(line):
            hits.append(f"{what}: {line.strip()[:100]}")
if hits:
    print("Blocked by the commit guard: no AI attribution in commits; the human user is the sole author.",
          file=sys.stderr)
    for h in hits:
        print("  " + h, file=sys.stderr)
    print("Remove those lines and commit again.", file=sys.stderr)
    sys.exit(1)
' "$1" || exit 1
    ;;
esac
exit 0
