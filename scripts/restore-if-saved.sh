#!/usr/bin/env bash

# Auto-restore only when resurrect has a snapshot. Manual C-r restores still use
# tmux-resurrect directly, so a deliberate manual restore keeps its usual notice.
resurrect_dir="$(tmux show-option -gqv @resurrect-dir)"
resurrect_dir="${resurrect_dir:-$HOME/.tmux/resurrect}"
resurrect_dir="${resurrect_dir//\$HOME/$HOME}"
resurrect_dir="${resurrect_dir//\$HOSTNAME/$(hostname)}"
resurrect_dir="${resurrect_dir/#\~/$HOME}"

if [ -f "$resurrect_dir/last" ]; then
  exec "$HOME/.tmux/plugins/tmux-resurrect/scripts/restore.sh"
fi
