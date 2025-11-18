#!/usr/bin/env bash
set -euo pipefail

if command -v code >/dev/null 2>&1; then
  code --version | head -n 1
  exit 0
fi

echo "VS Code not found"
exit 1
