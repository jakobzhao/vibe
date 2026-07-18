#!/usr/bin/env sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)

for command in bash git nvim; do
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
grep -Fq "split-window -h -b -l 23%" "$ROOT/bin/vibe"
grep -Fq "split-window -h -l 38%" "$ROOT/bin/vibe"
grep -Fq "split-window -h -l 42%" "$ROOT/bin/vibe"
grep -Fq "claude) PANE_TITLE='Claude'" "$ROOT/bin/vibe"
grep -Fq "gemini) PANE_TITLE='Gemini'" "$ROOT/bin/vibe"
grep -Fq "opencode) PANE_TITLE='OpenCode'" "$ROOT/bin/vibe"
grep -Fq "aider) PANE_TITLE='Aider'" "$ROOT/bin/vibe"
grep -Fq 'Windows 10/11 (WSL2)' "$ROOT/README.md"
grep -Fq 'v0.3.0' "$ROOT/nvim/vibe.lua"

TMP_HOME=$(mktemp -d "${TMPDIR:-/tmp}/vibe-check.XXXXXX")
trap 'rm -rf "$TMP_HOME"' EXIT HUP INT TERM

HOME="$TMP_HOME" "$ROOT/bin/vibe" --help >/dev/null
HOME="$TMP_HOME" "$ROOT/bin/install-vibe" --help >/dev/null
printf '%s\n' 'Checking welcome screen...'
nvim --headless -i NONE -u "$ROOT/nvim/vibe.lua" \
  -l "$ROOT/tests/check-welcome.lua"
nvim --headless -i NONE -u NONE \
  '+lua ya = { sync = function(fn) return fn end }' \
  "+luafile $ROOT/yazi/plugins/vibe-context.yazi/main.lua" '+qa!'

VIBE_CLOSE_TEST="$TMP_HOME/vibe-close.txt"
printf '%s\n' original > "$VIBE_CLOSE_TEST"
for scenario in clean modified force; do
  printf 'Checking close behavior: %s...\n' "$scenario"
  VIBE_ANIMATIONS=0 nvim --headless -i NONE -u "$ROOT/nvim/vibe.lua" "$VIBE_CLOSE_TEST" \
    -l "$ROOT/tests/check-close.lua" "$scenario"
done

printf '%s\n' 'Checking Git review...'
REVIEW_PROJECT="$TMP_HOME/review-project"
mkdir -p "$REVIEW_PROJECT"
git -C "$REVIEW_PROJECT" init -q
printf '%s\n' original > "$REVIEW_PROJECT/tracked.txt"
git -C "$REVIEW_PROJECT" add tracked.txt
git -C "$REVIEW_PROJECT" -c user.name=Vibe -c user.email=vibe@example.invalid commit -qm initial
printf '%s\n' changed > "$REVIEW_PROJECT/tracked.txt"
printf '%s\n' new > "$REVIEW_PROJECT/untracked.txt"
VIBE_PROJECT_DIR="$REVIEW_PROJECT" VIBE_ANIMATIONS=0 \
  nvim --headless -i NONE -u "$ROOT/nvim/vibe.lua" -l "$ROOT/tests/check-review.lua"

if command -v tmux >/dev/null 2>&1 && command -v yazi >/dev/null 2>&1; then
  printf '%s\n' 'Checking multi-agent runtime...'
  "$ROOT/tests/check-runtime.sh"
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
