#!/usr/bin/env bash
set -euo pipefail

if dpkg -s thonny >/dev/null 2>&1; then
  version=$(dpkg -s thonny | awk -F': ' '/Version/{print $2; exit}')
  if [[ -n "$version" ]]; then
    echo "Thonny package installed (version $version)"
  else
    echo "Thonny package installed"
  fi
  exit 0
fi

if command -v thonny >/dev/null 2>&1; then
  echo "Thonny executable found at $(command -v thonny)"
  exit 0
fi

echo "Thonny not found"
exit 1
