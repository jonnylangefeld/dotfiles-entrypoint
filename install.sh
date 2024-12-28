#!/bin/sh

# passwordless sudo
echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/"$USER"

# install homebrew
if ! brew >/dev/null 2>&1 ; then
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

eval "$(/opt/homebrew/bin/brew shellenv)"

# install homebrew packages
xargs brew install --cask << EOF
google-cloud-sdk
EOF

# login to gcloud
current_user=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")
if [ "$current_user" != "jonny.langefeld@gmail.com" ]; then
  gcloud auth login --no-launch-browser
fi

# create secret via
# gcloud secrets create gh_token --project jonnylangefeld-dotfiles
# update secret via
# echo -n "$gh_token" | gcloud secrets versions add gh_token --data-file=- --project jonnylangefeld-dotfiles
gh_token=$(gcloud secrets versions access latest --secret="gh_token" --project jonnylangefeld-dotfiles)

# clone dotfiles
mkdir -p ~/repos
if [ -d ~/repos/dotfiles ]; then
  cd ~/repos/dotfiles || exit
  git pull
else
  git clone --depth 1 "https://$gh_token@github.com/jonnylangefeld/dotfiles.git" ~/repos/dotfiles
  cd ~/repos/dotfiles || exit
  ls
fi
