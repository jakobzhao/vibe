#!/usr/bin/env sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)

for script in "$ROOT"/bin/* "$ROOT"/install.sh; do
  sh -n "$script"
done
bash -n "$ROOT/scripts/restore-if-saved.sh"

TMP_HOME=$(mktemp -d "${TMPDIR:-/tmp}/vibe-check.XXXXXX")
trap 'rm -rf "$TMP_HOME"' EXIT HUP INT TERM

HOME="$TMP_HOME" "$ROOT/bin/vibe" --help >/dev/null
HOME="$TMP_HOME" "$ROOT/bin/install-vibe" --help >/dev/null
nvim --headless -i NONE -u "$ROOT/nvim/vibe.lua" \
  +"luafile $ROOT/tests/check-welcome.lua" +qa! >/dev/null 2>&1

VIBE_CLOSE_TEST="$TMP_HOME/vibe-close.txt"
printf '%s\n' original > "$VIBE_CLOSE_TEST"
nvim --headless -i NONE -u "$ROOT/nvim/vibe.lua" "$VIBE_CLOSE_TEST" \
  +"lua vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(':q<CR>', true, false, true), 'xt', false)" \
  +"lua assert(vim.bo.filetype == 'vibe-welcome')" +qa! >/dev/null 2>&1
nvim --headless -i NONE -u "$ROOT/nvim/vibe.lua" "$VIBE_CLOSE_TEST" \
  +"lua vim.api.nvim_buf_set_lines(0, 0, -1, false, {'changed'})" \
  +'silent! VibeClose' +"lua assert(vim.bo.filetype ~= 'vibe-welcome')" +qa! >/dev/null 2>&1
nvim --headless -i NONE -u "$ROOT/nvim/vibe.lua" "$VIBE_CLOSE_TEST" \
  +"lua vim.api.nvim_buf_set_lines(0, 0, -1, false, {'changed'})" \
  +'VibeClose!' +"lua assert(vim.bo.filetype == 'vibe-welcome')" +qa! >/dev/null 2>&1

if find "$ROOT" -type f -not -path "$ROOT/.git/*" -not -path "$ROOT/tests/check.sh" -not -name README.md \
  -exec grep -En '/Users/|locaphilia|jakobzhao@gmail|GoogleDrive-' {} +; then
  printf '%s\n' 'Personal path or identifier found.' >&2
  exit 1
fi

printf '%s\n' 'Vibe checks passed.'
