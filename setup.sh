#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install brew if not present
if ! command_exists brew; then
    echo "Homebrew is not installed. Attempting to install..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Check and install zsh if not present
if ! command_exists zsh; then
    echo "zsh is not installed. Attempting to install..."
    if command_exists apt-get; then
        sudo apt-get update
        sudo apt-get install -y zsh
    elif command_exists brew; then
        brew install zsh
    else
        echo "Unable to install zsh. Please install it manually."
        exit 1
    fi
fi

# Set zsh as the default shell
if [[ "$SHELL" != *"zsh"* ]]; then
    echo "Changing default shell to zsh..."
    chsh -s $(which zsh)
fi

# Check and install stow if not present
if ! command_exists stow; then
    echo "stow is not installed. Attempting to install..."
    if command_exists apt-get; then
        sudo apt-get update
        sudo apt-get install -y stow
    elif command_exists brew; then
        brew install stow
    else
        echo "Unable to install stow. Please install it manually."
        exit 1
    fi
fi

if ! command_exists nvm; then
  echo "NVM not installed. Attempting to install..."
  /bin/bash -c "$(curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh)"
fi

echo "Run install.sh after this!"