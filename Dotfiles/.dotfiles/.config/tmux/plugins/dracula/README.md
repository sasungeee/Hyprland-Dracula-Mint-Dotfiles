# Dracula theme for Tmux

Theme with Dracula colors for [Tmux](https://github.com/tmux/tmux), based on the structure of [egel/tmux-gruvbox](https://github.com/egel/tmux-gruvbox) and using the official [Dracula](https://draculatheme.com/) color palette (as used in [dracula/tmux](https://github.com/dracula/tmux)).

This is a lightweight status-bar oriented theme (similar to the original gruvbox plugin), **not** a full feature-rich replacement of the official `dracula/tmux` plugin (which includes many widgets: battery, CPU, weather, git, etc.).

## Installation

### Install via [TPM](https://github.com/tmux-plugins/tpm) (recommended)

Add plugin at the top list of TPM plugins list in `.tmux.conf` and select desired theme.

```tmux
# ~/.tmux.conf

set -g @plugin 'tmux-plugins/tpm' # mandatory
set -g @plugin 'tmux-plugins/tmux-sensible' # optional recommended

set -g @plugin 'YOUR_USERNAME/tmux-dracula'   # or path to this local repo
# set desired theme options...
set -g @tmux-dracula 'dark' # or 'dark256', 'light', 'light256'

# other plugins
...
```

Hit `prefix + I` to fetch the plugin and source it. Your Tmux should be updated with the theme at this point.

### Install manually

1. Clone the project to desired location

```bash
cd ~/projects/
git clone <this-repo-url>
```

2. Add theme at the top of your `~/.tmux.conf` config.

```tmux
# ~/.tmux.conf

run ~/projects/tmux-dracula/dracula-tpm.tmux
# set desired options...
set -g @tmux-dracula 'dark' # or 'dark256', 'light', 'light256'
```

## Configuration options

### Theme

* default value: `dark`

| Theme name | Color palette | Description |
| --- | --- | --- |
| dark | true-color (HEX) | Official Dracula dark palette |
| dark256 | 256 colors | Approximate 256-color mapping |
| light | true-color (HEX) | Light adaptation (inverted backgrounds) |
| light256 | 256 colors | 256-color light adaptation |

```tmux
set -g @tmux-dracula 'dark' # dark256, light, light256
```

### Transparent status-bar

* default value: `'false'`
* tmux >= 3.2 (experimental)

```tmux
set -g @tmux-dracula-statusbar-alpha 'true'
```

### Left Status (Section A)

* default value: `'#S'` (session name)

```tmux
set -g @tmux-dracula-left-status-a '#S' # tmux's session name
```

### Right Status (Section X)

* default value: `'%Y-%m-%d'`

```tmux
# set date in US notation
set -g @tmux-dracula-right-status-x '%m/%d/%Y' # e.g.: 01/31/2024

# or set date in EU notation
set -g @tmux-dracula-right-status-x '%d.%m.%Y' # e.g.: 30.01.2024
```

### Right Status (Section Y)

* default value: `'%H:%M'`

```tmux
# set US time format
set -g @tmux-dracula-right-status-y '%I:%M %p' # 09:54 PM
```

### Right Status (Section Z)

* default value: `'#h'` (hostname)

```tmux
# display hostname and enhance section with other plugin
set -g @tmux-dracula-right-status-z '#h #{tmux_mode_indicator}'
```

## Where to adjust colors further

If you want to fine-tune colors yourself, edit these files:

1. **Main color definitions (HEX / true-color)**  
   `src/palette_dracula_dark.sh`  
   `src/palette_dracula_light.sh`

2. **256-color approximations**  
   `src/palette_dracula_dark256.sh`  
   `src/palette_dracula_light256.sh`

3. **How colors are applied to status bar, windows, panes, messages, etc.**  
   `src/theme_dracula_dark.sh`  
   `src/theme_dracula_light.sh`  
   `src/theme_dracula_light256.sh`

The variables you will most often change are of the form:

- `col_bg`, `col_bg1`, `col_bg2`, `col_bg3` — backgrounds
- `col_fg`, `col_fg1`, `col_fg2`, `col_fg3` — foregrounds
- `col_yellow2`, `col_red2`, `col_blue2`, `col_purple`, `col_green` … — accents

After changing a palette file, reload the theme (or restart tmux).

## Development

To run project locally:

1. clone the repository to desired place
2. create a symlink to the cloned repository (best in the standard TPM plugin directory):

```bash
cd ~/.tmux/plugins/
ln -sf $HOME/projects/tmux-dracula/ tmux-dracula
```

3. and in `~/.tmux.conf` set

```tmux
set -g @plugin 'YOUR_USERNAME/tmux-dracula'
set -g @tmux-dracula 'dark'
```

## License

GPLv3 — original structure by Maciej Sypień (egel/tmux-gruvbox).  
Colors based on the Dracula theme (MIT).

## Credits

- Structure & plugin framework: [egel/tmux-gruvbox](https://github.com/egel/tmux-gruvbox)
- Color palette: [dracula/tmux](https://github.com/dracula/tmux) / [draculatheme.com](https://draculatheme.com/)
