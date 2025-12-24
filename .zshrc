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

# Initialize zsh completion system
autoload -Uz compinit && compinit

source ~/.aliases

if command -v brew >/dev/null 2>&1; then
  source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# Only init zoxide in interactive shells (prevents errors in scripts/subshells)
if [[ $- == *i* ]]; then
  eval "$(zoxide init --cmd cd zsh)"
fi

[ -f "$HOME/.deno/env" ] && . "$HOME/.deno/env"

convert_video() {
    input_file="$1"
    output_file="${input_file%.*}_hdr.mp4"
    
    # Detect HDR metadata
    hdr_info=$(ffprobe -v error -select_streams v:0 -show_entries stream=color_space,color_transfer,color_primaries -of default=noprint_wrappers=1 "$input_file")
    
    # Base conversion command
    ffmpeg_cmd=(
        ffmpeg -i "$input_file"
        -c:v libx265
        -tag:v hvc1
        -preset medium
        -crf 23
        -c:a copy
        -map_metadata 0
        -movflags +faststart
    )

    # HDR-specific parameters
    if echo "$hdr_info" | grep -q "color_transfer=smpte2084\|color_space=bt2020nc\|color_primaries=bt2020"; then
        echo "Detected HDR source. Applying HDR-aware conversion."
        ffmpeg_cmd+=(
            # HDR-specific color handling
            -color_primaries bt2020
            -color_trc smpte2084
            -colorspace bt2020nc
            # Optional: tone-mapping for SDR displays
            -vf "zscale=t=linear:npl=100,format=yuv420p,zscale=p=bt709:t=linear:m=bt2020nc:r=tv,format=yuv420p"
        )
    fi

    # Complete the conversion
    "${ffmpeg_cmd[@]}" "$output_file"
}

# Alternative function with more aggressive tone-mapping
convert_video_hdr_aggressive() {
    input_file="$1"
    output_file="${input_file%.*}_hdr_mapped.mp4"
    
    ffmpeg -i "$input_file" \
    -c:v libx265 \
    -tag:v hvc1 \
    -preset medium \
    -crf 23 \
    -c:a copy \
    -map_metadata 0 \
    -movflags +faststart \
    -vf "zscale=t=linear:npl=100,tonemap=tonemap=hable:desat=0,zscale=p=bt709:t=linear:m=bt2020nc:r=tv" \
    "$output_file"
}

# Added by LM Studio CLI (lms)
export PATH="$PATH:$HOME/.lmstudio/bin"
# End of LM Studio CLI section

# Added by CodeRabbit CLI installer
export PATH="$HOME/.local/bin:$PATH"

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
