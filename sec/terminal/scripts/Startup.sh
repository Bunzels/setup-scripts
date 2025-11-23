#!/usr/bin/env bash
set -euo pipefail

# Wait for Cinnamon and DBus to be ready
sleep 3

# --- Disable unwanted keys ---
xmodmap -e 'keycode 70=Escape' 2>/dev/null || true   # F4
xmodmap -e 'keycode 133=Escape' 2>/dev/null || true  # Windows key

# --- Clear Chromium cache ---
rm -rf ~/.cache/chromium 2>/dev/null || true

# --- Ensure keyboard shortcut Ctrl+Alt+M exists ---
MENU_SCRIPT="$HOME/Scripts/Menu.sh"
if [ -x "$MENU_SCRIPT" ]; then
    # Wait for Cinnamon’s DBus session to be ready
    export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"

    CURRENT_KEYS=$(gsettings get org.cinnamon.desktop.keybindings custom-list 2>/dev/null || echo "@as []")

    # Add 'custom0' if it's not already present
    if [[ "$CURRENT_KEYS" != *"custom0"* ]]; then
        gsettings set org.cinnamon.desktop.keybindings custom-list "['custom0']"
    fi

    gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/custom-keybindings/custom0/ name 'Open Menu'
    gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/custom-keybindings/custom0/ command "bash $MENU_SCRIPT"
    gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/custom-keybindings/custom0/ binding "['<Control><Alt>m']"
fi

# --- Launch DeerNET in kiosk mode ---
chromium --noerrdialogs --disable-session-crashed-bubble --kiosk https://deernet.bunzels.com &



