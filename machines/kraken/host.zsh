# Machine-specific zsh config for kraken (homelab server -- Ubuntu 24.04, headless)
# Tracked in git. NON-SECRET config only -- secrets go in ~/.zshrc.local

# Named directory shortcuts for the media drive (use ~media, ~dockerdata)
hash -d media=/mnt/media
hash -d dockerdata=/mnt/media/docker

# gnome-keyring, so gh stores its OAuth token in the keyring rather than in
# plaintext in .config/gh/hosts.yml -- that file is tracked in this repo, and on
# macOS the Keychain keeps it token-free. This gives kraken the same behaviour.
#
# Headless: no prompter and no PAM password (SSH is key-only), so nothing
# unlocks the keyring on its own. A D-Bus-activated daemon comes up LOCKED and
# every lookup fails silently, so unlock it here at session start. --replace is
# needed because D-Bus may already have activated a locked daemon holding the
# bus name; a plain --unlock would start a second daemon that owns nothing.
#
# The passphrase is empty, so this is git hygiene rather than encryption at
# rest: the token moves out of the repo, but the keyring file itself is no
# stronger than a 0600 file. Seal the passphrase with systemd-creds + TPM if
# that ever needs to be real (kraken has /dev/tpm0).
if [[ -n "$DBUS_SESSION_BUS_ADDRESS" ]] && (( $+commands[gnome-keyring-daemon] )); then
  if [[ "$(busctl --user get-property org.freedesktop.secrets \
            /org/freedesktop/secrets/collection/login \
            org.freedesktop.Secret.Collection Locked 2>/dev/null)" != "b false" ]]; then
    eval "$(printf '\n' | gnome-keyring-daemon --replace --daemonize --unlock 2>/dev/null)"
    export GNOME_KEYRING_CONTROL
  fi
fi
