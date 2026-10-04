# shellcheck shell=bash
# workflow plugin: paste once into the cloud environment's Setup script; it never needs updating.
# Installs the workflow plugin and the personal commands from the public mirror
# github.com/elarmuzik1993/claude-workflow. The cached environment can be days old, so the plugin
# then refreshes itself from the mirror at every session start.
# A block, not a whole script: it never exits, so it can sit anywhere in an existing Setup script,
# and a failure warns instead of failing the session start.
(
    set -e
    # A committed file, served through raw.githubusercontent.com: the one GitHub route a cloud
    # session allows for a repo not attached to it. Older pastes download from codeload, which
    # works at setup time; their plugin still refreshes through this route.
    url="${WORKFLOW_MIRROR_URL:-https://raw.githubusercontent.com/elarmuzik1993/claude-workflow/main/workflow.tar.gz}"
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT
    curl -fsSL --retry 2 --max-time 60 "$url" | tar -xz -C "$tmp" --strip-components=1
    bash "$tmp/install.sh"
) || echo "workflow plugin: install failed; sessions start without it" >&2
