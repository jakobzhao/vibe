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

if find "$ROOT" -type f -not -path "$ROOT/.git/*" -not -path "$ROOT/tests/check.sh" -not -name README.md \
  -exec grep -En '/Users/|locaphilia|jakobzhao@gmail|GoogleDrive-' {} +; then
  printf '%s\n' 'Personal path or identifier found.' >&2
  exit 1
fi

printf '%s\n' 'Vibe checks passed.'
