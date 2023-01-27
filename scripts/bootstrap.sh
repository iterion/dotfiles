#!/bin/zsh

###############################################################################
# setup-brew
#
# A shell script to automate system tool setup for Mac OS X.
###############################################################################


###############################################################################
# Install Xcode command line tools
###############################################################################
echo "Installing Xcode Command Line Tools..."
xcode-select --install


###############################################################################
# Check for Homebrew, else install
###############################################################################
echo "Checking for, or Installing Homebrew..."
if [ -z `command -v brew` ]; then
    echo "Brew is missing! Installing it..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi;


##############################################################################
# Make sure we're on latest Homebrew
###############################################################################
echo "Homebrew: updating..."
brew update


###############################################################################
# Upgrade any already-installed formulae
###############################################################################
echo "Homebrew: upgrading..."
brew upgrade


###############################################################################
# Install utilities
###############################################################################
echo "Homebrew: updating unix tools..."
brew install zsh
brew install zsh-completions

# Change the default shell to zsh
zsh_path="$( command -v zsh )"
if ! grep "$zsh_path" /etc/shells; then
    echo "adding $zsh_path to /etc/shells"
    echo "$zsh_path" | sudo tee -a /etc/shells
fi

if [[ "$SHELL" != "$zsh_path" ]]; then
    chsh -s "$zsh_path"
    echo "default shell changed to $zsh_path"
fi
# Install ohmyzsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"



###############################################################################
# Install binaries and other packages
###############################################################################
echo "Homebrew: installing binaries and other packages..."
brew install bat
brew install fzf
brew install git
brew install git-lfs
brew install mas # https://github.com/mas-cli/mas
brew install hub
brew install ripgrep
brew install aws-vault
brew install neovim
brew install kubectx aws-iam-authenticator
brew install direnv
brew install tmux
brew install asdf
brew install dockutils

git clone https://github.com/AstroNvim/AstroNvim ~/.config/nvim

# INSTALL TPM
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

###############################################################################
# Run Homebrew cleanup to remove installation/cached files
###############################################################################
echo "Homebrew: cleaning up..."
brew cleanup

###############################################################################
# asdf setup
###############################################################################
asdf plugin add nodejs
asdf plugin add python
asdf plugin add terraform


###############################################################################
# rustup setup
###############################################################################
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

source "$HOME/.cargo/env"
rustup install stable

###############################################################################
# Install applications with Homebrew Cask
###############################################################################
echo "Homebrew Cask: installing apps..."
brew tap homebrew/cask-fonts
brew install --cask font-fira-code
brew install --cask docker
brew install --cask 1password/tap/1password-cli
brew install slack
brew install spotify
brew install zoom
brew install --cask warp
brew install --cask gpg-suite

###############################################################################
# Install applications with mas-cli (Mac App Store CLI)
###############################################################################
echo "mas-cli: installing Mac App Store apps..."

mas install 1475387142

echo "macOS Config, Dev Tools, Apps are Done Setup!"
#
