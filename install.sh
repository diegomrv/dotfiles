#!/bin/bash
set -euo pipefail

# =============================================================================
# Preflight check
# =============================================================================
if ! command -v brew &>/dev/null; then
  echo "Error: Homebrew not found. Run ./setup.sh first."
  exit 1
fi

# =============================================================================
# Brew packages
# =============================================================================
echo ""
echo "=== Installing Homebrew packages ==="

PACKAGES=(
  oh-my-posh
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-completions
  eza
  zoxide
  neovim
  fastfetch
  ffmpeg
)

for pkg in "${PACKAGES[@]}"; do
  if brew list "$pkg" &>/dev/null; then
    echo "$pkg already installed"
  else
    echo "Installing $pkg..."
    brew install "$pkg"
  fi
done

# =============================================================================
# Stow dotfiles
# =============================================================================
echo ""
echo "=== Applying dotfiles with Stow ==="

if command -v stow &>/dev/null; then
  stow --adopt .
  echo "Symlinks created"
else
  echo "Warning: stow not found, skipping dotfiles linking"
fi

# =============================================================================
# Done
# =============================================================================
echo ""
echo "=== Installation complete ==="
echo "Restart your terminal or run: source ~/.zshrc"
