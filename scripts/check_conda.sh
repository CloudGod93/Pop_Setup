#!/usr/bin/env bash
set -euo pipefail

CONDA_BIN="${CONDA_BIN:-}"
if [[ -z "$CONDA_BIN" && -x "${MINICONDA_PREFIX:-$HOME/miniconda3}/bin/conda" ]]; then
  CONDA_BIN="${MINICONDA_PREFIX:-$HOME/miniconda3}/bin/conda"
fi

if [[ -z "$CONDA_BIN" ]]; then
  if command -v conda >/dev/null 2>&1; then
    CONDA_BIN="$(command -v conda)"
  fi
fi

if [[ -n "$CONDA_BIN" ]]; then
  "$CONDA_BIN" --version
  exit 0
fi

echo "Conda not detected"
exit 1
