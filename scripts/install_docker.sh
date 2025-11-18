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

if command -v docker >/dev/null 2>&1; then
  echo "Docker already installed"
else
  echo "Setting up Docker repository"
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg
  source /etc/os-release
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $VERSION_CODENAME stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  apt_exec update
  echo "Installing Docker Engine packages"
  apt_exec install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi

echo "Adding $USER to docker group"
sudo usermod -aG docker "$USER"
echo "Docker installation script completed. Open a new shell or run 'newgrp docker' to refresh group membership."
