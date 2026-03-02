# Ghostty + tmux Cheatsheet

Prefix key: `Ctrl-a`

## When to use what

| Use Ghostty tabs for | Use tmux windows/panes for |
| --- | --- |
| Completely separate tmux sessions | Multiple views within a project |
| Isolated work contexts | Splits you want to survive a disconnect |
| Quick throwaway shells (`Cmd-T`, do thing, `Cmd-W`) | Persistent layouts |

## tmux (prefix = Ctrl-a)

### Sessions

| Keys | Action |
| --- | --- |
| `prefix d` | Detach from session |
| `prefix s` | List / switch sessions |
| `prefix $` | Rename session |
| `tmux new -s name` | New named session |

### Windows (tabs inside tmux)

| Keys | Action |
| --- | --- |
| `prefix c` | New window |
| `prefix ,` | Rename window |
| `prefix n` / `prefix p` | Next / previous window |
| `prefix 1-9` | Jump to window by number |
| `prefix Ctrl-a` | Toggle last window |
| `prefix &` | Kill window |

### Panes (splits inside a window)

| Keys | Action |
| --- | --- |
| `prefix i` | Split horizontal |
| `prefix u` | Split vertical |
| `Ctrl-h/j/k/l` | Navigate panes (vim-tmux-navigator) |
| `prefix z` | Zoom / unzoom pane |
| `prefix x` | Kill pane |
| `prefix Space` | Enter copy mode (vi keys) |

### Copy mode (vi)

| Keys | Action |
| --- | --- |
| `/` | Search forward |
| `?` | Search backward |
| `v` | Begin selection |
| `y` | Yank selection |
| `q` | Exit copy mode |

## Ghostty

### Tabs & Windows

| Keys | Action |
| --- | --- |
| `Cmd-T` | New tab (new tmux session via fish auto-attach) |
| `Cmd-W` | Close tab |
| `Cmd-Shift-]` / `Cmd-Shift-[` | Next / previous tab |
| `Cmd-1-9` | Jump to tab by number |
| `Cmd-N` | New window |

### Other

| Keys | Action |
| --- | --- |
| `Cmd-+` / `Cmd--` | Zoom in / out |
| `Cmd-Shift-,` | Open config |
| `Cmd-K` | Clear screen |
