#!/usr/bin/env bash
set -euo pipefail

if command -v ventoy >/dev/null 2>&1; then
  echo "Ventoy command available"
  exit 0
fi

echo "Ventoy not found"
exit 1
