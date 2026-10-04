#!/usr/bin/env bash
# Install the workflow plugin and the personal commands from this mirror into ~/.claude.
#
# Run from an unpacked copy of the mirror by the cloud environment's Setup script block
# (setup-block.sh) and, at every cloud session start, by the plugin itself (session-start.sh):
# the Setup script's result is cached for up to about seven days, the refresh is not.
#
# The plugin records where to refresh from as .mirror-url: the mirror's workflow.tar.gz through
# raw.githubusercontent.com, the one route a cloud session's GitHub proxy allows for a repo not
# attached to the session (an archive download from codeload gets a 403 there). Set here, not
# by the Setup block, so changing the route needs no re-paste. WORKFLOW_REFRESH_URL overrides it.

set -eu
REFRESH_URL="${WORKFLOW_REFRESH_URL:-https://raw.githubusercontent.com/elarmuzik1993/claude-workflow/main/workflow.tar.gz}"
src="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dest="$HOME/.claude/skills/workflow"

mkdir -p "$HOME/.claude/skills" "$HOME/.claude/commands"
# Build the new copy beside the old one and swap, so a failed copy never leaves no plugin.
rm -rf "$dest.new"
cp -r "$src/plugin" "$dest.new"
printf '%s\n' "$REFRESH_URL" > "$dest.new/.mirror-url"
rm -rf "$dest"
mv "$dest.new" "$dest"

# Copied over, never pruned: a cloud VM starts with no other commands to protect or remove.
cp "$src/commands/"*.md "$HOME/.claude/commands/"
