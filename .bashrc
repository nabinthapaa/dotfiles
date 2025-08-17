# Enable the subsequent settings only in interactive sessions
case $- in
*i*) ;;
*) return ;;
esac

alias vim=nvim
alias vi=nvim
alias cat=bat
alias sb="source ~/.bashrc"
alias bc="nvim ~/.bashrc"
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

# Start kanata to overide keyboard
# sudo -u nabin /usr/bin/kanata -c /home/nabin/.config/kanata/config.kbd >/dev/null &

tmp() {
  # Create a temporary directory and store its path in tmpd
  tmpd="$(mktemp -d)" || {
    echo "Failed to create temp directory"
    exit 1
  }

  # Change to the newly created temporary directory
  cd "$tmpd" || {
    echo "Failed to change directory to $tmpd"
    exit 1
  }

  echo "Switched to temporary directory: $tmpd"
}

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

get_vol() {
  wpctl get-volume @DEFAULT_AUDIO_SINK@
  return 0
}

toggle_mute() {
  wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
  return 0
}

mkcd() {
  if [[ -z $1 ]]; then
    echo "Usage $0 <directory-name>"
    exit 1
  fi

  mkdir -p "$1"
  cd "$1" || exit 0
}

list_sizes() {
  du -h --max-depth="$1" . | sort -h
}

# export VIM=nvim
export VIM=nvim

export SSH_KEY_PATH="$HOME/.ssh/id_ed25519"
export LANG=en_US.UTF-8
export OLLAMA_MODELS="/run/media/nabin/4D8B-DF04/ollama_models/.ollama"

# Compilation flag
export ARCHFLAGS="-arch x86_64"

# Default Editor
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

source <(fzf --bash)

# Set personal aliases, overriding those provided by oh-my-bash libs,
# plugins, and themes. Aliases can be placed here, though oh-my-bash
# users are encouraged to define aliases within the OSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.

# export ANDROID_HOME=$HOME/.android/
# export CHROME_EXECUTABLE=/usr/bin/chromium
# export VIMRUNTIME=/usr/share/nvim/runtime

export VIMRUNTIME=$HOME/.local/nvim/share/nvim/runtime
export NVIM_DIR=$HOME/.local/nvim/
export PATH="$NVIM_DIR/bin:$PATH"


export PATH="$HOME/.cargo/bin:$HOME/.npm-global/bin:$HOME/go/bin:$HOME/.local/bin:$HOME/.android/cmdline-tools/bin:$HOME/.android/platform-tools:$PATH"
eval -- "$(/usr/bin/starship init bash --print-full-init)"
eval "$(zoxide init bash)"
#
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion
#
# # pnpm
# export PNPM_HOME="/home/nabin/.local/share/pnpm"
# case ":$PATH:" in
# *":$PNPM_HOME:"*) ;;
# *) export PATH="$PNPM_HOME:$PATH" ;;
# esac
# # pnpm end
#
# # bun
# export BUN_INSTALL="$HOME/.bun"
# export PATH="$BUN_INSTALL/bin:$PATH"
#
# # laravel
# export PATH="$HOME/.config/composer/vendor/bin:$PATH"
#
# # Generated for envman. Do not edit.
# [ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"
#
# __docker_env_auto() {
#   local docker_file=".docker-service"
#   local current_dir="$PWD"
#
#   if [[ -f "$current_dir/$docker_file" ]]; then
#     local service_name
#     service_name=$(head -n 1 "$current_dir/$docker_file")
#
#     if [[ "$APP_SERVICE" != "$service_name" ]]; then
#       export APP_SERVICE="$service_name"
#       export NVIM_LARAVEL_ENV="docker-compose"
#     fi
#   else
#     if [[ -n "$APP_SERVICE" ]]; then
#       unset APP_SERVICE
#       unset NVIM_LARAVEL_ENV
#     fi
#   fi
# }
#
#
# # Ctrl+f
# bind -x '"\C-f": "tmux-sessionizer"'
#
# # Alt+h
# bind -x '"\eh": "tmux-sessionizer -s 0"'
#
# # Alt+t
# bind -x '"\et": "tmux-sessionizer -s 1"'
#
# # Alt+n
# bind -x '"\en": "tmux-sessionizer -s 2"'
#
# # Alt+s
# bind -x '"\es": "tmux-sessionizer -s 3"'
#
# SCRIPTS="$HOME/.local/scripts/"
# export PATH="$SCRIPTS:$PATH"
#
# PROMPT_COMMAND="__docker_env_auto; $PROMPT_COMMAND"
