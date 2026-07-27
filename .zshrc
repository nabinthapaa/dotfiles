# Enable the subsequent settings only in interactive sessions
[[ -o interactive ]] || return

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

autoload -Uz add-zsh-hook
autoload -Uz compinit

source_if_exists() {
  local file

  for file in "$@"; do
    if [[ -r "$file" ]]; then
      source "$file"
      return 0
    fi
  done

  return 1
}

# Temporary directory creation function
tmp() {
  tmpd="$(mktemp -d)" || {
    echo "Failed to create temp directory"
    return 1
  }

  cd "$tmpd" || {
    echo "Failed to change directory to $tmpd"
    return 1
  }

  echo "Switched to temporary directory: $tmpd"
}

# Docker service execution
exec_service() {
  service="$1"
  shift
  docker compose exec "$service" "$@"
}

init_slint() {
    local project="$1"

    if [[ -z "$project" ]]; then
        echo "Usage: init_slint <project-name>"
        return 1
    fi

    git clone git@github.com:slint-ui/slint-rust-template.git "$project" || { 
      echo "Git clone failed"
      return 1
    }

    rm -rf "$project/.git"

    (
        cd "$project" || exit
        git init
        git add .
        git commit -m "Initial commit"
    )

    echo "✅ Slint project '$project' created."
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
      return 1
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
    return 1
  fi

  mkdir -p "$1"
  cd "$1" || return 0
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
  export MANPAGER='nvim +Man!'
fi

# Sourcing fzf configuration
# Environment variables
export SSH_KEY_PATH="$HOME/.ssh/id_ed25519"
export LANG=en_US.UTF-8
export OLLAMA_MODELS="/run/media/nabin/4D8B-DF04/ollama_models/.ollama"
export ARCHFLAGS="-arch x86_64"
export VIMRUNTIME=/usr/share/nvim/runtime

# Path modifications
export PATH="$HOME/.cargo/bin:$HOME/.npm-global/bin:$HOME/go/bin:$HOME/.local/bin:$HOME/.android/cmdline-tools/bin:$HOME/.android/platform-tools:$PATH"

if command -v starship >/dev/null 2>&1; then
  eval -- "$(starship init zsh)"
fi

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' menu no
compinit

if [[ -t 0 && -t 1 ]] && command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
fi

source_if_exists \
  /usr/share/zsh/plugins/fzf-tab/fzf-tab.plugin.zsh \
  /usr/share/zsh/plugins/fzf-tab/fzf-tab.zsh

source_if_exists \
  /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

source_if_exists \
  /usr/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh \
  /usr/share/zsh/plugins/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh

# NVM setup for Node.js
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

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

    if [[ "${APP_SERVICE:-}" != "$service_name" ]]; then
      export APP_SERVICE="$service_name"
      export NVIM_LARAVEL_ENV="docker-compose"
    fi
  else
    if [[ -n "${APP_SERVICE:-}" ]]; then
      unset APP_SERVICE
      unset NVIM_LARAVEL_ENV
    fi
  fi
}

__accept_tmux_sessionizer_command() {
  BUFFER="$1"
  CURSOR=${#BUFFER}
  zle accept-line
}

__tmux_sessionizer_default() { __accept_tmux_sessionizer_command "tmux-sessionizer"; }
__tmux_sessionizer_0() { __accept_tmux_sessionizer_command "tmux-sessionizer -s 0"; }
__tmux_sessionizer_1() { __accept_tmux_sessionizer_command "tmux-sessionizer -s 1"; }
__tmux_sessionizer_2() { __accept_tmux_sessionizer_command "tmux-sessionizer -s 2"; }
__tmux_sessionizer_3() { __accept_tmux_sessionizer_command "tmux-sessionizer -s 3"; }

zle -N __tmux_sessionizer_default
zle -N __tmux_sessionizer_0
zle -N __tmux_sessionizer_1
zle -N __tmux_sessionizer_2
zle -N __tmux_sessionizer_3

bindkey '^f' __tmux_sessionizer_default
bindkey '^[h' __tmux_sessionizer_0
bindkey '^[t' __tmux_sessionizer_1
bindkey '^[n' __tmux_sessionizer_2
bindkey '^[s' __tmux_sessionizer_3

# Custom script path
SCRIPTS="$HOME/.local/scripts/"
export PATH="$SCRIPTS:$PATH"

export XDG_CONFIG_DIRS=~/dotfiles/.config/

export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:-} \
  --highlight-line \
  --info=inline-right \
  --ansi \
  --layout=reverse \
  --border=none \
  --color=bg+:#2e3c64 \
  --color=bg:#1f2335 \
  --color=border:#29a4bd \
  --color=fg:#c0caf5 \
  --color=gutter:#1f2335 \
  --color=header:#ff9e64 \
  --color=hl+:#2ac3de \
  --color=hl:#2ac3de \
  --color=info:#545c7e \
  --color=marker:#ff007c \
  --color=pointer:#ff007c \
  --color=prompt:#2ac3de \
  --color=query:#c0caf5:regular \
  --color=scrollbar:#29a4bd \
  --color=separator:#ff9e64 \
  --color=spinner:#ff007c \
"

add-zsh-hook precmd __docker_env_auto

[[ -f "$HOME/.local/share/../bin/env" ]] && . "$HOME/.local/share/../bin/env"
unset VIM
unset VIMRUNTIME


# Added by Antigravity CLI installer
export PATH="/home/nabin/.local/bin:$PATH"
export PATH="/home/nabin/.devcontainers/bin:$PATH"
