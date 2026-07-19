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

ln -s "$(command -v tail)" "$TEST_BIN/opencode"
printf '#!/usr/bin/env sh\nprintf "Do you trust the contents\\n"\nexec tail -f /dev/null\n' > "$TEST_BIN/codex"
printf '#!/usr/bin/env sh\nexec "%s" -L "%s" -f "%s" "$@"\n' \
  "$REAL_TMUX" "$TMUX_SOCKET" "$ROOT/tmux.conf" > "$TEST_BIN/tmux"
chmod +x "$TEST_BIN/codex" "$TEST_BIN/tmux"

HOME="$TEST_HOME"
PATH="$TEST_BIN:$ROOT/bin:$PATH"
export HOME PATH

VIBE_NO_ATTACH=1 \
VIBE_ANIMATIONS=0 \
  "$ROOT/bin/vibe" -a codex -a 'opencode -f /dev/null' "$TEST_PROJECT"

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
printf '%s\n' "$PANES" | grep -Eq '^Agent\|0\|.+$'
printf '%s\n' "$PANES" | grep -Eq '^OpenCode\|0\|.+$'
printf '%s\n' "$PANES" | grep -Fqx 'Explorer|0|yazi'
! printf '%s\n' "$PANES" | grep -Eq '^Shell\|'
printf '%s\n' "$PANES" | grep -Fqx 'Editor|0|nvim'
[ "$(tmux show-option -qv -t "$SESSION" status)" = off ]

COCKPIT_WINDOW=$(tmux show-option -qv -t "$SESSION" @vibe_cockpit_window)
DIRECTORY_PANE=$(tmux show-option -qv -t "$SESSION" @vibe_directory_pane)
SHELL_PANE=$(tmux show-option -qv -t "$SESSION" @vibe_shell_pane)
[ -n "$COCKPIT_WINDOW" ] && [ -n "$DIRECTORY_PANE" ] && [ -n "$SHELL_PANE" ]
[ "$(tmux display-message -p -t "$DIRECTORY_PANE" '#{window_id}')" = "$COCKPIT_WINDOW" ]
[ "$(tmux display-message -p -t "$SHELL_PANE" '#{window_id}')" != "$COCKPIT_WINDOW" ]
[ "$(tmux show-option -pqv -t "$DIRECTORY_PANE" @vibe_tab_kind)" = directory ]
[ "$(tmux show-option -pqv -t "$SHELL_PANE" @vibe_tab_kind)" = shell ]
[ "$(tmux show-option -pqv -t "$DIRECTORY_PANE" @vibe_tab_helper)" = "$ROOT/bin/vibe-tab" ]
[ "$(tmux show-option -pqv -t "$SHELL_PANE" @vibe_tab_helper)" = "$ROOT/bin/vibe-tab" ]
BORDER=$(tmux display-message -p -t "$DIRECTORY_PANE" '#{E:pane-border-format}')
printf '%s\n' "$BORDER" | grep -Fq Shell
printf '%s\n' "$BORDER" | grep -Fq Explorer

DIRECTORY_PID=$(tmux display-message -p -t "$DIRECTORY_PANE" '#{pane_pid}')
SHELL_PID=$(tmux display-message -p -t "$SHELL_PANE" '#{pane_pid}')
DIRECTORY_LEFT=$(tmux display-message -p -t "$DIRECTORY_PANE" '#{pane_left}')
DIRECTORY_TOP=$(tmux display-message -p -t "$DIRECTORY_PANE" '#{pane_top}')
tmux run-shell -t "$DIRECTORY_PANE" \
  "\"#{@vibe_tab_helper}\" mouse-pane \"#{session_name}\" \"$((DIRECTORY_LEFT + 4))\" \"$DIRECTORY_LEFT\" \"$((DIRECTORY_TOP - 1))\" \"$DIRECTORY_TOP\" \"#{pane_id}\""
[ "$(tmux display-message -p -t "$SHELL_PANE" '#{window_id}')" = "$COCKPIT_WINDOW" ]
[ "$(tmux display-message -p -t "$DIRECTORY_PANE" '#{window_id}')" != "$COCKPIT_WINDOW" ]
SWITCHED_PANES=$(tmux list-panes -t "$COCKPIT_WINDOW" -F '#{@vibe_role}')
printf '%s\n' "$SWITCHED_PANES" | grep -Fqx Shell
! printf '%s\n' "$SWITCHED_PANES" | grep -Fqx Explorer

SHELL_LEFT=$(tmux display-message -p -t "$SHELL_PANE" '#{pane_left}')
tmux run-shell -t "$SHELL_PANE" \
  "\"#{@vibe_tab_helper}\" mouse \"#{session_name}\" \"$((SHELL_LEFT + 12))\" \"$SHELL_LEFT\" \"#{pane_id}\""
[ "$(tmux display-message -p -t "$DIRECTORY_PANE" '#{window_id}')" = "$COCKPIT_WINDOW" ]
[ "$(tmux display-message -p -t "$SHELL_PANE" '#{window_id}')" != "$COCKPIT_WINDOW" ]
[ "$(tmux display-message -p -t "$DIRECTORY_PANE" '#{pane_pid}')" = "$DIRECTORY_PID" ]
[ "$(tmux display-message -p -t "$SHELL_PANE" '#{pane_pid}')" = "$SHELL_PID" ]

printf '%s\n' 'Vibe multi-agent runtime check passed.'
