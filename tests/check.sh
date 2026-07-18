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

if find "$ROOT" -type f -not -path "$ROOT/.git/*" -not -path "$ROOT/tests/check.sh" -not -name README.md \
  -exec grep -En '/Users/|locaphilia|jakobzhao@gmail|GoogleDrive-' {} +; then
  printf '%s\n' 'Personal path or identifier found.' >&2
  exit 1
fi

printf '%s\n' 'Vibe checks passed.'
