#!/usr/bin/env bash
set -euo pipefail

if command -v docker >/dev/null 2>&1; then
  docker --version
  exit 0
fi

echo "Docker not found"
exit 1
