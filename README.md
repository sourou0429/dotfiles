# Kuroiko's Dotfiles

This repository contains my personal configuration files (dotfiles) for a customized Linux environment, primarily focused on the Wayland compositor [River](https://github.com/riverwm/river) and the Neovim text editor. These configurations aim for a minimal yet highly functional and aesthetically pleasing setup, often utilizing the Gruvbox color scheme.

## Overview

Here's a breakdown of the main components configured in this repository:

*   **Window Manager**: [River](https://github.com/riverwm/river) - A dynamic tiling Wayland compositor.
*   **Terminal Emulator**: [Kitty](https://sw.kovidgoyal.net/kitty/) - Fast, feature-rich, GPU-accelerated terminal.
*   **Text Editor**: [Neovim](https://neovim.io/) - Highly customized Lua-based configuration (`grimmvim`) with lazy loading, Language Server Protocol (LSP) integration, completion, and a wide array of plugins for coding, UI enhancements, and utilities.
*   **Status Bars**:
    *   [Polybar](https://github.com/polybar/polybar) - Configured for displaying system information, workspaces, audio, battery, and date.
    *   [Waybar](https://github.com/Alexays/Waybar) - A highly customizable Wayland bar with modules for workspaces, clock, CPU, memory, network, battery, Bluetooth, and more.
*   **Shell**: [Zsh](https://www.zsh.org/) - Enhanced with custom scripts for system updates (`arch_update.sh`), health checks (`health_check.sh`), and an ASCII art startup message (`ascii_startup.zsh`).
*   **Notifications**: [Mako](https://wayland.emersion.fr/mako/) - A lightweight Wayland notification daemon.
*   **System Information**: [Neofetch](https://github.com/dylanaraps/neofetch) - Custom configuration for displaying system details with an Arch Linux ASCII logo.
*   **Terminal Multiplexer**: [Tmux](https://github.com/tmux/tmux) - For managing multiple terminal sessions.
*   **Application Launcher / Utilities**: [Rofi](https://github.com/davatorium/rofi) - Used for launching applications (`drun`), power management, Bluetooth device management, Wi-Fi network selection, and clipboard history.

## Keybindings (River)

The primary modifier key for River is `Super` (Windows key). Some notable keybindings include:

*   `Super + Return`: Launch Kitty terminal (with Tmux).
*   `Super + Shift + Return`: Launch Kitty terminal (without Tmux).
*   `Super + E`: Open Dolphin file manager.
*   `Super + W`: Open Firefox web browser.
*   `Super + R`: Launch Rofi application launcher.
*   `Super + Escape`: Launch Rofi power menu.
*   `Super + Q`: Close focused window.
*   `Super + Control + L`: Lock screen with `swaylock`.
*   `Super + J/K`: Focus next/previous view.
*   `Super + H/L`: Adjust main ratio of `rivertile` layout.
*   `Super + Space`: Toggle float for focused window.
*   `Super + F`: Toggle fullscreen for focused window.

Media keys are also configured for volume control (`pamixer`), media playback (`playerctl`), and screen brightness (`brightnessctl`).

## Installation

To use these dotfiles, you typically clone the repository and then symlink the configuration files to their respective locations in your home directory (e.g., `~/.config/`).

```bash
# Example for Neovim
git clone https://github.com/yourusername/dotfiles.git ~/.dotfiles
ln -s ~/.dotfiles/.config/nvim ~/.config/nvim
```

**Note**: Some configurations might require specific fonts (e.g., Nerd Fonts like Hack Nerd Font) or additional dependencies to be installed.

## Screenshots

*(Add screenshots here to showcase the setup)*
