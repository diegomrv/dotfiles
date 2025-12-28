# Source system-specific file
if [[ $(uname) == "Darwin" ]]; then
    source "$HOME/.zsh/macos.zsh"
elif [[ $(uname) == "Linux" ]]; then
    source "$HOME/.zsh/ubuntu.zsh"
else
    echo "Unsupported operating system"
    exit 1
fi

# History file configuration
[ -z "$HISTFILE" ] && HISTFILE="$HOME/.zsh_history"
[ "$HISTSIZE" -lt 50000 ] && HISTSIZE=50000
[ "$SAVEHIST" -lt 10000 ] && SAVEHIST=10000

export EDITOR='nvim'

# Initialize zsh completion system with additional completions
if command -v brew >/dev/null 2>&1; then
  FPATH=$(brew --prefix)/share/zsh-completions:$FPATH
fi
autoload -Uz compinit && compinit

source ~/.aliases

if command -v brew >/dev/null 2>&1; then
  # Autosuggestions: use history first, then completion (like fish)
  export ZSH_AUTOSUGGEST_STRATEGY=(history completion)
  source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  # Syntax highlighting must be sourced last
  source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# Only init zoxide in interactive shells (prevents errors in scripts/subshells)
if [[ $- == *i* ]]; then
  eval "$(zoxide init --cmd cd zsh)"
fi

# Additional PATH entries
export PATH="$HOME/.local/bin:$PATH"         # CodeRabbit CLI, pipx, etc.
export PATH="$PATH:$HOME/.lmstudio/bin"      # LM Studio CLI

# Source custom functions
[[ -f "$HOME/.zsh/functions/video.zsh" ]] && source "$HOME/.zsh/functions/video.zsh"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# place this after nvm initialization!
autoload -U add-zsh-hook

load-nvmrc() {
  local nvmrc_path
  nvmrc_path="$(nvm_find_nvmrc)"

  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version
    nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
    elif [ "$nvmrc_node_version" != "$(nvm version)" ]; then
      nvm use
    fi
  elif [ -n "$(PWD=$OLDPWD nvm_find_nvmrc)" ] && [ "$(nvm version)" != "$(nvm version default)" ]; then
    echo "Reverting to nvm default version"
    nvm use default
  fi
}

add-zsh-hook chpwd load-nvmrc
load-nvmrc

# Source machine-local config (for Herd, etc.)
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

fastfetch


# Herd injected PHP 8.4 configuration.
export HERD_PHP_84_INI_SCAN_DIR="/Users/drodriguez/Library/Application Support/Herd/config/php/84/"
