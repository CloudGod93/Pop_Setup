#!/usr/bin/env bash
set -euo pipefail

NODE_VERSION="${NODE_VERSION:-22}"
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

if [[ ! -d "$NVM_DIR" ]]; then
  echo "Installing NVM into $NVM_DIR"
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
fi

if ! source_nvm; then
  echo "Unable to source NVM from $NVM_DIR" >&2
  exit 1
fi

nvm install "$NODE_VERSION"
nvm alias default "$NODE_VERSION"
node -v
npm -v
