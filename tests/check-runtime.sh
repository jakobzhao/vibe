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
SMALL_SESSION=
mkdir -p "$TEST_HOME" "$TEST_PROJECT" "$TEST_BIN"
TEST_PROJECT=$(CDPATH= cd -- "$TEST_PROJECT" && pwd -P)
CONTEXT_ITEM="$TEST_PROJECT/file with space.txt"
printf '%s\n' context > "$CONTEXT_ITEM"

PROJECT_NAME=$(basename "$TEST_PROJECT" | tr '. ' '__')
PROJECT_ID=$(printf '%s' "$TEST_PROJECT" | cksum | awk '{ print $1 }')
SESSION="vibe-$PROJECT_NAME-$PROJECT_ID"

cleanup() {
  tmux kill-session -t "=$SESSION" 2>/dev/null || true
  if [ -n "$SMALL_SESSION" ]; then
    tmux kill-session -t "=$SMALL_SESSION" 2>/dev/null || true
  fi
  rm -rf "$TEST_ROOT"
}
trap cleanup EXIT HUP INT TERM

ln -s "$(command -v tail)" "$TEST_BIN/claude"
ln -s "$(command -v tail)" "$TEST_BIN/opencode"
printf '#!/usr/bin/env sh\nexec "%s" -L "%s" -f "%s" "$@"\n' \
  "$REAL_TMUX" "$TMUX_SOCKET" "$ROOT/tmux.conf" > "$TEST_BIN/tmux"
chmod +x "$TEST_BIN/tmux"

HOME="$TEST_HOME"
PATH="$TEST_BIN:$ROOT/bin:$PATH"
export HOME PATH

VIBE_NO_ATTACH=1 \
VIBE_ANIMATIONS=0 \
VIBE_FAVORITES_DIR="$TEST_HOME/favorites" \
  COLUMNS=140 LINES=40 \
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

PANES=$(tmux list-panes -t "=$SESSION:cockpit" -F '#{@vibe_role}|#{pane_dead}|#{pane_current_command}')
printf '%s\n' "$PANES" | grep -Eq '^Claude\|0\|.+$'
printf '%s\n' "$PANES" | grep -Fqx 'Directory|0|yazi'
printf '%s\n' "$PANES" | grep -Fqx 'Editor|0|nvim'
[ "$(printf '%s\n' "$PANES" | wc -l | tr -d ' ')" -eq 3 ]
tmux list-panes -s -t "=$SESSION" -F '#{@vibe_role}|#{pane_dead}|#{pane_current_command}' |
  grep -Eq '^OpenCode\|0\|.+$'
tmux show-hooks -g pane-focus-in | grep -Fq '@vibe_active_agent'
[ "$(tmux show-option -qv -t "$SESSION" status)" = on ]

DIRECTORY_PANE=$(tmux show-option -qv -t "$SESSION" @vibe_directory_pane)
VIBE_DIRECTORY_PANE="$DIRECTORY_PANE" \
VIBE_FAVORITES_DIR="$TEST_HOME/favorites" \
  "$ROOT/bin/vibe-favorite" title favorites
[ "$(tmux show-option -pqv -t "$DIRECTORY_PANE" @vibe_role)" = Favorites ]
VIBE_DIRECTORY_PANE="$DIRECTORY_PANE" \
VIBE_FAVORITES_DIR="$TEST_HOME/favorites" \
  "$ROOT/bin/vibe-favorite" title directory
[ "$(tmux show-option -pqv -t "$DIRECTORY_PANE" @vibe_role)" = Directory ]

TMUX_PANE="$DIRECTORY_PANE" "$ROOT/bin/vibe-layout" directory
[ "$(tmux display-message -p -t "$DIRECTORY_PANE" '#{window_name}')" = directory ]
TMUX_PANE="$DIRECTORY_PANE" "$ROOT/bin/vibe-layout" directory
[ "$(tmux display-message -p -t "$DIRECTORY_PANE" '#{window_name}')" = cockpit ]

CONTEXT_FILE="$TEST_HOME/context"
TMUX_PANE="$DIRECTORY_PANE" VIBE_CONTEXT_FILE="$CONTEXT_FILE" VIBE_PROJECT_DIR="$TEST_PROJECT" \
  "$ROOT/bin/vibe-context" add "$CONTEXT_ITEM" >/dev/null
[ "$(tmux show-option -qv -t "$SESSION" @vibe_context_count)" = 1 ]
grep -Fqx 'file with space.txt' "$CONTEXT_FILE"
TMUX_PANE="$DIRECTORY_PANE" VIBE_CONTEXT_FILE="$CONTEXT_FILE" VIBE_PROJECT_DIR="$TEST_PROJECT" \
  "$ROOT/bin/vibe-context" send

TEST_SMALL_PROJECT="$TEST_ROOT/small-project"
mkdir -p "$TEST_SMALL_PROJECT"
TEST_SMALL_PROJECT=$(CDPATH= cd -- "$TEST_SMALL_PROJECT" && pwd -P)
SMALL_ID=$(printf '%s' "$TEST_SMALL_PROJECT" | cksum | awk '{ print $1 }')
SMALL_SESSION="vibe-small-project-$SMALL_ID"
VIBE_NO_ATTACH=1 \
VIBE_ANIMATIONS=0 \
VIBE_FAVORITES_DIR="$TEST_HOME/favorites" \
  COLUMNS=90 LINES=28 \
  "$ROOT/bin/vibe" -a 'claude -f /dev/null' "$TEST_SMALL_PROJECT"

TRIES=0
while [ "$TRIES" -lt 300 ]; do
  [ "$(tmux show-option -qv -t "$SMALL_SESSION" @vibe_ready 2>/dev/null || true)" = 1 ] && break
  TRIES=$((TRIES + 1))
  sleep 0.1
done
[ "$TRIES" -lt 300 ] || { printf '%s\n' 'Narrow Vibe runtime did not become ready.' >&2; exit 1; }
[ "$(tmux list-panes -t "=$SMALL_SESSION:cockpit" -F '#{pane_id}' | wc -l | tr -d ' ')" -eq 2 ]
SMALL_DIRECTORY=$(tmux show-option -qv -t "$SMALL_SESSION" @vibe_directory_pane)
[ "$(tmux display-message -p -t "$SMALL_DIRECTORY" '#{window_name}')" = directory ]

printf '%s\n' 'Vibe multi-agent runtime check passed.'
