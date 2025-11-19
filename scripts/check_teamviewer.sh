#!/usr/bin/env bash
set -euo pipefail

if command -v teamviewer >/dev/null 2>&1; then
  if output=$(teamviewer --version 2>/dev/null); then
    first_line=""
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      first_line="$line"
      break
    done <<<"$output"
    echo "${first_line:-TeamViewer detected}"
  else
    echo "TeamViewer command detected"
  fi
  exit 0
fi

echo "TeamViewer not found"
exit 1
