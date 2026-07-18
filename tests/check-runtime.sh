#!/usr/bin/env sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)

for COMMAND in tmux yazi nvim tail sleep; do
  command -v "$COMMAND" >/dev/null 2>&1 || {
    printf 'Missing runtime test dependency: %s\n' "$COMMAND" >&2
    exit 127
  }
done
REAL_TMUX=$(command -v tmux)

TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/vibe-runtime.XXXXXX")
TEST_HOME="$TEST_ROOT/home"
TEST_PROJECT="$TEST_ROOT/project"
TEST_BIN="$TEST_ROOT/bin"
TMUX_SOCKET="vibe-runtime-$$"
mkdir -p "$TEST_HOME" "$TEST_PROJECT" "$TEST_BIN"
TEST_PROJECT=$(CDPATH= cd -- "$TEST_PROJECT" && pwd -P)

PROJECT_NAME=$(basename "$TEST_PROJECT" | tr '. ' '__')
PROJECT_ID=$(printf '%s' "$TEST_PROJECT" | cksum | awk '{ print $1 }')
SESSION="vibe-$PROJECT_NAME-$PROJECT_ID"

cleanup() {
  tmux kill-session -t "=$SESSION" 2>/dev/null || true
  rm -rf "$TEST_ROOT"
}
trap cleanup EXIT HUP INT TERM

ln -s "$(command -v tail)" "$TEST_BIN/claude"
ln -s "$(command -v tail)" "$TEST_BIN/opencode"
printf '#!/usr/bin/env sh\nexec "%s" -L "%s" "$@"\n' "$REAL_TMUX" "$TMUX_SOCKET" > "$TEST_BIN/tmux"
chmod +x "$TEST_BIN/tmux"

HOME="$TEST_HOME"
PATH="$TEST_BIN:$ROOT/bin:$PATH"
export HOME PATH

VIBE_NO_ATTACH=1 \
VIBE_ANIMATIONS=0 \
VIBE_FAVORITES_DIR="$TEST_HOME/favorites" \
  "$ROOT/bin/vibe" -a 'claude -f /dev/null' -a 'opencode -f /dev/null' "$TEST_PROJECT"

TRIES=0
while [ "$TRIES" -lt 300 ]; do
  [ "$(tmux show-option -qv -t "$SESSION" @vibe_ready 2>/dev/null || true)" = 1 ] && break
  TRIES=$((TRIES + 1))
  sleep 0.1
done
[ "$TRIES" -lt 300 ] || {
  printf '%s\n' 'Vibe runtime did not become ready.' >&2
  tmux list-panes -s -t "=$SESSION" -F '#{window_name} #{@vibe_role} #{pane_current_command} dead=#{pane_dead}' >&2 || true
  tmux capture-pane -p -t "=$SESSION:loading" >&2 || true
  tmux show-messages -JT >&2 || true
  exit 1
}

PANES=$(tmux list-panes -t "=$SESSION:cockpit" -F '#{@vibe_role}|#{pane_current_command}')
printf '%s\n' "$PANES" | grep -Fqx 'Claude|tail'
printf '%s\n' "$PANES" | grep -Fqx 'OpenCode|tail'
printf '%s\n' "$PANES" | grep -Eq '^Directory .*\|yazi$'
printf '%s\n' "$PANES" | grep -Fqx 'Editor|nvim'

printf '%s\n' 'Vibe multi-agent runtime check passed.'
