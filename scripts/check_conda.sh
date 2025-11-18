#!/usr/bin/env bash
set -euo pipefail

if command -v conda >/dev/null 2>&1; then
  echo "Conda already installed"
  exit 0
fi

echo "Conda not found"
exit 1
