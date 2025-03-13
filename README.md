# Dotfiles

My personal dotfiles for macOS, managed with Ansible.

## Ansible

```bash
# Clone the repository
git clone https://github.com/michaelbarton/dotfiles.git ~/.dotfiles

# Apply configuration with Ansible
cd ~/.dotfiles
./ansible/apply_ansible
```

### Fish Shell

```bash
curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher
fish -c "fisher update"
```

### Email Setup

1. Create maildb directory:
   ```bash
   mkdir -p ~/.maildb/michaelbarton
   ```

2. Set up Gmail password in keychain:
   ```bash
   security add-generic-password -a acct.gmail -s acct.gmail -w
   ```

3. Set up automated email sync:
   ```bash
   launchctl load -w ~/Library/LaunchAgents/uk.me.michaelbarton.offlineimap.plist
   ```

## Customization

For machine-specific settings, create:
- `~/.local/environment.bash` for Bash settings
