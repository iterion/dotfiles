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

autoload -Uz compinit
compinit

# Plugin list for oh-my-zsh
plugins=(git brew kops kubectl asdf)

source $ZSH/oh-my-zsh.sh

eval "$(direnv hook zsh)"

DEFAULT_USER="iterion"
source $HOME/.alias

export FZF_DEFAULT_COMMAND='rg --files --hidden'
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
set -o vi

# source ~/.jira-creds
export KITTYCAD_TOKEN=$(security find-generic-password -a "$USER" -s "kittycad_token" -w)
export KITTYCAD_DEV_TOKEN=$(security find-generic-password -a "$USER" -s "kittycad_dev_token" -w)
export GITHUB_VAULT_TOKEN=$(security find-generic-password -a "$USER" -s "github_vault_token" -w)
export CONSUL_IP=$(dig +short consul.hawk-dinosaur.ts.net. @100.100.100.100 | tail -n1)
export CONSUL_HTTP_ADDR="${CONSUL_IP}:80"
export NOMAD_ADDR="http://$(dig +short nomad.service.azure.internal.kittycad.io A @$CONSUL_IP | tail -n1)"
export VAULT_ADDR="http://$(dig +short active.vault.service.gcp.internal.kittycad.io A @$CONSUL_IP | tail -n1)"

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/iterion/Downloads/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/iterion/Downloads/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/iterion/Downloads/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/iterion/Downloads/google-cloud-sdk/completion.zsh.inc'; fi
