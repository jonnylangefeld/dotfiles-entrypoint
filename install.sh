#!/bin/sh

# passwordless sudo
# echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/"$USER"

if ! command -v nix &> /dev/null; then
  # /bin/bash -c "$(curl -fsSL https://nixos.org/nix/install) --yes"
  /bin/bash <(curl -L https://nixos.org/nix/install) --yes
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

# shellcheck disable=SC2016
nix-shell -p google-cloud-sdk git --run '
  current_user=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")
  if [ "$current_user" != "jonny.langefeld@gmail.com" ]; then
    gcloud auth login --no-launch-browser
  fi

  gh_token=$(gcloud secrets versions access latest --secret="gh_token" --project jonnylangefeld-dotfiles)

  mkdir -p ~/repos
  if [ -d ~/repos/dotfiles ]; then
    cd ~/repos/dotfiles || exit
    git pull
  else
    git clone --depth 1 "https://$gh_token@github.com/jonnylangefeld/dotfiles.git" ~/repos/dotfiles
    cd ~/repos/dotfiles || exit
  fi
'
