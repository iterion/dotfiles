# Path to your oh-my-zsh installation.
export ZSH="/Users/iterion/.oh-my-zsh"

ZSH_THEME="robbyrussell"
COMPLETION_WAITING_DOTS="true"

export EDITOR='nvim'
export KUBECONFIG=~/.kube/config
export GO111MODULE="on"
export GOPATH="/Users/iterion/Development/go"
export PATH="/usr/local/opt/gnu-getopt/bin:$GOPATH/bin:$PATH"
export PATH="$PATH:/usr/local/bin"
export PATH="$PATH:/Users/iterion/.local/bin"
export PATH="$PATH:/Applications/kitty.app/Contents/MacOS/"
source "/Users/iterion/Development/shell-tools/scripts.sh"

autoload -Uz compinit
compinit

# Plugin list for oh-my-zsh
plugins=(git brew kops kubectl)

source $ZSH/oh-my-zsh.sh

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

eval "$(pyenv init -)"
if which pyenv-virtualenv-init > /dev/null; then eval "$(pyenv virtualenv-init -)"; fi

# Ruby installs
eval "$(rbenv init -)"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
eval "$(direnv hook zsh)"

# Completion for kitty
kitty + complete setup zsh | source /dev/stdin

# Kitty functions
function kt-native() {
  export PROJECT_DIR=$1
  kitty --session ~/dotfiles/config/kitty/reason_native.conf
}

DEFAULT_USER="iterion"
source $HOME/.alias

export FZF_DEFAULT_COMMAND='rg --files --hidden'
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
set -o vi

source ~/.jira-creds

export PATH="$HOME/.poetry/bin:$PATH"

function k8sssh {
  cluster=$(aws eks list-clusters | jq -r .clusters[] | fzf)
  ssm session -f "kubernetes.io/cluster/${cluster}=owned" -t Name
}
export PATH="${HOME}/.local/bin:${PATH}"
