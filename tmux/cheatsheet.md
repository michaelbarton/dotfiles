# Ghostty + tmux Cheatsheet

Prefix key: `Ctrl-a`

All window and tab management is handled by tmux. Ghostty's `Cmd-T` and `Cmd-N`
are unbound to avoid conflicts.

## tmux (prefix = Ctrl-a)

### Sessions

| Keys               | Action                 |
| ------------------ | ---------------------- |
| `prefix d`         | Detach from session    |
| `prefix s`         | List / switch sessions |
| `prefix $`         | Rename session         |
| `tmux new -s name` | New named session      |

### Windows (tabs inside tmux)

| Keys                    | Action                   |
| ----------------------- | ------------------------ |
| `prefix c`              | New window               |
| `prefix ,`              | Rename window            |
| `prefix n` / `prefix p` | Next / previous window   |
| `prefix 1-9`            | Jump to window by number |
| `prefix Ctrl-a`         | Toggle last window       |
| `prefix &`              | Kill window              |

### Panes (splits inside a window)

| Keys           | Action                              |
| -------------- | ----------------------------------- |
| `prefix i`     | Split horizontal                    |
| `prefix u`     | Split vertical                      |
| `Ctrl-h/j/k/l` | Navigate panes (vim-tmux-navigator) |
| `prefix z`     | Zoom / unzoom pane                  |
| `prefix x`     | Kill pane                           |
| `prefix Space` | Enter copy mode (vi keys)           |

### Copy mode (vi)

| Keys | Action          |
| ---- | --------------- |
| `/`  | Search forward  |
| `?`  | Search backward |
| `v`  | Begin selection |
| `y`  | Yank selection  |
| `q`  | Exit copy mode  |

## Neovim ToggleTerm (`<leader>t`)

Fixed terminal roles make it easier to keep context:

| Keys         | Action                                                   |
| ------------ | -------------------------------------------------------- |
| `<leader>tr` | Focus run terminal (slot 1)                              |
| `<leader>te` | Focus test terminal (slot 2)                             |
| `<leader>ts` | Focus scratch terminal (slot 3)                          |
| `<leader>ta` | Toggle last-focused terminal                             |
| `<leader>tx` | Close current terminal                                   |
| `<leader>tX` | Close all managed terminals                              |
| `<leader>tl` | Send line (or visual selection) to last-focused terminal |
| `<leader>tj` | Pick and run a `just` target in the run terminal         |

Inside ToggleTerm buffers:

| Keys           | Action                                |
| -------------- | ------------------------------------- |
| `<Esc>` / `jk` | Leave terminal insert mode            |
| `Ctrl-h/j/k/l` | Navigate panes via vim-tmux-navigator |

## Ghostty

| Keys              | Action        |
| ----------------- | ------------- |
| `Cmd-+` / `Cmd--` | Zoom in / out |
| `Cmd-Shift-,`     | Open config   |
| `Cmd-K`           | Clear screen  |
