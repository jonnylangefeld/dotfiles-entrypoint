#!/bin/sh

export OP_SERVICE_ACCOUNT_TOKEN
echo "paste the 1Password service account token from here: https://my.1password.com/vaults/nkt3i4w35tbebpteodehlxamey/allitems/pt36wyw4hk653cz7xqqkbeioji:"
read -r OP_SERVICE_ACCOUNT_TOKEN

# passwordless sudo
echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/"$USER"

# install homebrew
if ! brew >/dev/null 2>&1 ; then
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

eval "$(/opt/homebrew/bin/brew shellenv)"

# install 1password
brew install --cask 1password-cli

mkdir -p ~/.ssh
op read -f -o ~/.ssh/github "op://Service Account/github/private key"

chmod 700 ~/.ssh
chmod 600 ~/.ssh/github
chmod 644 ~/.ssh/github.pub

echo "github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl" >> ~/.ssh/known_hosts

export GIT_SSH_COMMAND='ssh -i ~/.ssh/github -o UserKnownHostsFile=~/.ssh/known_hosts'

mkdir -p ~/repos
git clone git@github.com:jonnylangefeld/dotfiles.git ~/repos/dotfiles

cd ~/repos/dotfiles || exit
