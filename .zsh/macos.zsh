# Separate ZSH configuration for MacOS
export PATH="/opt/homebrew/bin:$PATH"
export PATH="$PATH:/opt/homebrew/sbin"
export PATH="$PATH:$HOME/.composer/vendor/bin"

if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
  eval "$(oh-my-posh init zsh --config ~/.wolfius.omp.json)"
fi

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end