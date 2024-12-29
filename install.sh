#!/bin/sh

# passwordless sudo
echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/"$USER"

# install developer tools
# this has to be done because otherwise we would run into this error: https://github.com/zhaofengli/nix-homebrew/issues/29
# I found the best solution to this in this comment: https://apple.stackexchange.com/questions/107307/how-can-i-install-the-command-line-tools-completely-from-the-command-line#comment433354_329261
install_developer_tools() {
  if ! xcode-select -p >/dev/null 2>&1; then
    tmp_file=/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
    touch $tmp_file
    label=$(softwareupdate -l | grep -B 1 -E "Command Line (Developer|Tools)" | awk -F"*" '/^ ?\\*/ {print$2}' | awk -F":" '{print$2}' | sed 's/^ *//;s/ *$//' | sed '/^$/d' | tail -n1)
    echo "Installing $label"
    softwareupdate --agree-to-license --verbose -i "$label"
    rm -rf $tmp_file
    sudo xcode-select --switch /Library/Developer/CommandLineTools
  fi
}
# install_developer_tools

if ! command -v nix >/dev/null 2>&1; then
  curl -L https://nixos.org/nix/install | sh -s -- --yes
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

echo "running nix-shell"

# because otherwise I'd run into https://github.com/NixOS/docker/issues/34
# sudo chown -R ${USER}:$(id -gn) /nix/var/nix/profiles/per-user
# sudo chown -R ${USER}:$(id -gn) /nix/var/nix/gcroots/per-user

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
    git clone --depth 1 --branch jlf/universal "https://$gh_token@github.com/jonnylangefeld/dotfiles.git" ~/repos/dotfiles
    cd ~/repos/dotfiles || exit
  fi
'

# xcode-select --install

#nix run nix-darwin --extra-experimental-features "nix-command flakes" -- switch --flake ~/repos/dotfiles/#vm
