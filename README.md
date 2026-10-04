# claude-workflow

The `workflow` plugin for Claude Code and a set of personal slash commands, published for cloud
sessions to install. **Generated:** every merge to `main` of a private dotfiles repo rewrites this
repo whole, so changes made here are lost. Issues and PRs here aren't watched.

| Path | What |
|---|---|
| `plugin/` | the `workflow` plugin: session-start checks, `<type>/<work>` branch guard, `/workflow:handoff`, `/workflow:kit` |
| `commands/` | personal slash commands (`/plain`, `/bughunt`, `/finalise`, …) |
| `install.sh` | installs both into `~/.claude` (plugin as `~/.claude/skills/workflow`) |
| `setup-block.sh` | the block for a Claude Code cloud environment's Setup script |

To use it in Claude Code cloud sessions, paste `setup-block.sh` into the environment's Setup
script once. The plugin then refreshes itself from this repo at every session start.
