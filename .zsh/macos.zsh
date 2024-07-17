# Separate ZSH configuration for MacOS
export PATH="$PATH:$HOME/.composer/vendor/bin"

# bun completions
[ -s "/Users/wolfius/.bun/_bun" ] && source "/Users/wolfius/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
  #eval "$(oh-my-posh init zsh --config ~/.M365Princess-mod.omp.json)"
  eval "$(oh-my-posh init zsh --config ~/.hunk-mod.omp.json)"
fi
