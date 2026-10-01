# OmaMouze

OmaMouze is a lightweight, fully integrated mouse management plugin for the Omarchy desktop environment (Hyprland + Quickshell). It allows you to configure your mouse's DPI, pointer sensitivity, cursor size, scroll speed, and assign custom actions to any of your mouse buttons, straight from your top bar.

It's built with native Hyprland support, which means adjustments take effect immediately with zero overhead!

## Features

- **DPI & Sensitivity Controls:** Tune your pointer speed with hardware base DPI profiles and software sensitivity multipliers.
- **Acceleration Profiles:** Switch between "Flat" (raw 1:1 input) and "Adaptive" (curve acceleration).
- **Auto-Detection:** Automatically discovers all your connected mouse devices, excluding virtual inputs.
- **Scroll Speed:** Instantly adjust wheel scrolling speed (lines per scroll).
- **Cursor Size:** Quickly change your mouse pointer size from the panel (applies to both X11/GTK and Wayland).
- **Button Assignments:** Remap your extra mouse buttons (thumb buttons, middle click, etc.) with pre-configured actions like media controls, workspace switching, or run your own custom shell commands!

## Installation

You can install OmaMouze with the following simple command:

```bash
git clone https://github.com/tonythesuperpony/omamouze.git
cd omamouze
./install.sh
```

During installation, you will be prompted to choose where you want the OmaMouze icon to appear on your Omarchy bar (left, center, or right). The default is `right`.

## Uninstallation

To completely remove OmaMouze from your system:

```bash
cd omamouze
./uninstall.sh
```

You'll be asked if you also want to remove your saved mouse configuration files.

## Dependencies

OmaMouze uses standard Linux / Omarchy tools. Make sure you have the following installed (these should be included in your Omarchy install by default):
- `hyprctl` (for window manager controls)
- `gsettings` (for cursor sizes)
- `wtype` (for emulating keyboard presses in custom bindings)
- `playerctl` and `wpctl` (for media controls)

## Usage

Simply click the mouse icon in your Omarchy bar to reveal the control panel. 

- **To assign a button:** Click on any of the listed mouse buttons. A panel will appear allowing you to select a quick preset or type a custom command.
- **To switch devices:** Click the connected device name at the top to quickly jump between multiple connected mice.
