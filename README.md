# Dotfiles

My personal dotfiles for macOS, managed with Ansible.

## Quick start

```bash
# Clone the repository
git clone https://github.com/michaelbarton/dotfiles.git ~/.dotfiles

# Apply configuration with Ansible
cd ~/.dotfiles
make apply
```

## Run specific Ansible tags

```bash
uv run ansible-playbook -i ~/.dotfiles/ansible/inventory.ini ~/.dotfiles/ansible/dotfiles.yml --tags "hooks,setup"
```

Tagged `never` tasks (run explicitly when needed):

```bash
# Install Homebrew packages from Brewfile, prune orphans, clean caches
make packages

# Optional bioinformatics tools
make packages-bio

# macOS defaults and Dock (requires sudo)
uv run ansible-playbook -i ~/.dotfiles/ansible/inventory.ini ~/.dotfiles/ansible/dotfiles.yml --tags macos --ask-become-pass
```

Since macOS 13.2, `defaults write` against a sandboxed app silently writes to
the wrong plist unless the terminal has Full Disk Access — the command succeeds
and does nothing.

## Maintenance

```bash
make fmt_check
make nvim-check
make nvim-update   # sync plugins and refresh lazy-lock.json
```

### Fish Shell

```bash
curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher
fish -c "fisher update"
```

## Customization

For machine-specific settings, create:

- `~/.local/environment.bash` for Bash settings
- `~/.local/environment.fish` for Fish settings

### Work git identity

`GIT_AUTHOR_*`/`GIT_COMMITTER_*` env vars are not set globally because they
override every gitconfig level, making per-repo identity impossible. Instead,
`git/gitconfig` includes `~/.config/git/config-local` if present. On a machine
that needs a work identity, create it by hand (never committed — it names your
employer):

```gitconfig
[includeIf "hasconfig:remote.*.url:git@github.com:<org>/**"]
  path = ~/.config/git/config-work
```

And `~/.config/git/config-work`:

```gitconfig
[user]
  email = you@work-example.com
  name = Your Name
```

Requires git 2.36+ for `hasconfig:`. Verify with:

```bash
cd <a work checkout> && git var GIT_AUTHOR_IDENT   # expect work address
cd ~/.dotfiles && git var GIT_AUTHOR_IDENT          # expect personal address
```
