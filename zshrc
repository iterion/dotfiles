# Custom cd
chpwd() ls

autoload -Uz compinit
compinit
# Completion for kitty
kitty + complete setup zsh | source /dev/stdin

# Kitty functions
function kt-native() {
  export PROJECT_DIR=$1
  kitty --session ~/dotfiles/config/kitty/reason_native.conf
}

function kt-bs() {
  export PROJECT_DIR=$1
  kitty --session ~/dotfiles/config/kitty/bucklescript.conf
}

function kt-js() {
  export PROJECT_DIR=$1
  kitty --session ~/dotfiles/config/kitty/javascript.conf
}

DEFAULT_USER="iterion"
source $HOME/.alias

export FZF_DEFAULT_COMMAND='rg --files --hidden'
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
set -o vi
