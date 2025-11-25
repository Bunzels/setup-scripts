#!/bin/bash
set -eo pipefail
export PATH=$PATH:/sbin:/usr/sbin

# =====================================================
# DISABLE BLUEMAN + PRINT QUEUE APPLETS
# =====================================================

USER_AUTOSTART="$HOME/.config/autostart"
SYSTEM_AUTOSTART="/etc/xdg/autostart"

mkdir -p "$USER_AUTOSTART"

disable_autostart() {
    local name="$1"
    local src="$SYSTEM_AUTOSTART/$name.desktop"
    local dest="$USER_AUTOSTART/$name.desktop"

    if [[ -f "$src" ]]; then
        echo "Disabling $name autostart..."
        cp "$src" "$dest"
        if grep -q '^Hidden=' "$dest"; then
            sed -i 's/^Hidden=.*/Hidden=true/' "$dest"
        else
            echo "Hidden=true" >> "$dest"
        fi
    else
        echo "Warning: $src not found — skipping."
    fi
}

disable_autostart "blueman"
disable_autostart "print-applet"
disable_autostart "system-config-printer-applet"

echo "✅ Blueman and Print Queue applets disabled for user $USER."


# =====================================================
# KIOSK DESKTOP SHORTCUT
# =====================================================

USER_HOME="/home/kiosk"
DESKTOP_DIR="$USER_HOME/Desktop"
SHORTCUT_FILE="$DESKTOP_DIR/DeerNET.desktop"

mkdir -p "$DESKTOP_DIR"

cat <<EOF > "$SHORTCUT_FILE"
#!/usr/bin/env xdg-open
[Desktop Entry]
Name=DeerNET
Exec=chromium --kiosk https://deernet.bunzels.com
Comment=
Terminal=false
PrefersNonDefaultGPU=false
Icon=chromium
Type=Application
EOF

chmod +x "$SHORTCUT_FILE"
chown kiosk:kiosk "$SHORTCUT_FILE"

echo "✅ DeerNET desktop shortcut created."


# =====================================================
# NUMLOCK ENABLED (LightDM + Cinnamon)
# =====================================================

echo "🔧 Enabling NumLock..."

apt-get update -y
apt-get install -y numlockx

LIGHTDM_CONF="/etc/lightdm/lightdm.conf"
if ! grep -q "greeter-setup-script" "$LIGHTDM_CONF" 2>/dev/null; then
    echo "[Seat:*]" >> "$LIGHTDM_CONF"
    echo "greeter-setup-script=/usr/bin/numlockx on" >> "$LIGHTDM_CONF"
else
    sed -i 's|^greeter-setup-script=.*|greeter-setup-script=/usr/bin/numlockx on|' "$LIGHTDM_CONF"
fi

echo "✅ NumLock enabled at LightDM login screen."

# Cinnamon session NumLock autostart
mkdir -p "$USER_HOME/.config/autostart"

cat <<EOF > "$USER_HOME/.config/autostart/numlock.desktop"
[Desktop Entry]
Type=Application
Exec=numlockx on
Name=NumLock On
X-GNOME-Autostart-enabled=true
EOF

chown -R kiosk:kiosk "$USER_HOME/.config"

echo "✅ NumLock enabled inside Cinnamon sessions."


# =====================================================
# CINNAMON POWER / SCREENSAVER / SLEEP / SUPER KEY
# Using dconf *compiled database* — works without session
# =====================================================

echo "🔧 Applying Cinnamon configuration (dconf db compile)..."

KIOSK_DCONF_BASE="/home/kiosk/.config/dconf"
KIOSK_DCONF_DIR="$KIOSK_DCONF_BASE/user.d"

mkdir -p "$KIOSK_DCONF_DIR"

# Write settings file
cat <<'EOF' > "$KIOSK_DCONF_DIR/00-kiosk-settings"
[org/cinnamon/desktop/screensaver]
lock-enabled=false
idle-activation-enabled=true
idle-delay=900

[org/cinnamon/settings-daemon/plugins/power]
sleep-inactive-ac-type='nothing'
sleep-inactive-ac-timeout=0
sleep-inactive-battery-type='nothing'
sleep-inactive-battery-timeout=0
idle-dim-ac=false
idle-dim-battery=false
sleep-display-ac=1800
sleep-display-battery=1800

[org/cinnamon/desktop/session]
idle-delay=900

[org/cinnamon/desktop/keybindings/media-keys]
home=['']
EOF

# Compile dconf database manually
sudo -u kiosk dconf compile "$KIOSK_DCONF_BASE/user" "$KIOSK_DCONF_DIR"

echo "✅ Cinnamon settings applied (no D-Bus required)."
echo "   – Screensaver: 15 minutes"
echo "   – Screen off: 30 minutes"
echo "   – Lock disabled"
echo "   – Sleep disabled"
echo "   – Windows/Super key disabled"


# =====================================================
# DONE
# =====================================================

echo "🎉 Setup complete."
