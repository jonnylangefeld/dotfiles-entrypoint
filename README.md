# dotfiles-entrypoint

This is the public entrypoint to download my dotfiles.

Run

```shell
sh -c "$(curl -H "Accept: application/vnd.github.v3.raw" \
     https://api.github.com/repos/jonnylangefeld/dotfiles-entrypoint/contents/install.sh\?ref=jlf/universal)"
```

On any machine to install the dotfiles.
