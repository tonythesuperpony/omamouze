#!/usr/bin/env bash
set -e

echo "Installing OmaMouze..."

# Create necessary directories
mkdir -p ~/.config/omarchy/plugins/omamouze/bin
mkdir -p ~/.local/bin
mkdir -p ~/.local/share/applications

# Copy plugin files
cp plugin/BarWidget.qml ~/.config/omarchy/plugins/omamouze/
cp plugin/manifest.json ~/.config/omarchy/plugins/omamouze/
cp plugin/bin/omamouze-ctl ~/.config/omarchy/plugins/omamouze/bin/
chmod +x ~/.config/omarchy/plugins/omamouze/bin/omamouze-ctl

# Copy assets
cp assets/omamouze ~/.local/bin/
chmod +x ~/.local/bin/omamouze
cp assets/omamouze.desktop ~/.local/share/applications/

# Update desktop database
update-desktop-database ~/.local/share/applications/ &>/dev/null || true

# Prompt for bar section
echo ""
echo "Where would you like to display the OmaMouze icon on the Omarchy bar?"
echo "1) Left"
echo "2) Center"
echo "3) Right (Default)"
read -p "Select an option [1-3] (default: 3): " section_choice

SECTION="right"
case "$section_choice" in
  1) SECTION="left" ;;
  2) SECTION="center" ;;
  3|*) SECTION="right" ;;
esac

echo ""
echo "Enabling OmaMouze plugin on the $SECTION section..."
omarchy plugin enable omamouze --section "$SECTION"

echo "Restarting Omarchy shell to apply changes..."
omarchy restart shell

echo ""
echo "OmaMouze has been successfully installed!"
