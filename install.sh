#!/bin/sh

set -x

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

  # After installing nix, it tells us 'Nix won't work in active shell sessions until you restart them.'
  # To be able to run nix commands in the current shells script, we source the following
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

  # The above perfectly works when doing all steps manual, but once running in this script, there are further issues.
  # As soon as we get to the `nix-shell` command, we get errors like https://github.com/NixOS/docker/issues/34
  # `error: could not set permissions on '/nix/var/nix/profiles/per-user' to 755: Operation not permitted`
  # This is even those the permissions of that file are already 755. I noticed it has to do with ownership.
  # I temporarily solved it by owning this file via
  # sudo chown -R ${USER}:$(id -gn) /nix/var/nix/profiles/per-user
  # But that just started a game of whack-a-mole, where I had to do this for more and more files.
  # Eventually I found that if we just re-attempt the installation of nix, it will fix all the permissions, despite the re-installation failing.
  # This seems like a hack, but currently the only solution I could find to use nix right after an install, without additional manual steps.
  # Since this is only executed on a brand new install, I'll accept this hack for now.
  # curl -L https://nixos.org/nix/install | sh -s -- --yes

  timeout=30
  while ! nc -zU /var/run/nix-daemon.sock; do
    echo "Waiting for nix-daemon to start..."
    sleep 1
    timeout=$((timeout - 1))
    if [ $timeout -le 0 ]; then
      echo "Nix daemon didn't start, exiting."
      exit 1
    fi
  done
  # sudo usermod -aG nixbld "$(whoami)"
  # sudo dseditgroup -o edit -a "$(whoami)" -t user nixbld
  # if [ "$(uname -s)" = "Darwin" ]; then
  #   sudo dseditgroup -o edit -a "$(whoami)" -t user nixbld
  # else
  #   sudo usermod -aG nixbld "$(whoami)"
  # fi
fi

echo "running nix-shell"
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

#nix run nix-darwin --extra-experimental-features "nix-command flakes" -- switch --flake ~/repos/dotfiles/#vm
