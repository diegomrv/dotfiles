# Separate ZSH configuration for Ubuntu (WSL)
export PATH="$HOME/.local/bin:$PATH"

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

eval "$(oh-my-posh init zsh --config ~/.hunk-mod.omp.json)"

export WARP_ENABLE_WAYLAND=1
