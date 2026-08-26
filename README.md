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
# Install Homebrew packages from Brewfile
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
