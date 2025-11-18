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

if command -v google-chrome-stable >/dev/null 2>&1; then
  echo "Google Chrome already installed"
  exit 0
fi

sudo install -m 0755 -d /usr/share/keyrings
curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | \
  sudo gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg

cat <<'REPO' | sudo tee /etc/apt/sources.list.d/google-chrome.list >/dev/null
deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main
REPO

apt_exec update
apt_exec install -y google-chrome-stable
