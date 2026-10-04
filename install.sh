#!/usr/bin/env bash
# Install the workflow plugin and the personal commands from this mirror into ~/.claude.
#
# Run from an unpacked copy of the mirror by the cloud environment's Setup script block
# (setup-block.sh) and, at every cloud session start, by the plugin itself (session-start.sh):
# the Setup script's result is cached for up to about seven days, the refresh is not.
#
# WORKFLOW_MIRROR_URL, the tarball this copy came from, is recorded in the plugin as
# .mirror-url, which is what tells the plugin to refresh itself and from where.

set -eu
src="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dest="$HOME/.claude/skills/workflow"

mkdir -p "$HOME/.claude/skills" "$HOME/.claude/commands"
# Build the new copy beside the old one and swap, so a failed copy never leaves no plugin.
rm -rf "$dest.new"
cp -r "$src/plugin" "$dest.new"
[ -z "${WORKFLOW_MIRROR_URL:-}" ] || printf '%s\n' "$WORKFLOW_MIRROR_URL" > "$dest.new/.mirror-url"
rm -rf "$dest"
mv "$dest.new" "$dest"

# Copied over, never pruned: a cloud VM starts with no other commands to protect or remove.
cp "$src/commands/"*.md "$HOME/.claude/commands/"
