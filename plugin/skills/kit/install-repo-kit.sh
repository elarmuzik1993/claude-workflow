#!/usr/bin/env bash
# Install the repo side of the portable workflow, so every session in the repo, local or cloud,
# starts with the same rules, state and verification.
#
#   bash install-repo-kit.sh [--check] [REPO]    (REPO defaults to .)
#
#   (no flag)  create whatever is missing; never overwrite
#   --check    change nothing; report what is MISSING, wrong or still template text;
#              silent and exit 0 when clean. The session-start hook runs it in kit repos.
#
# It ships inside the workflow plugin, so any session can run it: /workflow:kit (the SKILL.md
# beside it) installs the kit and then fills it in from the repo.
#
# The kit is only neutral, tool-agnostic files, so it suits public repos too:
#
#   AGENTS.md          rules, with a session-workflow section; imports .agents/STATE.md.
#                      Claude Code and Codex both read it directly, so no CLAUDE.md is needed.
#   .agents/STATE.md   the hand-off between sessions
#   scripts/verify.sh  the repo's one verification command (a placeholder that fails until replaced)
#
# Each is created once and then owned by the repo. The automation (session-start checks, the
# branch guard, /workflow:handoff) comes from the `workflow` plugin, installed on each machine
# and in each cloud environment's Setup script, so nothing Claude-specific is committed.
# .gitattributes gets `*.sh text eol=lf` appended when absent. Nothing else is touched.

set -u

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/templates"

mode=install
case "${1:-}" in
    --check)  mode=check; shift ;;
    -h|--help) sed -n '2,/^$/p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) echo "unknown option: $1" >&2; exit 2 ;;
esac
REPO="${1:-.}"
[ -d "$REPO" ] || { echo "not a directory: $REPO" >&2; exit 2; }
REPO="$(cd "$REPO" && pwd)"

# source (in templates/)|destination (in the repo)
MANIFEST="
AGENTS.md.tmpl|AGENTS.md
STATE.md.tmpl|.agents/STATE.md
verify.sh|scripts/verify.sh
"

problems=0
say()  { [ "$mode" = check ] || printf '  %-8s %s\n' "$1" "$2"; }
flag() { problems=$((problems + 1)); printf '  %-8s %s\n' "$1" "$2"; }

while IFS='|' read -r src dest; do
    [ -n "$src" ] || continue
    from="$KIT/$src" to="$REPO/$dest"
    [ -r "$from" ] || { echo "kit source missing: $from" >&2; exit 2; }
    if [ -e "$to" ]; then
        say exists "$dest"
    elif [ "$mode" = check ]; then
        flag MISSING "$dest"
    else
        mkdir -p "$(dirname "$to")" && cp "$from" "$to"
        case "$dest" in *.sh) chmod +x "$to" ;; esac
        say created "$dest"
    fi
done <<EOF
$MANIFEST
EOF

has_line() { grep -qE "^${2//./\\.}[[:space:]]*$" "$REPO/$1" 2>/dev/null; }

# Claude Code reads AGENTS.md directly only when the repo has no CLAUDE.md. A CLAUDE.md that
# doesn't import AGENTS.md hides it, and with it the rules and the state import.
if [ -f "$REPO/CLAUDE.md" ] && ! has_line CLAUDE.md @AGENTS.md; then
    flag HIDDEN "CLAUDE.md hides AGENTS.md from Claude: delete CLAUDE.md, or add a line '@AGENTS.md'"
fi

# The state note loads only through an import; without one, sessions start blind.
if [ -f "$REPO/AGENTS.md" ] && ! has_line AGENTS.md @.agents/STATE.md && ! has_line CLAUDE.md @.agents/STATE.md; then
    flag IMPORT "no line '@.agents/STATE.md' in AGENTS.md (or CLAUDE.md); merge it from the kit's templates/AGENTS.md.tmpl"
fi

# .gitattributes: shell scripts run under Git Bash on Windows, which rejects CRLF.
# Compare and copy lines without their CRs. Either file can have CRLF line endings (a Windows
# checkout, a repo committed from Windows), and a stray CR makes a present line look missing.
# Git for Windows' grep drops CRs from the file it searches, but not from the pattern.
attrs="$REPO/.gitattributes" missing=""
while IFS= read -r line; do
    line=${line%$'\r'}
    case "$line" in ''|'#'*) continue ;; esac
    tr -d '\r' 2>/dev/null < "$attrs" | grep -qxF "$line" || missing="$missing$line"$'\n'
done < "$KIT/gitattributes"
if [ -n "$missing" ]; then
    if [ "$mode" = check ]; then
        flag LINES ".gitattributes lacks: $(printf '%s' "$missing" | tr '\n' ' ')"
    else
        { [ -s "$attrs" ] && [ -n "$(tail -c1 "$attrs")" ] && echo
          [ -s "$attrs" ] && echo
          grep '^#' "$KIT/gitattributes" | tr -d '\r'
          printf '%s' "$missing"; } >> "$attrs"
        say updated ".gitattributes (+ $(printf '%s' "$missing" | tr '\n' ' '))"
    fi
fi

# Template text left in place: the kit was installed but never filled in, so sessions run on
# placeholder rules and state. Only --check reports it; right after an install it is expected.
# Each marker is a whole line of its template (the tests check), and never one a finished file
# keeps, like the rules' `<type>/<work>`.
placeholder() {    # repo file, then its marker lines on stdin
    local line first=""
    [ -f "$REPO/$1" ] || return 0
    while IFS= read -r line; do
        [ -n "$line" ] && tr -d '\r' < "$REPO/$1" | grep -qxF -- "$line" && { first=$line; break; }
    done
    [ -z "$first" ] || flag TEMPLATE "$1 still has template text: '$first'; fill it in (/workflow:kit)"
}
if [ "$mode" = check ]; then
    placeholder AGENTS.md <<'EOF'
# AGENTS.md: <project>
Obsidian: [[<Project>]]
<One paragraph: what this repo is, who uses it, what "working" means.>
| `<dir>/` | <purpose> |
| <run / build / test one thing> | `<command>` |
- <naming, patterns, and libraries to prefer or avoid>
EOF
    placeholder .agents/STATE.md <<'EOF'
_Updated YYYY-MM-DD_
- <decision>: <why> (only ones that still shape the work)
- <problem>: <where>; <workaround>
EOF
fi

if [ "$mode" = check ]; then
    [ "$problems" -eq 0 ] && exit 0
    printf 'repo kit: %d problem(s) in %s\n' "$problems" "$REPO"
    exit 1
fi

cat <<EOF

Repo kit installed in $REPO.
Next: fill in AGENTS.md, replace the scripts/verify.sh placeholder, then commit. The session
hooks, /workflow:kit and /workflow:handoff come from the workflow plugin.
EOF
[ "$problems" -eq 0 ] || exit 1
