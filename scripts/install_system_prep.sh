#!/usr/bin/env bash
set -euo pipefail

TEAMVIEWER_SOURCE="/etc/apt/sources.list.d/teamviewer.list"
BASE_PACKAGES=(
  git
  curl
  wget
  ca-certificates
  gnupg
  lsb-release
  build-essential
  unzip
  flatpak
  alacritty
  rsync
  sed
)

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

if [[ -f "$TEAMVIEWER_SOURCE" ]]; then
  echo "Removing stale TeamViewer source: $TEAMVIEWER_SOURCE"
  sudo rm -f "$TEAMVIEWER_SOURCE"
fi

echo "Updating apt package lists"
apt_exec update -y

echo "Upgrading base system packages"
apt_exec dist-upgrade -y

echo "Removing conflicting system nodejs/npm packages"
apt_exec remove --purge -y nodejs npm || true

if ((${#BASE_PACKAGES[@]} > 0)); then
  echo "Installing core CLI and GUI packages: ${BASE_PACKAGES[*]}"
  apt_exec install -y "${BASE_PACKAGES[@]}"
fi
