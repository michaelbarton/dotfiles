# Dotfiles

My personal dotfiles for macOS, managed with Ansible. Fish is the primary shell,
run inside Ghostty with tmux. Editing happens in Neovim (LazyVim).

## Setup

```bash
# Clone the repository
git clone https://github.com/michaelbarton/dotfiles.git ~/.dotfiles

# Format, apply the Ansible playbook, and smoke-test the nvim config
cd ~/.dotfiles
make
```

### Make targets

- `make apply` — run the Ansible playbook (directories, symlinks, nvim plugins,
  launch agents, Claude Code skills).
- `make fmt` / `make fmt_check` — format (or check) YAML, Markdown, Python, and
  Lua files.
- `make nvim-check` — boot Neovim headlessly against representative filetypes
  and fail on startup errors or warnings.
- `make nvim-health` — run `:checkhealth`.

### Fish Shell

Plugins are managed with fisher:

```bash
curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher
fish -c "fisher update"
```

### Claude Code skills

Markdown files in `skills/` are linked into `~/.claude/skills` by the playbook,
making them available as slash commands in Claude Code.

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

- `~/.local/environment.fish` for Fish settings
- `~/.local/environment.bash` for Bash settings
- `~/.local/environment.zsh` for Zsh settings

## CI

Every push runs:

- Formatting checks (`make fmt_check`).
- Syntax checks for the fish, zsh, and bash configs and scripts.
- Ghostty config validation (`ghostty +validate-config`).
- The full Ansible playbook on Ubuntu, followed by the Neovim startup smoke test
  (`make nvim-check`).
