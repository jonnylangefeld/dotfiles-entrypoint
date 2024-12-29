# dotfiles-entrypoint

This is the public entrypoint to download my dotfiles.

Run

```shell
sh -c "$(curl -fsLS https://raw.githubusercontent.com/jonnylangefeld/dotfiles-entrypoint/jlf/universal/install.sh)"
```

Sometimes the above doesn't accurately reflect the latest changes, as it's distributed through a CDN. If you are having issues pulling the latest version of a
branch, it's best to use the Github API:

```shell
sh -c "$(curl -H "Accept: application/vnd.github.v3.raw" \
     https://api.github.com/repos/jonnylangefeld/dotfiles-entrypoint/contents/install.sh\?ref=jlf/universal)"
```

## Approach

While there's nothing inherently secret about my dotfiles, I've chosen to keep them private. While I try to stay up to date with everything there might be some
things that are outdated, and what if someone finds just that vulnerability in my system? While I don't do security through obscurity, I think to add some
obscurity to an otherwise secure system only makes it even harder for an intruder.

However, I still wanted some public entrypoint to my dotfiles, so I can just copy/paste (or even type) a single command to get my dotfiles on a new machine.
This repository is that entrypoint.

The idea is to create a minimal installation that asks me for some kind of login that I can handle with just one other device in my possession. This can
potentially be run from entirely new machines, VMs, or remote servers.

### Github Service Account Token

To achieve this I used a the Google Cloud Secret Manager to store a Github service account key with read access to https://github.com/jonnylangefeld/dotfiles.
So technically even if this key gets into the wrong hands one couldn't do much, except read the contents.

The key was created via https://github.com/settings/tokens?type=beta.

1. Click 'Generate new token'
2. Give the token a name
3. Select 'No expiration'
4. Select 'Repository Access > Only select repositories'
5. Select 'jonnylangefeld/dotfiles' in the dropdown
6. Select 'Read-only' under 'Permissions > Contents'
7. Click 'Generate token'

### Google Cloud Secret Manager

Store the token generated above as a secret in the Google Cloud Secret Manager.

```shell
gcloud projects create jonnylangefeld-dotfiles
gcloud billing projects link jonnylangefeld-dotfiles --billing-account=$(gcloud billing accounts list | grep "Privacy" | grep True | head -n1 | awk '{print$1}')
gcloud services enable secretmanager.googleapis.com --project jonnylangefeld-dotfiles
gcloud secrets create gh_token --project jonnylangefeld-dotfiles

# Write the secret token
echo -n "$gh_token" | gcloud secrets versions add gh_token --data-file=- --project jonnylangefeld-dotfiles
```
