# Claude Code Migration Prompt

Paste this as your first message when you open Claude Code inside ~/dotfiles:

---

I'm setting up a dotfiles repo at ~/dotfiles using GNU Stow on Arch Linux with Hyprland.

Please do the following:

1. List everything relevant in ~/.config — I want to see what's there before you touch anything.

2. For each app that has a config (hyprland, waybar, rofi, dunst, kitty/alacritty, etc.), create the correct stow package structure inside ~/dotfiles and move the config files into it. The structure should be:
   ~/dotfiles/<app>/.config/<app-config-dir>/

3. Run `stow <package>` for each one to create the symlinks back to ~/.config.

4. Verify the symlinks exist and point to the right place.

5. Update the CLAUDE.md "Packages in this repo" section with whatever you added.

Do one app at a time and confirm each step worked before moving to the next. If anything looks risky or ambiguous, stop and ask me.
