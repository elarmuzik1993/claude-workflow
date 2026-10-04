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
#                                trunk. Deployed alone, so it must stay self-contained.
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

# In a repo-kit repo the trunk takes work only through a PR. A hand-off that changes nothing but
# .agents/STATE.md (a redeploy recorded, a step done) is pushed to it directly, so it needs no PR
# of its own. Fails open: a remote commit this clone lacks, or a diff git can't make, is let through.
# $1 remote sha, $2 local sha, $3 the trunk's name
state_only() {
    [ -f .agents/STATE.md ] || return 0
    local files
    files=$(git diff --name-only "$1" "$2" 2>/dev/null) || return 0
    files=$(printf '%s\n' "$files" | grep -vx '\.agents/STATE\.md')
    [ -z "$files" ] && return 0
    cat >&2 <<EOF
Blocked: a direct push to '$3' may change only .agents/STATE.md in this repo; this one also changes:
$(printf '%s\n' "$files" | sed 's/^/  /')
Put the work on a <type>/<work> branch, with its STATE.md update, and open a PR.
Don't bypass this check (--no-verify).
EOF
    exit 1
}

# ── git pre-push: stdin has "<local ref> <local sha> <remote ref> <remote sha>" per ref ──
if [ "$(basename "$0")" = pre-push ]; then
    while read -r _ local_sha remote_ref remote_sha; do
        case "$local_sha" in *[!0]*) ;; *) continue ;; esac     # all zeros: a deletion
        case "$remote_ref" in refs/heads/*) ;; *) continue ;; esac   # tags and other refs
        branch=${remote_ref#refs/heads/}
        case "$remote_sha" in *[!0]*)                           # the remote already has it
            [[ $branch =~ $TRUNK ]] && state_only "$remote_sha" "$local_sha" "$branch"
            continue ;;
        esac
        conforms "$branch" || block "$branch" 1
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

# Print each branch name the command would create, rename to, or push; HEAD means the current
# branch. Deletions, tags, listings and switching to an existing branch print nothing.
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

    if sub == "push":
        if any(a in ("-d", "--delete", "--tags", "--all", "--mirror") for a in args):
            continue
        refspecs = positional(args, ("-o", "--push-option", "--repo", "--receive-pack", "--exec"))[1:]
        if not refspecs:
            print("HEAD")
        for spec in refspecs:
            spec = spec.lstrip("+")
            if spec.startswith(":") or spec.startswith("refs/tags/"):
                continue                                   # deletion, or a tag
            dst = spec.split(":", 1)[1] if ":" in spec else spec
            if not dst.startswith("refs/tags/"):
                print(dst[len("refs/heads/"):] if dst.startswith("refs/heads/") else dst)
    elif sub == "checkout":
        for name in value_after(args, ("-b", "-B")):
            print(name)
    elif sub == "switch":
        for name in value_after(args, ("-c", "-C", "--create", "--force-create")):
            print(name)
    elif sub == "worktree" and args[:1] == ["add"]:
        for name in value_after(args[1:], ("-b", "-B")):
            print(name)
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
            print(names[-1] if renaming else names[0])     # new name: last when renaming, else first
')

while IFS= read -r target; do
    target=${target%$'\r'}                  # Python on Windows prints CRLF; $(...) strips only the last CR
    [ -n "$target" ] || continue
    [ "$target" = HEAD ] && target=$current
    [ -n "$target" ] || continue                                        # detached HEAD
    git show-ref --verify --quiet "refs/tags/$target" 2>/dev/null && continue
    conforms "$target" || block "$target" 2
done <<< "$targets"
exit 0
