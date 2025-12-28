#!/bin/bash
set -euo pipefail

# Helper function
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# =============================================================================
# Homebrew
# =============================================================================
echo ""
echo "=== Homebrew ==="

if ! command_exists brew; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Set up PATH for this session (needed on Linux and Apple Silicon)
  if [[ -f /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  elif [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
else
  echo "Homebrew already installed"
fi

# =============================================================================
# Zsh
# =============================================================================
echo ""
echo "=== Zsh ==="

if ! command_exists zsh; then
  echo "Installing zsh..."
  if command_exists apt-get; then
    sudo apt-get update
    sudo apt-get install -y zsh
  elif command_exists brew; then
    brew install zsh
  else
    echo "Error: Unable to install zsh. Please install it manually."
    exit 1
  fi
else
  echo "Zsh already installed"
fi

if [[ "$SHELL" != *"zsh"* ]]; then
  echo "Setting zsh as default shell..."
  chsh -s "$(which zsh)"
else
  echo "Zsh is already the default shell"
fi

# =============================================================================
# Stow
# =============================================================================
echo ""
echo "=== Stow ==="

if ! command_exists stow; then
  echo "Installing stow..."
  if command_exists apt-get; then
    sudo apt-get update
    sudo apt-get install -y stow
  elif command_exists brew; then
    brew install stow
  else
    echo "Error: Unable to install stow. Please install it manually."
    exit 1
  fi
else
  echo "Stow already installed"
fi

# =============================================================================
# NVM (Node Version Manager)
# =============================================================================
echo ""
echo "=== NVM ==="

if [[ ! -d "$HOME/.nvm" ]]; then
  echo "Installing NVM..."
  /bin/bash -c "$(curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh)"
else
  echo "NVM already installed"
fi

# =============================================================================
# PNPM
# =============================================================================
echo ""
echo "=== PNPM ==="

if ! command_exists pnpm; then
  echo "Installing PNPM..."
  curl -fsSL https://get.pnpm.io/install.sh | ENV="$HOME/.zshrc" SHELL="$(which zsh)" sh -
else
  echo "PNPM already installed"
fi

# =============================================================================
# Done
# =============================================================================
echo ""
echo "=== Setup complete ==="
echo "Run ./install.sh to install packages and apply dotfiles"
