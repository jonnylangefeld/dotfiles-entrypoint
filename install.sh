#!/bin/sh

if [ ! -f ~/.config/op/token ]; then
  echo "paste the 1Password service account token from here: https://my.1password.com/vaults/nkt3i4w35tbebpteodehlxamey/allitems/pt36wyw4hk653cz7xqqkbeioji:"
  read -r OP_SERVICE_ACCOUNT_TOKEN
  mkdir -p ~/.config/op
  echo "${OP_SERVICE_ACCOUNT_TOKEN}" > ~/.config/op/token
fi
export OP_SERVICE_ACCOUNT_TOKEN
OP_SERVICE_ACCOUNT_TOKEN=$(cat ~/.config/op/token)

# install homebrew
if ! brew >/dev/null 2>&1 ; then
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# install 1password
brew install --cask \
  1password/tap/1password-cli

mkdir -p ~/.ssh
op read -f -o ~/.ssh/github "op://Service Account/github/private key"

echo "github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl" > ~/.ssh/known_hosts_tmp

export GIT_SSH_COMMAND='ssh -i ~/.ssh/github -o UserKnownHostsFile=~/.ssh/known_hosts_tmp'

if ! chezmoi >/dev/null 2>&1; then
  sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply --ssh jonnylangefeld
else
  chezmoi init --ssh jonnylangefeld
  chezmoi update --force
fi
