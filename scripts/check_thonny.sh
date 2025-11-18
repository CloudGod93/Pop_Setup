#!/usr/bin/env bash
set -euo pipefail

if command -v thonny >/dev/null 2>&1; then
  thonny --version || true
  echo "Thonny detected"
  exit 0
fi

echo "Thonny not found"
exit 1
