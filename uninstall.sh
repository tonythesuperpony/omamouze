#!/usr/bin/env bash

echo "Uninstalling OmaMouze..."

# Disable plugin
omarchy plugin disable omamouze || true

# Remove files
rm -rf ~/.config/omarchy/plugins/omamouze
rm -f ~/.local/bin/omamouze
rm -f ~/.local/share/applications/omamouze.desktop

# Clean state and config (optional, but good practice)
read -p "Do you want to remove OmaMouze configuration and settings as well? [y/N]: " clean_cfg
if [[ "$clean_cfg" =~ ^[Yy]$ ]]; then
    rm -rf ~/.config/omamouze
    rm -rf ~/.local/state/omamouze
    
    # Remove bindings from Hyprland config
    sed -i '/-- BEGIN omamouze/,/-- END omamouze/d' ~/.config/hypr/bindings.lua
    echo "Settings removed."
fi

echo "Restarting Omarchy shell..."
omarchy restart shell

echo ""
echo "OmaMouze has been completely uninstalled."
