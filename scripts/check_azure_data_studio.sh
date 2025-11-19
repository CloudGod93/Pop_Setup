#!/usr/bin/env bash
set -euo pipefail

candidates=(
  azuredatastudio
  azure-data-studio
  azure-data-studio-insiders
)

for pkg in "${candidates[@]}"; do
  if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q 'install ok installed'; then
    version=$(dpkg-query -W -f='${Version}' "$pkg" 2>/dev/null || true)
    if [[ -n "$version" ]]; then
      echo "Azure Data Studio ${version}"
    else
      echo "Azure Data Studio installed"
    fi
    exit 0
  fi
done

if command -v azuredatastudio >/dev/null 2>&1; then
  echo "Azure Data Studio command detected"
  exit 0
fi

echo "Azure Data Studio not found"
exit 1
