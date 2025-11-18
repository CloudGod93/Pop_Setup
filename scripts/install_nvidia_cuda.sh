#!/usr/bin/env bash
set -euo pipefail

CUDA_VERSION="11.8"
CUDA_PREFIX="/usr/local/cuda-${CUDA_VERSION}"
CUDA_KEY_URL="https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb"
CUDA_KEY_DEB="/tmp/cuda-keyring.deb"
CUDNN_VERSION="8.6.0.163-1+cuda11.8"

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

install_nvidia_driver() {
  if command -v nvidia-smi >/dev/null 2>&1; then
    echo "NVIDIA driver already present"
    return
  fi

  echo "Installing NVIDIA driver"
  if grep -qi 'pop' /etc/os-release 2>/dev/null; then
    apt_exec install -y system76-driver-nvidia
  else
    sudo ubuntu-drivers autoinstall
  fi
}

install_cuda_toolkit() {
  if [[ -d "$CUDA_PREFIX" ]]; then
    echo "CUDA ${CUDA_VERSION} already installed"
    return
  fi

  echo "Downloading CUDA keyring"
  curl -fsSL "$CUDA_KEY_URL" -o "$CUDA_KEY_DEB"
  echo "Installing CUDA keyring"
  sudo dpkg -i "$CUDA_KEY_DEB"
  apt_exec update
  echo "Installing CUDA Toolkit ${CUDA_VERSION}"
  apt_exec install -y "cuda-toolkit-11-8"
  echo "Installing cuDNN ${CUDNN_VERSION}"
  apt_exec install -y \
    "libcudnn8=${CUDNN_VERSION}" \
    "libcudnn8-dev=${CUDNN_VERSION}"
  sudo apt-mark hold libcudnn8 libcudnn8-dev
}

install_nvidia_driver
install_cuda_toolkit
