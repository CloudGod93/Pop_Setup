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

if command -v teamviewer >/dev/null 2>&1; then
  echo "TeamViewer already installed"
  exit 0
fi

DEB_PATH="/tmp/teamviewer_amd64.deb"
wget -O "$DEB_PATH" https://download.teamviewer.com/download/linux/teamviewer_amd64.deb
apt_exec install -y "$DEB_PATH"
rm -f "$DEB_PATH"
