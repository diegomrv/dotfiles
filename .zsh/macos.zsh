# Separate ZSH configuration for MacOS
export PATH="/opt/homebrew/bin:$PATH"
export PATH="$PATH:/opt/homebrew/sbin"
export PATH="$PATH:$HOME/.composer/vendor/bin"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
  #eval "$(oh-my-posh init zsh --config ~/.M365Princess-mod.omp.json)"
  eval "$(oh-my-posh init zsh --config ~/.hunk-mod.omp.json)"
fi

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end