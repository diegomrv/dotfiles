#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check and install zsh if not present
if ! command_exists zsh; then
    echo "zsh is not installed. Attempting to install..."
    if command_exists apt-get; then
        sudo apt-get update
        sudo apt-get install -y zsh
    elif command_exists brew; then
        brew install zsh
    elif command_exists dnf; then
        sudo dnf install -y zsh
    elif command_exists yum; then
        sudo yum install -y zsh
    else
        echo "Unable to install zsh. Please install it manually."
        exit 1
    fi
fi

DOTFILES_DIR="$HOME/dotfiles"
FILES=".vimrc .vim .zshrc .hunk-mod.omp.json .fonts .aliases"    # list of files/folders to symlink in homedir

# Create symlinks
for FILE in $FILES; do
    echo "Creating symlink to $FILE in home directory."
    ln -s $DOTFILES_DIR/$FILE $HOME/$FILE
done

# Create zsh directory if it doesn't exist
mkdir -p $HOME/.zsh

platform=$(uname);

# Symlink system-specific zsh file
if [[ $platform == "Darwin" ]]; then
    ln -sf $DOTFILES_DIR/zsh/macos.zsh $HOME/.zsh/system_specific.zsh
elif [[ $platform == "Linux" ]]; then
    ln -sf $DOTFILES_DIR/zsh/ubuntu.zsh $HOME/.zsh/system_specific.zsh
else
    echo "Unsupported operating system"
    exit 1
fi

echo "Dotfiles installation complete!"

# Optionally, set zsh as the default shell
if [[ "$SHELL" != *"zsh"* ]]; then
    echo "Changing default shell to zsh..."
    chsh -s $(which zsh)
fi
