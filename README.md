# Vibe

Vibe turns a terminal into a small, persistent workspace for coding with AI agents.
One command opens a file browser, an editor, and one or more agents in a tmux session:

```text
┌──────────────────┬────────────────────────────────────┐
│ Shell | Directory│ Editor                             │
├──────────────────┤                                    │
│ Agent            │                                    │
└──────────────────┴────────────────────────────────────┘
```

It is intentionally lightweight: POSIX shell scripts coordinate tmux, Yazi, and
Neovim. Sessions survive terminal disconnects, files open from Yazi into the
editor, and Shell and Directory switch as preserved tabs in the upper-left.
The project Shell uses a minimal `>` prompt, and any CLI agent can run below it.

## Features

- Persistent project workspaces powered by tmux
- Yazi directory browser with reusable favorites
- Preserved Shell and Directory tabs sharing one focused pane
- Neovim or Nano as the Editor
- Codex by default, with named support for Claude, Gemini, OpenCode, and Aider
- Generic support for any persistent interactive CLI agent
- Multiple agents in one workspace
- One-command Git worktrees for isolated tasks
- Mouse and keyboard navigation
- Cloud-safe browsing mode that avoids reading file contents until you open them
- Termius-inspired dark theme for tmux, Yazi, Neovim, and Ghostty

## Requirements

Vibe supports macOS, Ubuntu, and Windows through WSL2. It needs:

- `tmux`
- `yazi`
- `nvim` or Nano
- `git`
- at least one interactive agent command, such as `codex` or `claude`

The installer uses Homebrew on macOS and `apt` plus the official Yazi release
binary on Ubuntu. Windows runs the same Ubuntu path inside WSL2; native Windows
is not supported because Vibe uses tmux.

## Install

### macOS

```sh
curl -fsSL https://raw.githubusercontent.com/jakobzhao/vibe/main/install.sh | sh
```

### Ubuntu 20.04+

Install the two bootstrap tools, then run the same installer. It installs
missing tmux, Yazi, and editor dependencies:

```sh
sudo apt-get update
sudo apt-get install -y curl git
curl -fsSL https://raw.githubusercontent.com/jakobzhao/vibe/main/install.sh | sh
```

### Windows 10/11 (WSL2)

Vibe runs inside Ubuntu on WSL2, not in native PowerShell, Command Prompt, or
Git Bash. From an elevated PowerShell terminal, install WSL when needed:

```powershell
wsl --install -d Ubuntu
```

After the required restart, install Vibe through the included Windows bridge:

```powershell
Invoke-WebRequest https://raw.githubusercontent.com/jakobzhao/vibe/main/install-windows.ps1 -OutFile $env:TEMP\install-vibe.ps1
& $env:TEMP\install-vibe.ps1
```

Open Ubuntu and run `vibe`. Files under `/mnt/c`, `/mnt/d`, and other mounted
Windows drives can be opened, although projects kept in the WSL filesystem are
usually faster.

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
vibe -a gemini -a opencode . # mix other installed agents
vibe -a 'aider --model sonnet' .
vibe -w feature/login .      # create/reuse an isolated Git worktree
vibe --list                  # list running Vibe sessions
```

Set defaults with environment variables:

```sh
export VIBE_AGENT=claude
export VIBE_EDITOR=nano
export VIBE_COMPACT_UI=0  # restore native Codex/Neovim status bars
export VIBE_ANIMATIONS=0  # disable the subtle VIBE title animation
```

Set these variables before running the installer too; validation and automatic
dependency installation will follow the selected agent and editor.

Vibe starts agent commands exactly as supplied. Codex receives optional compact
UI settings; all other agents retain their native interface. Install and
authenticate each agent CLI before selecting it. The default Codex pane is
labeled Agent. Other recognized pane titles include Claude, Gemini, OpenCode,
and Aider, while any other persistent
interactive command uses its executable name.

Inside Vibe, press `Ctrl-a` and then:

| Key | Action |
| --- | --- |
| `h/j/k/l` | Move between panes |
| `d` | Detach and leave the workspace running |
| `Q` | Stop the Vibe session |
| `r` | Reload tmux configuration |
| `|` / `-` | Split the current pane |

Click `Shell` or `Directory` in the upper-left pane title to switch tabs; only
the selected tab is visible, and both keep their running state. In Directory,
`Enter` opens the selected file in Editor. Press `f` to toggle Favorites. Use
`b a` to add an item and `b d` to remove one. In Editor, `:q` closes the current file and returns to the Vibe welcome
screen; `:q!` discards unsaved changes and returns there. Use `Ctrl-a Q` to stop
the complete workspace.

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
- `nvim/vibe.lua` for the Editor
- `ghostty/termius-dark.ghostty` for the optional terminal profile

Vibe keeps user-created favorites outside the repository at
`~/.local/share/vibe/favorites` by default. Override this with
`VIBE_FAVORITES_DIR`.

## Contributing

Issues and pull requests are welcome. Run `./tests/check.sh` before submitting a
change. Please keep the core dependency-light and portable across macOS,
Ubuntu, and WSL2.

## License

MIT. Vendored Yazi plugins retain their own license files.
