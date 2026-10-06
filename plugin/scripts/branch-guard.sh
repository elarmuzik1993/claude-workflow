#!/usr/bin/env bash
# Branch names are always <type>/<work>: a change type, a slash, then short kebab-case
# describing the work. For example: feat/portable-workflow, fix/hook-bom, docs/windows-setup.
# Never a tool-generated name (claude/..., codex/...) and never a random suffix.
#
# This file is the one definition of the convention. Source: dotfiles/plugins/workflow/scripts/.
# It runs in four ways:
#
#   branch-guard.sh              PreToolUse hook on Bash of the `workflow` plugin, in every repo,
#                                locally and in cloud sessions. Blocks (exit 2) a git command
#                                that would create, rename to or push a non-conforming branch.
#                                Claude sees why on stderr.
#   branch-guard.sh --status     for session-start.sh: one line if the current branch breaks the
#                                convention, nothing otherwise.
#   branch-guard.sh --repo-hook  the PreToolUse mode, run from a repo's own .claude/settings.json;
#                                stands down when the plugin is installed, so it runs once.
#   ~/.git_hooks/pre-push        this file, deployed by restore.sh and restore-rules.ps1. Every
#                                git push on my machines, in any repo, from any tool, is checked.
#                                Only branches the push would create are checked; existing ones
#                                keep their names. In a repo with .agents/STATE.md, a push to
#                                main/master may change only that file: work goes through a PR,
#                                and a hand-off with nothing else to say goes straight to the
#                                trunk; any other branch that changes only that file is refused.
#                                Deployed alone, so it must stay self-contained.
#
# A rule in CLAUDE.md is only advice, and cloud sessions are told by their harness to push the
# branch they were assigned (claude/<slug>-<id>), so the convention is enforced here instead.

set -u

TYPES='feat|fix|refactor|perf|docs|test|build|ci|chore'
PATTERN="^($TYPES)/[a-z0-9]+(-[a-z0-9]+)*\$"
LONG_LIVED='^(main|master|develop)$'     # the trunk branches themselves are not <type>/<work>
TRUNK='^(main|master)$'                  # where .agents/STATE.md is read from

conforms() { [[ $1 =~ $PATTERN || $1 =~ $LONG_LIVED ]]; }

