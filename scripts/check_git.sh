#!/usr/bin/env bash
set -euo pipefail

if command -v git >/dev/null 2>&1; then
  echo "Git already installed"
  exit 0
fi

echo "Git not found"
exit 1
