#!/usr/bin/env bash
# SessionStart hook of the `workflow` plugin. It runs at the start of every Claude Code session,
# in every repo, on any machine and in cloud sessions (claude.ai/code, the mobile app).
#
# Source of truth: dotfiles/plugins/workflow/. The plugin reaches sessions through a cloud
# environment's Setup script or the claude.ai account (README), so nothing needs to be
# committed to the repos it runs in.
#
# Stdout becomes session context, so it prints one status line plus only what needs action,
# and it never fails the session: every path exits 0.
#
#   session-start.sh              run as the plugin's hook
#   session-start.sh --repo-hook  run from a repo's own .claude/settings.json; stands down when
#                                 the plugin is installed, so the two never both print

set -u

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
[ "${1:-}" = --repo-hook ] && plugin_installed && exit 0

root="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
cd "$root" 2>/dev/null || exit 0

STATE=.agents/STATE.md
STATE_MAX_LINES="${STATE_MAX_LINES:-60}"
[ -f "$STATE" ] && workflow=1 || workflow=0     # the repo opted in: it has a hand-off note

if [ "${CLAUDE_CODE_REMOTE:-}" = "true" ]; then where=cloud; else where=local; fi

# A cloud session starts from a snapshot of the Setup script's install that can be about seven
# days old. A plugin installed from the public mirror records where from (.mirror-url), so it
# refreshes itself here and this session's hooks run the current version. Bounded, and quiet
# unless the version changed or the refresh failed. Locally, auto-sync.sh keeps it current.
mirror="$here/../.mirror-url"
if [ "$where" = cloud ] && [ -r "$mirror" ]; then
    version() { grep -o '"version": *"[^"]*"' "$here/../.claude-plugin/plugin.json" 2>/dev/null | grep -o '[0-9][^"]*'; }
    was=$(version)
    url=$(head -n1 "$mirror")
    if ( tmp=$(mktemp -d) && trap 'rm -rf "$tmp"' EXIT &&
         curl -fsSL --max-time "${WORKFLOW_REFRESH_TIMEOUT:-10}" "$url" | tar -xz -C "$tmp" --strip-components=1 &&
         WORKFLOW_MIRROR_URL=$url bash "$tmp/install.sh" ) >/dev/null 2>&1; then
        now=$(version)
        [ "$now" = "$was" ] || printf 'workflow plugin %s -> %s, refreshed from the mirror\n' "${was:-?}" "${now:-?}"
    else
        printf 'workflow plugin: refresh from the mirror failed; running the cached %s\n' "${was:-version}"
    fi
fi

# A cloud container starts from a fresh clone, so install the repo's dependencies there if it
# has an install step. Locally they are already installed, and reinstalling on every start is slow.
if [ "$where" = cloud ] && [ -f .agents/bootstrap.sh ]; then
    if ! out=$(bash .agents/bootstrap.sh 2>&1); then
        printf 'bootstrap FAILED (.agents/bootstrap.sh), last lines:\n%s\n\n' \
            "$(printf '%s\n' "$out" | tail -n 20)"
    fi
fi

if git rev-parse --git-dir >/dev/null 2>&1; then
    branch=$(git branch --show-current 2>/dev/null)
    changes=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    if [ "${changes:-0}" = 0 ]; then tree=clean; else tree="$changes uncommitted"; fi
    printf 'Session: %s · branch %s · %s\n' "$where" "${branch:-detached}" "$tree"
    # Branch names are <type>/<work>. Cloud sessions start on a generated claude/<slug>-<id>
    # branch, which has to be renamed before anything is pushed; branch-guard.sh blocks the push.
    bash "$here/branch-guard.sh" --status
fi

# Cloud sessions never load ~/.claude/CLAUDE.md, so bring the core rules along. Locally that
# file already carries them.
if [ "$where" = cloud ]; then
    printf 'Cloud session: commit and push before ending; the container is discarded.\n'
    if [ -f "$here/../rules.md" ]; then
        printf '\nCore rules (workflow plugin):\n'
        grep '^- ' "$here/../rules.md"
    fi
fi

[ "$workflow" = 1 ] || exit 0

# STATE.md is the hand-off from the last session. Commits after its last update are work it
# does not describe, often made outside Claude, so say how far behind it is. Merge commits don't
# count: the hand-off rides in the work PR, so merging that PR adds nothing it doesn't describe.
last=$(git log -1 --format=%H -- "$STATE" 2>/dev/null)
if [ -n "$last" ]; then
    behind=$(git rev-list --count --no-merges "$last..HEAD" 2>/dev/null || echo 0)
    [ "${behind:-0}" -gt 0 ] 2>/dev/null &&
        printf '%s is %s commit(s) behind HEAD; read git log before trusting it.\n' "$STATE" "$behind"
fi
lines=$(wc -l < "$STATE" | tr -d ' ')
[ "${lines:-0}" -gt "$STATE_MAX_LINES" ] 2>/dev/null &&
    printf '%s is %s lines (cap %s); trim it at the next hand-off.\n' "$STATE" "$lines" "$STATE_MAX_LINES"

# The kit itself: missing files, a hidden AGENTS.md, template text never filled in. The
# installer's --check is the one definition of a complete kit, and silent when it is.
kit="$here/../skills/kit/install-repo-kit.sh"
if [ -f "$kit" ] && ! out=$(bash "$kit" --check . 2>&1); then
    printf '\n%s\n' "$out"
fi

# Quick verification. The repo's verify script is silent when clean, so this adds nothing
# to the context unless something is broken.
if [ -f scripts/verify.sh ]; then
    if ! out=$(bash scripts/verify.sh --quick 2>&1); then
        printf '\nscripts/verify.sh --quick FAILED; fix this before other work:\n%s\n' "$out"
    fi
fi

exit 0
