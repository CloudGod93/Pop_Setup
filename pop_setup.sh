#!/usr/bin/env bash
# Fail on first error, on unset variables, and on pipeline errors
set -euo pipefail

# systemctl reboot --firmware-setup

# ==============================================================================
# 1. SYSTEM PREP & APT PACKAGE INSTALLATION
# ==============================================================================
echo "▶️ Starting initial system update and APT package installation..."
sudo apt update
sudo apt upgrade -y

# Install prerequisite packages and core applications from APT repositories
sudo apt install -y \
  git \
  alacritty \
  notepadqq \
  curl \
  wget \
  gpg \
  ca-certificates \
  gnupg \
  lsb-release \
  software-properties-common \
  apt-transport-https

# ==============================================================================
# 2. ADD EXTERNAL REPOSITORIES (VS Code & CUDA)
# ==============================================================================
echo "▶️ Adding external APT repositories for VS Code and CUDA..."

# --- VS Code Repository ---
# Add the Microsoft GPG key
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /usr/share/keyrings/packages.microsoft.gpg > /dev/null
# Add the repository configuration
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" | sudo tee /etc/apt/sources.list.d/vscode.list

# --- CUDA Toolkit 11.8 Repository ---
# Download and install the NVIDIA CUDA repository key
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
rm cuda-keyring_1.1-1_all.deb # Cleanup

# Refresh package list after adding new repositories
sudo apt update

# ==============================================================================
# 3. INSTALL APPLICATIONS FROM REPOSITORIES (APT & FLATPAK)
# ==============================================================================
echo "▶️ Installing applications from APT and Flatpak..."

# --- APT Installations (VS Code, CUDA, cuDNN) ---
sudo apt install -y code cuda-toolkit-11-8

# Install specific cuDNN version and hold it to prevent automatic upgrades
sudo apt install -y \
  libcudnn8=8.6.0.163-1+cuda11.8 \
  libcudnn8-dev=8.6.0.163-1+cuda11.8
sudo apt-mark hold libcudnn8 libcudnn8-dev

# --- Flatpak Installations ---
flatpak install -y flathub com.getpostman.Postman com.notepadqq.NotepadqqWine

# ==============================================================================
# 4. INSTALL .DEB PACKAGES (CHROME, TEAMVIEWER, DOCKER)
# ==============================================================================
echo "▶️ Downloading and installing .deb packages..."
# Change to Downloads directory for downloaded files
cd ~/Downloads

# --- Downloads ---
wget -O google-chrome-stable_current_amd64.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
wget -O teamviewer_amd64.deb https://download.teamviewer.com/download/linux/teamviewer_amd64.deb
wget -O docker-desktop-amd64.deb https://desktop.docker.com/linux/main/amd64/docker-desktop-amd64.deb

# --- Installations (apt handles dependencies) ---
sudo apt install -y ./google-chrome-stable_current_amd64.deb
sudo apt install -y ./teamviewer_amd64.deb
sudo apt install -y ./docker-desktop-amd64.deb

# --- Cleanup ---
rm google-chrome-stable_current_amd64.deb teamviewer_amd64.deb docker-desktop-amd64.deb
cd ~ # Return to home directory

# ==============================================================================
# 5. CONFIGURE DEVELOPMENT TOOLS (GIT, NVM, MINICONDA, CUDA)
# ==============================================================================
echo "▶️ Configuring development tools..."

# --- Git Configuration ---
git config --global user.name "CloudGod93"
git config --global user.email "jtingley2021@gmail.com"
git config --global credential.helper store # Warning: saves credentials in plaintext
git config --global push.autoSetupRemote true

# --- NVM (Node Version Manager) Installation ---
LATEST_NVM_VERSION=$(curl -s "https://api.github.com/repos/nvm-sh/nvm/releases/latest" | grep -oP '"tag_name": "\K(.*)(?=")')
echo "Installing NVM version ${LATEST_NVM_VERSION}..."
curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${LATEST_NVM_VERSION}/install.sh" | bash
# Source NVM for the current script session
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
# Install Node.js v22 and set as default
nvm install 22
nvm alias default 22

# --- Miniconda Installation ---
curl -O https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh -b -p "$HOME/miniconda3"
rm Miniconda3-latest-Linux-x86_64.sh
# Initialize conda (adds setup to ~/.bashrc)
"$HOME/miniconda3/bin/conda" init bash

# --- CUDA Environment Variables ---
# Add CUDA paths to ~/.bashrc if they don't already exist
BASHRC_FILE="$HOME/.bashrc"
CUDA_PATH_LINE='export PATH=/usr/local/cuda-11.8/bin:${PATH}'
CUDA_LIB_LINE='export LD_LIBRARY_PATH=/usr/local/cuda-11.8/lib64:${LD_LIBRARY_PATH}'
grep -qF -- "$CUDA_PATH_LINE" "$BASHRC_FILE" || echo "$CUDA_PATH_LINE" >> "$BASHRC_FILE"
grep -qF -- "$CUDA_LIB_LINE" "$BASHRC_FILE" || echo "$CUDA_LIB_LINE" >> "$BASHRC_FILE"

# --- Docker Post-install ---
# Enable the Docker Desktop user service
systemctl --user daemon-reload
systemctl --user enable --now docker-desktop

# ==============================================================================
# 6. FINALIZATION
# ==============================================================================
# Apply all .bashrc changes to the current shell
source "$HOME/.bashrc"

echo ""
echo "======================================================================="
echo "✅ ALL INSTALLATIONS COMPLETE."
echo "You should now have:"
echo "  - Core Apps: VS Code, Postman, Alacritty, Notepad++, Chrome, TeamViewer"
echo "  - Dev Tools: Git, Docker Desktop, Miniconda, Node.js (via NVM)"
echo "  - ML Libs:   CUDA 11.8 & cuDNN 8.6"
echo ""
echo "To verify installations, try:"
echo "  - node -v"
echo "  - conda --version"
echo "  - docker --version"
echo "  - nvcc --version"
echo ""
echo "❗️ A system reboot is recommended for all changes to take full effect."
echo "======================================================================="