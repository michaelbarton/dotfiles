# Ghostty + tmux Cheatsheet

Prefix key: `Ctrl-a`

All window and tab management is handled by tmux. Ghostty's `Cmd-T` and
`Cmd-N` are unbound to avoid conflicts.

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

| Keys | Action |
| --- | --- |
| `Cmd-+` / `Cmd--` | Zoom in / out |
| `Cmd-Shift-,` | Open config |
| `Cmd-K` | Clear screen |