# $1 the offending name, $2 exit code (git hooks fail with 1; Claude Code blocks on 2)
block() {
    cat >&2 <<EOF
Blocked: branch name '$1' breaks the convention <type>/<work>.
  type: ${TYPES//|/, }
  work: short kebab-case describing the change, e.g. feat/portable-workflow
Use a conforming name. For an existing branch: git branch -m $1 <type>/<work>
Don't bypass this check (--no-verify). If the remote refuses a conforming name, stop and ask.
EOF
    exit "$2"
}

# In a repo-kit repo (one with .agents/STATE.md) the trunk takes work only through a PR, and a
# hand-off that changes nothing but STATE.md (a review, a redeploy recorded) goes to it directly,
# so it never needs a PR of its own. Both halves are checked here:
#   trunk   a push to the trunk may change only STATE.md;
#   branch  a branch whose only change since it left the trunk is STATE.md is refused, also when
#           its earlier work has already merged: it would need a PR of its own. A cloud session
#           always starts on a branch of its own, so a review-only hand-off lands here if it
#           goes by the branch.
# Fails open: a commit this clone lacks, an unfetched trunk, or a diff git can't make.
# $1 trunk|branch, $2 the range to diff, $3 the branch pushed to, $4 remote, $5 trunk, $6 exit code
STATE=.agents/STATE.md
state_check() {
    [ -f "$STATE" ] || return 0
    local files others
    files=$(git diff --name-only "$2" 2>/dev/null) || return 0
    others=$(printf '%s\n' "$files" | grep -vxF "$STATE")
    if [ "$1" = trunk ]; then
        [ -z "$others" ] && return 0
        cat >&2 <<EOF
Blocked: a direct push to '$3' may change only $STATE in this repo; this one also changes:
$(printf '%s\n' "$others" | sed 's/^/  /')
Put the work on a <type>/<work> branch, with its STATE.md update, and open a PR.
Don't bypass this check (--no-verify).
EOF
    else
        [ -n "$files" ] && [ -z "$others" ] || return 0
        cat >&2 <<EOF
Blocked: branch '$3' changes only $STATE since it left $4/$5 (earlier work on it, if any, has
merged), so it would need a PR of its own. A hand-off with nothing else in it goes to '$5':
  git rebase $4/$5 && git push $4 HEAD:$5
Don't bypass this check (--no-verify).
EOF
    fi
    exit "$6"
}

# The trunk a remote has, as this clone last fetched it; nothing when it has none.
# $1 remote
fetched_trunk() {
    local t
    for t in main master; do
        git rev-parse -q --verify "refs/remotes/$1/$t^{commit}" >/dev/null 2>&1 && { echo "$t"; return 0; }
    done
    return 1
}

# A branch push: $1 the commit pushed, $2 the branch, $3 remote, $4 exit code
branch_check() {
    [[ $2 =~ $LONG_LIVED ]] && return 0
    local trunk
    trunk=$(fetched_trunk "$3") || return 0
    state_check branch "$3/$trunk...$1" "$2" "$3" "$trunk" "$4"
}

# ── git pre-push: stdin has "<local ref> <local sha> <remote ref> <remote sha>" per ref ──
if [ "$(basename "$0")" = pre-push ]; then
    remote=${1:-origin}                     # git passes the remote's name (or its URL: fails open)
    while read -r _ local_sha remote_ref remote_sha; do
        case "$local_sha" in *[!0]*) ;; *) continue ;; esac     # all zeros: a deletion
        case "$remote_ref" in refs/heads/*) ;; *) continue ;; esac   # tags and other refs
        branch=${remote_ref#refs/heads/}
        case "$remote_sha" in *[!0]*)                           # the remote already has it
            if [[ $branch =~ $TRUNK ]]; then
                state_check trunk "$remote_sha..$local_sha" "$branch" "$remote" "$branch" 1
            else
                branch_check "$local_sha" "$branch" "$remote" 1
            fi
            continue ;;
        esac
        conforms "$branch" || block "$branch" 1
        branch_check "$local_sha" "$branch" "$remote" 1
    done
    exit 0
fi

# Same check as session-start.sh's; repeated because the pre-push copy is deployed alone.
plugin_installed() {
    local d
    # Synced from claude.ai: synced/<org>_<account>/<plugin>; marketplace installs: cache/<market>/<plugin>;
    # the cloud setup script (scripts/mirror/setup-block.sh) and deploy.sh: skills/workflow, loaded as workflow@skills-dir.
    for d in "$HOME"/.claude/plugins/synced/*/workflow* "$HOME"/.claude/plugins/cache/*/workflow* \
             "$HOME"/.claude/skills/workflow; do
        [ -e "$d" ] && return 0
    done
    return 1
}
if [ "${1:-}" = --repo-hook ]; then
    plugin_installed && { cat >/dev/null; exit 0; }
    shift
fi

root="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
cd "$root" 2>/dev/null || exit 0
current=$(git branch --show-current 2>/dev/null)

if [ "${1:-}" = --status ]; then
    [ -z "$current" ] || conforms "$current" ||
        printf 'Branch %s breaks the <type>/<work> convention; rename it before pushing: git branch -m <type>/<work>\n' "$current"
    exit 0
fi

# ── PreToolUse: stdin is the tool call as JSON ─────────────────────────────
input=$(cat)
case "$input" in *push*|*branch*|*checkout*|*switch*|*worktree*) ;; *) exit 0 ;; esac   # fast path

PY=""
for p in python3 python; do "$p" -c '' >/dev/null 2>&1 && { PY=$p; break; }; done
[ -n "$PY" ] || exit 0                             # can't parse the call: never block blind

# Print each branch name the command would create or rename to; HEAD means the current branch.
# A push prints "push<TAB>remote<TAB>source<TAB>destination" instead, so the pushed commit is
# checked too. Its source is "-" when that can't be done before the command runs: an earlier
# part of the command makes commits that don't exist yet, or it pushes from another repo (-C).
# Deletions, tags, listings and switching to an existing branch print nothing.
targets=$(printf '%s' "$input" | "$PY" -c '
import json, re, shlex, sys
REDIRECT = re.compile(r"^[0-9]*(?:>>?|<)")               # 2>, >, >>, <, >/dev/null, 2>err.log
HEREDOC = re.compile(r"(?<!<)<<(?!<)(-?)\s*([\"\x27]?)([A-Za-z_][A-Za-z0-9_]*)\2")
SEPARATORS = ";&|()\n"             # a line break ends a command, as `;` does
SQ = "\x27"                        # this program sits inside a single-quoted shell string

def without_heredocs(command):
    """Here-document bodies are text, not commands, and an apostrophe in one used to stop the
    whole command from parsing. An opener with no closing line is left as it is."""
    lines, out, i = command.split("\n"), [], 0
    while i < len(lines):
        out.append(lines[i])
        end = i
        for dash, _, word in HEREDOC.findall(lines[i]):
            j = end + 1
            while j < len(lines) and (lines[j].lstrip("\t") if dash else lines[j]) != word:
                j += 1
            if j == len(lines):
                break
            end = j
        i = end + 1
    return "\n".join(out)

def without_comments(command):
    """Drop comments and join continued lines, outside quotes, as bash does. shlex would let a
    comment swallow the line break that ends its command, joining it to the next line."""
    out, quote, i = [], None, 0
    while i < len(command):
        c = command[i]
        if quote == SQ:
            quote = None if c == SQ else quote
        elif c == "\\" and i + 1 < len(command):
            if command[i + 1] != "\n":
                out.append(command[i:i + 2])
            i += 2
            continue
        elif quote:
            quote = None if c == quote else quote
        elif c in (SQ, "\""):
            quote = c
        elif c == "#" and (not out or out[-1][-1] in " \t" + SEPARATORS):
            while i < len(command) and command[i] != "\n":
                i += 1
            continue
        out.append(c)
        i += 1
    return "".join(out)

try:
    command = json.load(sys.stdin).get("tool_input", {}).get("command", "")
    lexer = shlex.shlex(without_comments(without_heredocs(command)), posix=True,
                        punctuation_chars=SEPARATORS)
    lexer.whitespace_split = True
    lexer.whitespace = " \t\r"
    lexer.commenters = ""
    tokens = list(lexer)
except Exception:
    sys.exit(0)

def value_after(args, flags):
    """Values of flags like -b NAME, -bNAME or --create=NAME."""
    for j, a in enumerate(args):
        if a in flags and j + 1 < len(args):
            yield args[j + 1]
        for f in flags:
            if f.startswith("--") and a.startswith(f + "="):
                yield a.split("=", 1)[1]
            elif not f.startswith("--") and a.startswith(f) and len(a) > len(f):
                yield a[len(f):]

def positional(args, takes_value=()):
    """Non-option arguments, without shell redirections: in `git push 2>&1` the `2>` is not a
    branch. A bare operator (`2>`, `>`) takes the next word as its target, so skip that too."""
    out, skip = [], False
    for a in args:
        if skip:
            skip = False
        elif REDIRECT.match(a):
            skip = REDIRECT.match(a).end() == len(a)
        elif a in takes_value:
            skip = True
        elif a == "--":
            break
        elif not a.startswith("-"):
            out.append(a)
    return out

simple, words = [], []
for token in tokens:
    if token and set(token) <= set(SEPARATORS):
        simple.append(words); words = []
    else:
        words.append(token)
simple.append(words)

out, committing = [], False
for words in simple:
    while words and "=" in words[0] and not words[0].startswith("-"):
        words = words[1:]                                  # leading VAR=value assignments
    if not words or words[0].rsplit("/", 1)[-1] not in ("git", "git.exe"):
        continue
    i = 1
    while i < len(words) and words[i].startswith("-"):     # git -C dir / -c key=value ... <sub>
        i += 2 if words[i] in ("-C", "-c") else 1
    if i >= len(words):
        continue
    sub, args = words[i], words[i + 1:]
    elsewhere = any(w == "-C" or w.startswith(("--git-dir", "--work-tree")) for w in words[1:i])

    if sub == "push":
        if any(a in ("-d", "--delete", "--tags", "--all", "--mirror") for a in args):
            continue
        given = positional(args, ("-o", "--push-option", "--repo", "--receive-pack", "--exec"))
        remote, refspecs = (given[0] if given else "origin"), given[1:]
        unchecked = committing or elsewhere
        if not refspecs:
            out.append(["push", remote, "-" if unchecked else "HEAD", "HEAD"])
        for spec in refspecs:
            spec = spec.lstrip("+")
            if spec.startswith(":") or spec.startswith("refs/tags/"):
                continue                                   # deletion, or a tag
            src, dst = spec.split(":", 1) if ":" in spec else (spec, spec)
            if not dst.startswith("refs/tags/"):
                dst = dst[len("refs/heads/"):] if dst.startswith("refs/heads/") else dst
                out.append(["push", remote, "-" if unchecked else src, dst])
    elif sub == "checkout":
        for name in value_after(args, ("-b", "-B")):
            out.append([name])
    elif sub == "switch":
        for name in value_after(args, ("-c", "-C", "--create", "--force-create")):
            out.append([name])
    elif sub == "worktree" and args[:1] == ["add"]:
        for name in value_after(args[1:], ("-b", "-B")):
            out.append([name])
    elif sub == "branch":
        listing = {"-d", "-D", "--delete", "-l", "--list", "-a", "--all", "-r", "--remotes",
                   "--show-current", "-v", "-vv", "--verbose", "--unset-upstream",
                   "--edit-description", "--contains", "--no-contains", "--merged",
                   "--no-merged", "--points-at"}
        if any(a.split("=", 1)[0] in listing for a in args):
            continue
        names = positional(args, ("-u", "--set-upstream-to", "--sort", "--format"))
        renaming = any(a in ("-m", "-M", "--move", "-c", "-C", "--copy") for a in args)
        if names:
            out.append([names[-1] if renaming else names[0]])     # new name: last when renaming, else first
    if sub in ("commit", "merge", "rebase", "pull", "cherry-pick", "revert", "am", "reset"):
        committing = True

for line in out:
    print("\t".join(line))
')

while IFS= read -r target; do
    target=${target%$'\r'}                  # Python on Windows prints CRLF; $(...) strips only the last CR
    [ -n "$target" ] || continue
    src=
    case "$target" in push$'\t'*) IFS=$'\t' read -r _ remote src target <<< "$target" ;; esac
    [ "$target" = HEAD ] && target=$current
    [ -n "$target" ] || continue                                        # detached HEAD
    git show-ref --verify --quiet "refs/tags/$target" 2>/dev/null && continue
    conforms "$target" || block "$target" 2
    [ -n "$src" ] && [ "$src" != - ] && branch_check "$src" "$target" "$remote" 2
done <<< "$targets"
exit 0
