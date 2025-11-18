#!/usr/bin/env bash
set -euo pipefail

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  # shellcheck disable=SC1090
  . "$NVM_DIR/nvm.sh"
fi

if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
  node -v
  npm -v
  exit 0
fi

echo "Node.js via NVM not detected"
exit 1
