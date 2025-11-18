#!/usr/bin/env bash
set -euo pipefail

if ! command -v git >/dev/null 2>&1; then
  echo "Git not installed"
  exit 1
fi

NAME=$(git config --global user.name || true)
EMAIL=$(git config --global user.email || true)

if [[ -z "$NAME" || -z "$EMAIL" ]]; then
  echo "Git identity not fully configured"
  exit 1
fi

echo "Git configured for $NAME <$EMAIL>"
exit 0
