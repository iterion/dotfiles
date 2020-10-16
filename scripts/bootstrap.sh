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
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
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


###############################################################################
# Install binaries and other packages
###############################################################################
echo "Homebrew: installing binaries and other packages..."
brew install bat
brew install fzf
brew install git
brew install git-delta
brew install httpie # https://httpie.org/
brew install hub
brew install kitty # https://formulae.brew.sh/cask/kitty
brew install mas # https://github.com/mas-cli/mas
brew install nginx
brew install node
brew install ripgrep
brew install Schniz/tap/fnm # Fast Node Manager - https://github.com/Schniz/fnm
brew install yarn
brew install aws-vault
# brew install neovim


###############################################################################
# Run Homebrew cleanup to remove installation/cached files
###############################################################################
echo "Homebrew: cleaning up..."
brew cleanup


###############################################################################
# Install applications with Homebrew Cask
###############################################################################
echo "Homebrew Cask: installing apps..."
brew cask install 1password
brew cask install docker
brew cask install firefox
brew cask install github
brew cask install slack
brew cask install spotify
brew cask install visual-studio-code
brew cask install zoomus


echo "Go to https://github.com/Hammerspoon/hammerspoon/releases/tag/0.9.78 to
download Hammerspoon"
while true; do
    read -p "Have you installed Hammerspoon?" yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) continue;;
        * ) echo "Please answer yes or no.";;
    esac
done


###############################################################################
# Install applications with mas-cli (Mac App Store CLI)
###############################################################################
echo "mas-cli: installing Mac App Store apps..."

mas install 

echo "macOS Config, Dev Tools, Apps are Done Setup!"
#
