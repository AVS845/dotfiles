# Dotfiles

This repo manages my Arch Linux + Hyprland configuration using GNU Stow.

## Structure

Each top-level folder is a "package" for one app. Its contents mirror the path
from $HOME. For example:

```
hyprland/.config/hypr/hyprland.conf  →  ~/.config/hypr/hyprland.conf
waybar/.config/waybar/config          →  ~/.config/waybar/config
```

To symlink a package: `stow <package>` from ~/dotfiles  
To remove a package: `stow -D <package>`

## My Setup

- **Compositor:** Hyprland (Wayland)
- **Bar:** Waybar
- **Launcher:** Wofi
- **Terminal:** Kitty
- **Notifications:** (TBD)
- **Color scheme:** (update this — e.g. Catppuccin Mocha, Tokyo Night, etc.)

## Packages in this repo

- `hyprland` — hyprland.conf, hyprlock.conf, hyprpaper.conf, launcher.sh, shaders, wallpaper
- `waybar` — config.jsonc, style.css
- `kitty` — kitty.conf, startup.conf
- `wofi` — config, style.css (launcher)
- `btop` — btop.conf, themes
- `fastfetch` — config.jsonc, small.jsonc
- `nvim` — full LazyVim config (init.lua, lua/, plugins)
- `git` — .gitconfig, .config/git/ignore
- `quickshell` — shell.qml, scripts/, colors/ (pywal integration)

## Goals

- Keep colors/fonts consistent across all apps
- Minimal and functional — no unnecessary animations
- Easy to restore on a fresh Arch install

## Notes for Claude

- When changing a color or font, update ALL configs that reference it
- Prefer variables/includes where the app supports them
- Don't touch ~/.config directly — always work inside this repo and stow
- If a new app config is added, create its stow package structure and note it above
