#!/usr/bin/env bash
set -euo pipefail

MINICONDA_PREFIX="${MINICONDA_PREFIX:-$HOME/miniconda3}"
INSTALLER_URL="${MINICONDA_INSTALLER_URL:-https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh}"
INSTALLER_PATH="/tmp/miniconda.sh"

if [[ ! -d "$MINICONDA_PREFIX" ]]; then
  echo "Downloading Miniconda installer"
  curl -fsSL "$INSTALLER_URL" -o "$INSTALLER_PATH"
  echo "Installing Miniconda to $MINICONDA_PREFIX"
  bash "$INSTALLER_PATH" -b -p "$MINICONDA_PREFIX"
fi

CONDA_BIN="$MINICONDA_PREFIX/bin/conda"
if [[ ! -x "$CONDA_BIN" ]]; then
  echo "Conda binary not found in $MINICONDA_PREFIX" >&2
  exit 1
fi

# shellcheck disable=SC1090
eval "$("$CONDA_BIN" 'shell.bash' 'hook')"

"$CONDA_BIN" init bash || true
if command -v zsh >/dev/null 2>&1 && [[ -f "$HOME/.zshrc" ]]; then
  "$CONDA_BIN" init zsh || true
fi

export CONDA_ALWAYS_YES=true
"$CONDA_BIN" --version
"$CONDA_BIN" tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main
"$CONDA_BIN" tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r
