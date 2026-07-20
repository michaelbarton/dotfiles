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

## Maintenance

```bash
make fmt_check
make nvim-check
```

### Fish Shell

```bash
curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher
fish -c "fisher update"
```

## Customization

For machine-specific settings, create:

- `~/.local/environment.bash` for Bash settings
