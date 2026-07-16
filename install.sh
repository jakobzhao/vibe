#!/usr/bin/env sh
set -eu

REPOSITORY=${VIBE_REPOSITORY:-https://github.com/jakobzhao/vibe.git}
INSTALL_DIR=${VIBE_INSTALL_DIR:-$HOME/.local/share/vibe}

command -v git >/dev/null 2>&1 || {
  printf '%s\n' 'Vibe installer requires Git.' >&2
  exit 1
}

if [ -d "$INSTALL_DIR/.git" ]; then
  git -C "$INSTALL_DIR" pull --ff-only
elif [ -e "$INSTALL_DIR" ]; then
  printf 'Install path already exists and is not a Git checkout: %s\n' "$INSTALL_DIR" >&2
  exit 1
else
  mkdir -p "$(dirname -- "$INSTALL_DIR")"
  git clone --depth 1 "$REPOSITORY" "$INSTALL_DIR"
fi

exec "$INSTALL_DIR/bin/install-vibe" "$@"
