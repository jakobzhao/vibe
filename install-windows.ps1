$ErrorActionPreference = "Stop"

if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) {
    throw "Vibe requires WSL2 on Windows. Run 'wsl --install -d Ubuntu', restart Windows, and try again."
}

$installCommand = @'
set -eu
if ! command -v curl >/dev/null 2>&1 || ! command -v git >/dev/null 2>&1; then
  printf '%s\n' 'Install prerequisites first: sudo apt-get update && sudo apt-get install -y curl git' >&2
  exit 1
fi
installer=$(mktemp "${TMPDIR:-/tmp}/vibe-install.XXXXXX")
trap 'rm -f "$installer"' EXIT HUP INT TERM
curl -fsSL https://raw.githubusercontent.com/jakobzhao/vibe/main/install.sh -o "$installer"
sh "$installer" --no-ghostty
'@

& wsl.exe sh -lc $installCommand
if ($LASTEXITCODE -ne 0) {
    throw "Vibe installation in WSL failed with exit code $LASTEXITCODE."
}

Write-Host "Vibe is installed inside WSL. Open Ubuntu and run: vibe"
