# Enable the subsequent settings only in interactive sessions
case $- in
  *i*) ;;
  *) return ;;
esac

# Aliases
alias vim=nvim
alias vi=nvim
alias cat=bat
alias sb="source ~/.zshrc"
alias bc="nvim ~/.zshrc"
alias nvc="nvim ~/.dotfiles/.config/nvim/"
alias rndi="docker images --filter \"dangling=true\" -q | xargs -r docker rmi"
alias hypr="nvim ~/.config/hypr/"
alias ls="lsd"
alias fp="fzf --preview=\"bat --color=always {} \""
alias ff="clear && fastfetch"
alias pa="/opt/Postman\ Agent/Postman\ Agent"
alias start="sudo systemctl start"
alias status="sudo systemctl status"
alias stop="sudo systemctl stop"

# Temporary directory creation function
tmp() {
  tmpd="$(mktemp -d)" || {
    echo "Failed to create temp directory"
    exit 1
  }

  cd "$tmpd" || {
    echo "Failed to change directory to $tmpd"
    exit 1
  }

  echo "Switched to temporary directory: $tmpd"
}

# Docker service execution
exec_service() {
  service="$1"
  shift
  docker compose exec "$service" "$@"
}

# Mirror refresh
refresh_mirrors() {
  sudo reflector \
    --country 'Nepal,Singapore,Netherlands' \
    --protocol https \
    --sort score \
    --fastest 10 \
    --save /etc/pacman.d/mirrorlist
}

# Key help
key_help() {
  echo 'tap and hold to repeat key'
  echo 'a: hold: lmeta, tap: a'
  echo 's: hold: lalt, tap: s'
  echo 'd: hold: lshift, tap: d'
  echo 'f: hold: lctrl, tap: f'

  echo 'j: hold: rctrl, tap: j'
  echo 'k: hold: rshift, tap: k'
  echo 'l: hold: ralt, tap: l'
  echo ';: hold: rmeta, tap: ;'
}

# Remove temporary files
rm_tmp() {
  if [ -d /tmp ] && ls /tmp/tmp.* 1>/dev/null 2>&1; then
    echo "Removing files..."
    rm -rv /tmp/tmp.* || {
      echo "Error: Failed to delete files."
      exit 1
    }
    echo "Cleanup completed."
  else
    echo "No matching files found in /tmp/."
  fi
}

# Set volume
set_vol() {
  if [[ -z $1 ]]; then
    echo "Usage: $0 <volume-level>"
    return 1
  fi

  volume_level=$1
  echo "Setting volume $volume_level"
  wpctl set-volume @DEFAULT_AUDIO_SINK@ "$volume_level"
  return 0
}

# Get volume
get_vol() {
  wpctl get-volume @DEFAULT_AUDIO_SINK@
  return 0
}

# Toggle mute
toggle_mute() {
  wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
  return 0
}

# Make and cd into a directory
mkcd() {
  if [[ -z $1 ]]; then
    echo "Usage $0 <directory-name>"
    exit 1
  fi

  mkdir -p "$1"
  cd "$1" || exit 0
}

# List sizes
list_sizes() {
  du -h --max-depth="$1" . | sort -h
}

# Set default editor based on SSH connection
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

# Sourcing fzf configuration
source <(fzf --bash)

# Environment variables
export VIM=nvim
export SSH_KEY_PATH="$HOME/.ssh/id_ed25519"
export LANG=en_US.UTF-8
export OLLAMA_MODELS="/run/media/nabin/4D8B-DF04/ollama_models/.ollama"
export ARCHFLAGS="-arch x86_64"
export VIMRUNTIME=/usr/share/nvim/runtime

# Path modifications
export PATH="$HOME/.cargo/bin:$HOME/.npm-global/bin:$HOME/go/bin:$HOME/.local/bin:$HOME/.android/cmdline-tools/bin:$HOME/.android/platform-tools:$PATH"
eval -- "$(/usr/bin/starship init zsh --print-full-init)"
eval "$(zoxide init zsh)"

# NVM setup for Node.js
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# PNPM setup
export PNPM_HOME="/home/nabin/.local/share/pnpm"
if [[ ":$PATH:" != *":$PNPM_HOME:"* ]]; then
  export PATH="$PNPM_HOME:$PATH"
fi

# Bun setup
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Laravel setup
export PATH="$HOME/.config/composer/vendor/bin:$PATH"

# Auto-load environment variables
[ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"

# Docker environment auto-detection
__docker_env_auto() {
  local docker_file=".docker-service"
  local current_dir="$PWD"

  if [[ -f "$current_dir/$docker_file" ]]; then
    local service_name
    service_name=$(head -n 1 "$current_dir/$docker_file")

    if [[ "$APP_SERVICE" != "$service_name" ]]; then
      export APP_SERVICE="$service_name"
      export NVIM_LARAVEL_ENV="docker-compose"
    fi
  else
    if [[ -n "$APP_SERVICE" ]]; then
      unset APP_SERVICE
      unset NVIM_LARAVEL_ENV
    fi
  fi
}

# Key bindings
bindkey -s '^f' 'tmux-sessionizer'
bindkey -s '^[h' 'tmux-sessionizer -s 0'
bindkey -s '^[t' 'tmux-sessionizer -s 1'
bindkey -s '^[n' 'tmux-sessionizer -s 2'
bindkey -s '^[s' 'tmux-sessionizer -s 3'

# Custom script path
SCRIPTS="$HOME/.local/scripts/"
export PATH="$SCRIPTS:$PATH"

# Docker environment auto-update on prompt
PROMPT_COMMAND="__docker_env_auto; $PROMPT_COMMAND"

. "$HOME/.local/share/../bin/env"
