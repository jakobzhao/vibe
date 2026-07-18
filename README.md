# Vibe

Vibe turns a terminal into a small, persistent workspace for coding with AI agents.
One command opens a file browser, an editor, and one or more agents in a tmux session:

```text
┌────────┬─────────┬────────────────────────────────────┐
│ Direct.│ Shell   │ Main editor                        │
├────────┴─────────┤                                    │
│ Codex / agent    │                                    │
└──────────────────┴────────────────────────────────────┘
```

It is intentionally lightweight: POSIX shell scripts coordinate tmux, Yazi, and
Neovim. Sessions survive terminal disconnects, files open from Yazi into the main
editor, the upper-left Shell is ready for project commands, and any CLI agent can
run in the lower-left pane.

## Features

- Persistent project workspaces powered by tmux
- Yazi directory browser with reusable favorites
- Ready-to-use project shell beside the directory browser
- Neovim or Nano as the main editor
- Codex by default, with support for Claude or any interactive CLI agent
- Multiple agents in one workspace
- One-command Git worktrees for isolated tasks
- Mouse and keyboard navigation
- Cloud-safe browsing mode that avoids reading file contents until you open them
- Termius-inspired dark theme for tmux, Yazi, Neovim, and Ghostty

## Requirements

Vibe supports macOS and Linux. It needs:

- `tmux`
- `yazi`
- `nvim` or Nano
- `git`
- at least one interactive agent command, such as `codex` or `claude`

The installer can install dependencies through Homebrew. On Linux without
Homebrew, install the requirements with your system package manager first.

## Install

### Quick install

```sh
curl -fsSL https://raw.githubusercontent.com/jakobzhao/vibe/main/install.sh | sh
```

The installer clones Vibe into `~/.local/share/vibe`, creates links in `~/bin`,
preserves replaced files as timestamped backups, installs TPM plugins, and adds
`~/bin` to your shell path.

### Clone it yourself

```sh
git clone https://github.com/jakobzhao/vibe.git ~/.local/share/vibe
~/.local/share/vibe/bin/install-vibe
```

Useful installer options:

```text
--check          validate without changing anything
--skip-packages  do not install missing packages or Codex
--no-ghostty     do not configure Ghostty or install Fira Mono
```

## Use

```sh
vibe                         # current directory, Codex agent
vibe ~/code/my-project       # another project
vibe -a claude .             # use another agent
vibe -a codex -a claude .    # run multiple agents
vibe -w feature/login .      # create/reuse an isolated Git worktree
vibe --list                  # list running Vibe sessions
```

Set defaults with environment variables:

```sh
export VIBE_AGENT=claude
export VIBE_EDITOR=nano
export VIBE_COMPACT_UI=0  # restore native Codex/Neovim status bars
```

Set these variables before running the installer too; validation and automatic
dependency installation will follow the selected agent and editor.

Inside Vibe, press `Ctrl-a` and then:

| Key | Action |
| --- | --- |
| `h/j/k/l` | Move between panes |
| `d` | Detach and leave the workspace running |
| `Q` | Stop the Vibe session |
| `r` | Reload tmux configuration |
| `|` / `-` | Split the current pane |

In Directory, `Enter` opens the selected file in Main. Press `f` or click the
Directory pane title to toggle Favorites. Use `b a` to add an item and `b d` to
remove one.

## Update

Run the quick installer again, or:

```sh
git -C ~/.local/share/vibe pull --ff-only
~/.local/share/vibe/bin/install-vibe
```

## Configuration

The repository is the configuration. Fork it and edit:

- `tmux.conf` for layout controls and colors
- `yazi/` for browsing and file actions
- `nvim/vibe.lua` for the main editor
- `ghostty/termius-dark.ghostty` for the optional terminal profile

Vibe keeps user-created favorites outside the repository at
`~/.local/share/vibe/favorites` by default. Override this with
`VIBE_FAVORITES_DIR`.

## Contributing

Issues and pull requests are welcome. Run `./tests/check.sh` before submitting a
change. Please keep the core dependency-light and portable across macOS and Linux.

## License

MIT. Vendored Yazi plugins retain their own license files.
