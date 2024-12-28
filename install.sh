#!/bin/sh

# export OP_SERVICE_ACCOUNT_TOKEN
# echo "paste the 1Password service account token from here: https://my.1password.com/vaults/nkt3i4w35tbebpteodehlxamey/allitems/pt36wyw4hk653cz7xqqkbeioji:"
# read -r OP_SERVICE_ACCOUNT_TOKEN

# passwordless sudo
echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/"$USER"

# install homebrew
if ! brew >/dev/null 2>&1 ; then
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

eval "$(/opt/homebrew/bin/brew shellenv)"

xargs brew install --cask << EOF
google-cloud-sdk
EOF

current_user=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")
if [ "$current_user" != "jonny.langefeld@gmail.com" ]; then
  gcloud auth login --no-launch-browser
fi

# create secret via
# gcloud secrets create gh_token --project jonnylangefeld-dotfiles

# update secret via
# echo -n "$gh_token" | gcloud secrets versions add gh_token --data-file=- --project jonnylangefeld-dotfiles

gh_token=$(gcloud secrets versions access latest --secret="gh_token" --project jonnylangefeld-dotfiles)

# mkdir -p ~/.ssh
# op read -f -o ~/.ssh/github "op://Service Account/github/private key"

# chmod 700 ~/.ssh
# chmod 600 ~/.ssh/github
# chmod 644 ~/.ssh/github.pub

# echo "github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl" >> ~/.ssh/known_hosts

# export GIT_SSH_COMMAND='ssh -i ~/.ssh/github -o UserKnownHostsFile=~/.ssh/known_hosts'

# PRIVATE_KEY=$(op read -f "op://Service Account/github/private key")

mkdir -p ~/repos
if [ -d "~/repos/dotfiles" ]; then
  cd ~/repos/dotfiles
  git pull
else
  git clone "https://$gh_token@github.com/jonnylangefeld/dotfiles.git" ~/repos/dotfiles
fi
cd ~/repos/dotfiles || exit
