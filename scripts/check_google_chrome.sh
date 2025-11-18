#!/usr/bin/env bash
set -euo pipefail

if command -v google-chrome-stable >/dev/null 2>&1; then
  google-chrome-stable --version
  exit 0
fi

echo "Google Chrome not found"
exit 1
