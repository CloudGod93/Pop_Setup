#!/usr/bin/env bash
set -euo pipefail

wait_for_apt_lock() {
  while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || \
        fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do
    echo "Waiting for apt lock to clear..."
    sleep 5
  done
}

apt_exec() {
  wait_for_apt_lock
  sudo DEBIAN_FRONTEND=noninteractive apt-get "$@"
}

if command -v azuredatastudio >/dev/null 2>&1; then
  echo "Azure Data Studio already installed"
  exit 0
fi

AZD_URL="${AZD_URL:-https://sqlopsbuilds.azureedge.net/stable/azuredatastudio-linux-x64.deb}"
AZD_TMP="/tmp/$(basename "$AZD_URL")"

echo "Downloading Azure Data Studio from ${AZD_URL}"
apt_exec install -y curl ca-certificates
curl -L "$AZD_URL" -o "$AZD_TMP"

apt_exec install -y "$AZD_TMP"
rm -f "$AZD_TMP"

echo "Azure Data Studio installation complete"
