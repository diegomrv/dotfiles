# Separate ZSH configuration for MacOS
export PATH="/opt/homebrew/bin:$PATH"
export PATH="$PATH:/opt/homebrew/sbin"
export PATH="$PATH:$HOME/.composer/vendor/bin"

if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
  eval "$(oh-my-posh init zsh --config ~/.wolfius.omp.json)"
fi

# pnpm. Different installers have used $PNPM_HOME and $PNPM_HOME/bin as the global
# bin dir, so add whichever actually exists.
export PNPM_HOME="$HOME/Library/pnpm"
for _d in "$PNPM_HOME" "$PNPM_HOME/bin"; do
  if [[ -d "$_d" ]]; then
    case ":$PATH:" in
      *":$_d:"*) ;;
      *) export PATH="$_d:$PATH" ;;
    esac
  fi
done
unset _d
# pnpm end

# keg-only mysql CLI (replaces removed mysql@8.0)
[[ -d /opt/homebrew/opt/mysql-client/bin ]] && export PATH="/opt/homebrew/opt/mysql-client/bin:$PATH"

# Laravel Herd (injected by Herd; kept here so it stays off Linux machines)
if [[ -d "$HOME/Library/Application Support/Herd/bin" ]]; then
  export PATH="$HOME/Library/Application Support/Herd/bin:$PATH"
  export HERD_PHP_84_INI_SCAN_DIR="$HOME/Library/Application Support/Herd/config/php/84/"
  export HERD_PHP_82_INI_SCAN_DIR="$HOME/Library/Application Support/Herd/config/php/82/"
fi

# LM Studio CLI (lms)
[[ -d "$HOME/.lmstudio/bin" ]] && export PATH="$PATH:$HOME/.lmstudio/bin"

# Unlock the login keychain for SSH sessions (needed for Claude Code auth, etc.)
if [[ -n "$SSH_CONNECTION" ]] && ! security show-keychain-info login.keychain 2>/dev/null; then
  security unlock-keychain login.keychain
fi