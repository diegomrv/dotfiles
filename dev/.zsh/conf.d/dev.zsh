# dev package (workstations): Node, PHP, localdev, worktrunk

alias artisan="php artisan"
alias sail='sh $([ -f sail ] && echo sail || echo vendor/bin/sail)'

export PATH="$PATH:$HOME/.composer/vendor/bin"

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

# keg-only mysql CLI (replaces removed mysql@8.0)
[[ -d "$HOMEBREW_PREFIX/opt/mysql-client/bin" ]] && export PATH="$HOMEBREW_PREFIX/opt/mysql-client/bin:$PATH"

# PHP CLI = Homebrew php@8.4, the version localdev's php-fpm serves *.test with
# (Herd retired 2026-10-05; see ~/projects/code/localdev)
[[ -d "$HOMEBREW_PREFIX/opt/php@8.4/bin" ]] && export PATH="$HOMEBREW_PREFIX/opt/php@8.4/bin:$PATH"

# localdev: wt (worktrees that boot) and dev (JS dev server at <folder>.test)
[[ -d "$HOME/projects/code/localdev/bin" ]] && export PATH="$HOME/projects/code/localdev/bin:$PATH"

# LM Studio CLI (lms)
[[ -d "$HOME/.lmstudio/bin" ]] && export PATH="$PATH:$HOME/.lmstudio/bin"

# gcloud/gsutil/bq tab completion (brew cask gcloud-cli). Needs compinit, which .zshrc ran already.
[[ -f "$HOMEBREW_PREFIX/share/google-cloud-sdk/completion.zsh.inc" ]] && source "$HOMEBREW_PREFIX/share/google-cloud-sdk/completion.zsh.inc"

# nvm, plus switching Node versions on cd to follow .nvmrc
export NVM_DIR="$HOME/.nvm"
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  source "$NVM_DIR/nvm.sh"
  [[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"

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

  autoload -U add-zsh-hook
  add-zsh-hook chpwd load-nvmrc
  load-nvmrc
fi

# worktrunk's shell hook; skipped for localdev's own `wt` (~/projects/code/localdev)
if command -v wt >/dev/null 2>&1 && [[ $(command -v wt) != */localdev/bin/wt ]]; then eval "$(command wt config shell init zsh)"; fi
