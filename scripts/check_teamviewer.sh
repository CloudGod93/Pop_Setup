#!/usr/bin/env bash
set -euo pipefail

if command -v teamviewer >/dev/null 2>&1; then
  teamviewer --version | head -n 1
  exit 0
fi

echo "TeamViewer not found"
exit 1
