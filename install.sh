#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install oh-my-posh
brew list oh-my-posh &>/dev/null || brew install oh-my-posh && echo "oh-my-posh installed"

# Install zsh-autosuggestions
brew list zsh-autosuggestions &>/dev/null || brew install zsh-autosuggestions && echo "zsh-autosuggestions installed"

# Install eza
brew list eza &>/dev/null || brew install eza && echo "eza installed"

# Install zoxide
brew list zoxide &>/dev/null || brew install zoxide && echo "zoxide installed"

if command_exists stow; then
  echo "Adding symlinks with stow..."
  stow --adopt .
fi

echo "Dotfiles installation complete!"