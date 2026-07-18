#!/usr/bin/env sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)

for command in bash nvim; do
  if ! command -v "$command" >/dev/null 2>&1; then
    printf 'Missing test dependency: %s\n' "$command" >&2
    exit 127
  fi
done

for script in "$ROOT"/bin/* "$ROOT"/install.sh; do
  sh -n "$script"
done
bash -n "$ROOT/scripts/restore-if-saved.sh"

grep -Fq 'tmux new-session -d -x "$INITIAL_WIDTH" -y "$INITIAL_HEIGHT"' "$ROOT/bin/vibe"
grep -Fq "split-window -h -b -l 38%" "$ROOT/bin/vibe"
grep -Fq "split-window -v -l 51%" "$ROOT/bin/vibe"
grep -Fq "new-window -d -P -F '#{pane_id}'" "$ROOT/bin/vibe"
grep -Fq "codex) PANE_TITLE='Agent'" "$ROOT/bin/vibe"
grep -Fq "claude) PANE_TITLE='Claude'" "$ROOT/bin/vibe"
grep -Fq "gemini) PANE_TITLE='Gemini'" "$ROOT/bin/vibe"
grep -Fq "opencode) PANE_TITLE='OpenCode'" "$ROOT/bin/vibe"
grep -Fq "aider) PANE_TITLE='Aider'" "$ROOT/bin/vibe"
grep -Fq 'Windows 10/11 (WSL2)' "$ROOT/README.md"
grep -Fq 'v0.2.3' "$ROOT/nvim/vibe.lua"
grep -Fq "set -g status off" "$ROOT/tmux.conf"
! grep -Fq "status on" "$ROOT/bin/vibe-ready"
grep -Fq "@vibe_role 'Explorer'" "$ROOT/bin/vibe"
grep -Fq "@vibe_tab_kind 'directory'" "$ROOT/bin/vibe"
grep -Fq "@vibe_tab_kind 'shell'" "$ROOT/bin/vibe"
grep -Fq 'MouseDown1Border' "$ROOT/tmux.conf"
grep -Fq 'MouseDown1Pane' "$ROOT/tmux.conf"
grep -Fq 'mouse-pane' "$ROOT/tmux.conf"
grep -Fq '@vibe_tab_helper' "$ROOT/tmux.conf"
grep -Fq '#[align=left]' "$ROOT/tmux.conf"
! grep -Fq "Explorer · Favorites:" "$ROOT/bin/vibe"
grep -Fq 'favorites) LABEL="Favorites"' "$ROOT/bin/vibe-favorite"
grep -Fq 'directory) LABEL="Explorer"' "$ROOT/bin/vibe-favorite"
grep -Fq 'ratio = [0, 1, 0]' "$ROOT/yazi/yazi.toml"
grep -Fq 'function Header:cwd()' "$ROOT/yazi/init.lua"
grep -Fq 'plugin vibe-leave' "$ROOT/yazi/keymap.toml"
test -f "$ROOT/yazi/plugins/vibe-leave.yazi/main.lua"

TMP_HOME=$(mktemp -d "${TMPDIR:-/tmp}/vibe-check.XXXXXX")
trap 'rm -rf "$TMP_HOME"' EXIT HUP INT TERM

HOME="$TMP_HOME" "$ROOT/bin/vibe" --help >/dev/null
HOME="$TMP_HOME" "$ROOT/bin/install-vibe" --help >/dev/null
printf '%s\n' 'Checking welcome screen...'
nvim --headless -i NONE -u "$ROOT/nvim/vibe.lua" \
  -l "$ROOT/tests/check-welcome.lua"

VIBE_CLOSE_TEST="$TMP_HOME/vibe-close.txt"
printf '%s\n' original > "$VIBE_CLOSE_TEST"
for scenario in clean modified force; do
  printf 'Checking close behavior: %s...\n' "$scenario"
  VIBE_ANIMATIONS=0 nvim --headless -i NONE -u "$ROOT/nvim/vibe.lua" "$VIBE_CLOSE_TEST" \
    -l "$ROOT/tests/check-close.lua" "$scenario"
done

if command -v tmux >/dev/null 2>&1 && command -v yazi >/dev/null 2>&1; then
  printf '%s\n' 'Checking multi-agent runtime...'
  if ! "$ROOT/tests/check-runtime.sh"; then
    printf '%s\n' 'Runtime check failed; rerunning with shell trace...' >&2
    sh -x "$ROOT/tests/check-runtime.sh"
    exit 1
  fi
else
  printf '%s\n' 'Skipping runtime check (tmux or yazi is missing).'
fi

if find "$ROOT" -type f -not -path "$ROOT/.git" -not -path "$ROOT/.git/*" \
  -not -path "$ROOT/tests/check.sh" -not -name README.md \
  -exec grep -En '/Users/|locaphilia|jakobzhao@gmail|GoogleDrive-' {} +; then
  printf '%s\n' 'Personal path or identifier found.' >&2
  exit 1
fi

printf '%s\n' 'Vibe checks passed.'
