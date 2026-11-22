#!/usr/bin/env bash
# Merge gate: in a repo with the kit (.agents/STATE.md and scripts/verify.sh), a PR merges only
# after the repo's verify has passed on the exact commit being merged. A merge lands on the trunk,
# which every machine deploys and the mirror publishes, and there is no CI, so this is the one
# check before a merge.
#
# PreToolUse hook of the `workflow` plugin on the GitHub connector's merge tool and on Bash
# (`gh pr merge`). Blocks (exit 2) with the reason on stderr; exits 0 on every other path.
#   - The commit: the connector call must name it (expectedHeadSha), so what merges is what was
#     verified; for `gh pr merge` it is read with `gh pr view`.
#   - The check: verify runs in a temporary worktree of that commit, so uncommitted files can't
#     make it pass and new files can't be missed. A pass is remembered in the repo's git dir
#     (workflow-verified), so a retry is instant.
# Fails open where it can't judge: no kit, no parser, a gh merge whose PR it can't read.

set -u

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$here/msvc-env.sh"   # On Windows a CMake repo's build needs MSVC's environment.

input=$(cat)
case "$input" in *merge_pull_request*|*"pr merge"*) ;; *) exit 0 ;; esac   # fast path

root="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
cd "$root" 2>/dev/null || exit 0
[ -f .agents/STATE.md ] && [ -f scripts/verify.sh ] || exit 0

PY=""
for p in python3 python; do "$p" -c '' >/dev/null 2>&1 && { PY=$p; break; }; done
[ -n "$PY" ] || exit 0

# Prints "connector<TAB>sha" (sha may be empty), "gh<TAB>pr-arg" (arg may be empty), or nothing.
call=$(printf '%s' "$input" | "$PY" -c '
import json, shlex, sys
try:
    data = json.load(sys.stdin)
except ValueError:
    sys.exit()
tool, args = data.get("tool_name", ""), data.get("tool_input") or {}
if tool.endswith("merge_pull_request"):
    print("connector\t" + str(args.get("expectedHeadSha") or ""))
elif tool == "Bash":
    try:
        words = shlex.split(args.get("command", ""))
    except ValueError:
        sys.exit()
    for i in range(len(words) - 2):
        if words[i:i + 3] == ["gh", "pr", "merge"]:
            rest = [w for w in words[i + 3:] if not w.startswith("-")]
            print("gh\t" + (rest[0] if rest and rest[0] not in (";", "&&", "||", "|") else ""))
            break
')
[ -n "$call" ] || exit 0
kind=${call%%$'\t'*}
arg=${call#*$'\t'}

if [ "$kind" = connector ]; then
    sha=$arg
    if [ -z "$sha" ]; then
        echo "Blocked by the merge gate: pass expectedHeadSha, the PR head commit, so the merge is the commit verify passed on." >&2
        exit 2
    fi
else
    command -v gh >/dev/null 2>&1 || exit 0
    sha=$(gh pr view ${arg:+"$arg"} --json headRefOid --jq .headRefOid 2>/dev/null) || exit 0
    [ -n "$sha" ] || exit 0
fi

gitdir=$(git rev-parse --git-common-dir 2>/dev/null) || exit 0
stamp="$gitdir/workflow-verified"
grep -qx "$sha" "$stamp" 2>/dev/null && exit 0

if ! git cat-file -e "$sha^{commit}" 2>/dev/null; then
    git fetch -q origin "$sha" 2>/dev/null
    if ! git cat-file -e "$sha^{commit}" 2>/dev/null; then
        echo "Blocked by the merge gate: commit ${sha:0:12} isn't in this clone. git fetch origin, then try again." >&2
        exit 2
    fi
fi

tree=$(mktemp -d 2>/dev/null) || exit 0
trap 'git worktree remove --force "$tree" >/dev/null 2>&1; rm -rf "$tree"' EXIT
git worktree add -q --detach "$tree" "$sha" >/dev/null 2>&1 || exit 0
if out=$(cd "$tree" && msvc_env && bash scripts/verify.sh 2>&1); then
    echo "$sha" >> "$stamp"
    exit 0
fi
{
    echo "Blocked by the merge gate: verify fails on ${sha:0:12}, the commit this would merge:"
    printf '%s\n' "$out" | grep -v '^ok ' | tail -n 25
    echo "Fix it on the branch, push, and merge the new head."
} >&2
exit 2
