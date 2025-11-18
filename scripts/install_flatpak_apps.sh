#!/usr/bin/env bash
set -euo pipefail

if ! command -v flatpak >/dev/null 2>&1; then
  echo "Flatpak is not installed. Run the system prep script first." >&2
  exit 1
fi

IFS=',' read -ra APP_LIST <<< "${FLATPAK_APPS:-com.getpostman.Postman}"

if flatpak remotes --user | grep -q "flathub"; then
  echo "Removing user-level Flathub remote"
  flatpak remote-delete --user --force flathub || true
fi

echo "Ensuring system-level Flathub remote exists"
sudo flatpak remote-add --system --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

for app in "${APP_LIST[@]}"; do
  trimmed="$(echo "$app" | xargs)"
  [[ -z "$trimmed" ]] && continue
  echo "Installing Flatpak app: $trimmed"
  sudo flatpak install --system -y flathub "$trimmed"
done

echo "Updating all system Flatpak apps"
sudo flatpak update -y
