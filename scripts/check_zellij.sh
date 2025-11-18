#!/usr/bin/env bash
set -euo pipefail

if command -v zellij >/dev/null 2>&1; then
  zellij --version
  exit 0
fi

echo "Zellij not found"
exit 1
