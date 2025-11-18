#!/usr/bin/env bash
set -euo pipefail

RIBBING_APP_PARENT="${RIBBING_APP_PARENT:-$HOME/Documents/Projects/RibbingApp}"
V1_DIR="${V1_DIR:-$RIBBING_APP_PARENT/app/v1}"
V2_DIR="${V2_DIR:-$RIBBING_APP_PARENT/app/v2}"
CC_PARENT="${CC_PARENT:-$HOME/Documents/Projects/CattleClassificationApp}"
CC_DIR="${CC_DIR:-$CC_PARENT/app}"

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

source_nvm() {
  if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    # shellcheck disable=SC1090
    . "$NVM_DIR/nvm.sh"
    if [[ -s "$NVM_DIR/bash_completion" ]]; then
      # shellcheck disable=SC1090
      . "$NVM_DIR/bash_completion"
    fi
    return 0
  fi
  return 1
}

resolve_conda_bin() {
  if [[ -n "${CONDA_BIN:-}" && -x "$CONDA_BIN" ]]; then
    echo "$CONDA_BIN"
    return
  fi
  if [[ -x "${MINICONDA_PREFIX:-$HOME/miniconda3}/bin/conda" ]]; then
    echo "${MINICONDA_PREFIX:-$HOME/miniconda3}/bin/conda"
    return
  fi
  if command -v conda >/dev/null 2>&1; then
    command -v conda
    return
  fi
  echo "" 
}

run_npm_install() {
  local dir="$1"
  if [[ ! -f "$dir/package.json" ]]; then
    return
  fi
  if source_nvm; then
    echo "Running npm install in $dir"
    (cd "$dir" && npm install)
  else
    echo "NVM not available; skipping npm install in $dir" >&2
  fi
}

apply_conda_env() {
  local file="$1"
  local conda_bin="$2"
  if [[ -f "$file" ]]; then
    echo "Applying conda environment from $file"
    "$conda_bin" env create -f "$file" || "$conda_bin" env update -f "$file" --prune
  fi
}

run_npm_install "$V2_DIR/client"

CONDA_BIN_PATH="$(resolve_conda_bin)"
if [[ -n "$CONDA_BIN_PATH" ]]; then
  apply_conda_env "$V2_DIR/server/environment.yml" "$CONDA_BIN_PATH"
  apply_conda_env "$V1_DIR/environment.yml" "$CONDA_BIN_PATH"
  apply_conda_env "$CC_DIR/environment.yml" "$CONDA_BIN_PATH"
else
  echo "Conda not available; skipping environment creation" >&2
fi
