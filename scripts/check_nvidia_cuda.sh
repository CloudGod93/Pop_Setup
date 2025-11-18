#!/usr/bin/env bash
set -euo pipefail

if ! command -v nvidia-smi >/dev/null 2>&1; then
  echo "nvidia-smi not found"
  exit 1
fi

if ! command -v nvcc >/dev/null 2>&1 && [[ ! -d /usr/local/cuda-11.8 ]]; then
  echo "CUDA 11.8 not detected"
  exit 1
fi

echo "NVIDIA driver and CUDA appear to be installed"
exit 0
