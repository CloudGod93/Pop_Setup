#!/usr/bin/env bash
set -euo pipefail

if ! command -v flatpak >/dev/null 2>&1; then
  echo "Flatpak not installed"
  exit 1
fi

IFS=',' read -ra APP_LIST <<< "${FLATPAK_APPS:-com.getpostman.Postman}"
missing=()

for app in "${APP_LIST[@]}"; do
  trimmed="$(echo "$app" | xargs)"
  [[ -z "$trimmed" ]] && continue
  if ! flatpak list --app --columns=application | grep -Fx "$trimmed" >/dev/null 2>&1; then
    missing+=("$trimmed")
  fi
done

if ((${#missing[@]} == 0)); then
  echo "All configured Flatpak apps detected"
  exit 0
fi

echo "Missing Flatpak apps: ${missing[*]}"
exit 1
