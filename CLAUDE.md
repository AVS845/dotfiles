# Dotfiles

This repo manages my Arch Linux + Hyprland configuration using GNU Stow.

## Structure

Each top-level folder is a "package" for one app. Its contents mirror the path
from $HOME. For example:

```
hyprland/.config/hypr/hyprland.conf     →  ~/.config/hypr/hyprland.conf
quickshell/.config/quickshell/shell.qml →  ~/.config/quickshell/shell.qml
```

To symlink a package: `stow <package>` from ~/dotfiles  
To remove a package: `stow -D <package>`

## My Setup

- **Compositor:** Hyprland (Wayland)
- **Bar/Launcher/Notifications:** Quickshell
- **Terminal:** Kitty
- **Lock Screen:** Hyprlock
- **Color scheme:** Pywal (automatic from wallpaper)

## Packages in this repo

- `hyprland` — hyprland.conf, hyprlock.conf, hyprpaper.conf, shaders, wallpaper
- `quickshell` — shell.qml, scripts/ (bar, launcher, notifications, pywal integration)
- `kitty` — kitty.conf, startup.conf
- `btop` — btop.conf, themes
- `fastfetch` — config.jsonc, small.jsonc
- `nvim` — full LazyVim config (init.lua, lua/, plugins)
- `git` — .gitconfig, .config/git/ignore

## Goals

- Keep colors/fonts consistent across all apps
- Minimal and functional — no unnecessary animations
- Easy to restore on a fresh Arch install

## Notes for Claude

- When changing a color or font, update ALL configs that reference it
- Prefer variables/includes where the app supports them
- Don't touch ~/.config directly — always work inside this repo and stow
- If a new app config is added, create its stow package structure and note it above
