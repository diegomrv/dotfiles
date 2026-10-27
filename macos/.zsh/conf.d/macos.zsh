# macos package

export LEDGER_FILE="$HOME/finance/.hledger.journal"
export MOLE_ENABLE_DISK_VERIFY=1

# Unlock the login keychain for SSH sessions (needed for Claude Code auth, etc.)
if [[ -n "$SSH_CONNECTION" ]] && ! security show-keychain-info login.keychain 2>/dev/null; then
  security unlock-keychain login.keychain
fi
