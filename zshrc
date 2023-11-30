# Path to your oh-my-zsh installation.
export ZSH="/Users/iterion/.oh-my-zsh"
eval "$(ssh-agent -s)"
ssh-add --apple-use-keychain ~/.ssh/id_ed25519

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

export KITTYCAD_TOKEN=$(op --account kittycadinc.1password.com item get "KittyCAD Token" --fields credential)
export KITTYCAD_DEV_TOKEN=$(op --account kittycadinc.1password.com item get "KittyCAD Dev Token" --fields credential)
export GITHUB_VAULT_TOKEN=$(op --account kittycadinc.1password.com item get "GitHub Token Vault" --fields token)

export TF_VAR_axiom_api_token=$(op --account kittycadinc.1password.com item get TerraformCreds --fields axiom_api_token)
export TF_VAR_github_token=$(op --account kittycadinc.1password.com item get TerraformCreds --fields github_token)
export TF_VAR_actions_github_app_key_base64=$(op --account kittycadinc.1password.com item get TerraformCreds --fields actions_github_app_key_base64)
export TF_VAR_actions_github_app_id=$(op --account kittycadinc.1password.com item get TerraformCreds --fields actions_github_app_id)
export VAULT_ADDR="http://vault.hawk-dinosaur.ts.net"

function decode_aws_auth() {
  aws sts decode-authorization-message --encoded-message $1 | jq -r .DecodedMessage | jq .
}

function ssh-k8s() {
  INSTANCE_ID=$(kubectl get node $1 -ojson | jq -r ".spec.providerID" | cut -d \/ -f5)
  aws ssm start-session --target $INSTANCE_ID
}
