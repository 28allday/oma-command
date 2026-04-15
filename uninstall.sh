#!/bin/bash
set -euo pipefail

# OMA-COMMAND Uninstaller

GAME_NAME="oma-command"
DISPLAY_NAME="OMA-COMMAND"

INSTALL_DIR="$HOME/.local/share/$GAME_NAME"
DESKTOP_FILE="$HOME/.local/share/applications/$GAME_NAME.desktop"
ICON_DIR="$HOME/.local/share/icons/hicolor"

echo "=== Uninstalling $DISPLAY_NAME ==="

# Remove desktop entry
if [ -f "$DESKTOP_FILE" ]; then
    rm "$DESKTOP_FILE"
    echo "Removed desktop entry"
fi

# Remove icons
for size in 16 32 48 64 128 256 512; do
    local_icon="$ICON_DIR/${size}x${size}/apps/$GAME_NAME.png"
    [ -f "$local_icon" ] && rm "$local_icon"
done
[ -f "$ICON_DIR/scalable/apps/$GAME_NAME.svg" ] && rm "$ICON_DIR/scalable/apps/$GAME_NAME.svg"
echo "Removed icons"

# Remove game files
if [ -d "$INSTALL_DIR" ]; then
    rm -rf "$INSTALL_DIR"
    echo "Removed game files"
fi

# Update icon cache
if command -v gtk-update-icon-cache &>/dev/null; then
    gtk-update-icon-cache -f -t "$ICON_DIR" 2>/dev/null || true
fi

# Restart walker
if command -v omarchy-restart-walker &>/dev/null; then
    omarchy-restart-walker 2>/dev/null || true
fi

echo "=== $DISPLAY_NAME uninstalled ==="
