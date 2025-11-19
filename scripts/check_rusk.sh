#!/usr/bin/env bash
set -euo pipefail

if command -v rustdesk >/dev/null 2>&1; then
  rustdesk --version 2>/dev/null | head -n 1 || echo "rustdesk command present"
  exit 0
fi

echo "Rusk (rustdesk) not found"
exit 1
