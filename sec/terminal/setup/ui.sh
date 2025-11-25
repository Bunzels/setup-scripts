set -eo pipefail
export PATH=$PATH:/sbin:/usr/sbin

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
disable_autostart "print-applet"   # typical name
disable_autostart "system-config-printer-applet"  # fallback name

echo "✅ Blueman and Print Queue applets disabled for user $USER."


# -----------------------------------------------------
# KIOSK DESKTOP SHORTCUT
# -----------------------------------------------------

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

echo "✅ DeerNET desktop shortcut created at $SHORTCUT_FILE (Mint-compatible format)"


# -----------------------------------------------------
# NUMLOCK ENABLED BY DEFAULT (LightDM + Cinnamon)
# -----------------------------------------------------

echo "🔧 Enabling NumLock by default..."

# 1. Install numlockx
apt-get update -y
apt-get install -y numlockx

# 2. Enable NumLock at LightDM login screen
LIGHTDM_CONF="/etc/lightdm/lightdm.conf"
if ! grep -q "greeter-setup-script" "$LIGHTDM_CONF" 2>/dev/null; then
    echo "[Seat:*]" >> "$LIGHTDM_CONF"
    echo "greeter-setup-script=/usr/bin/numlockx on" >> "$LIGHTDM_CONF"
else
    sed -i 's|^greeter-setup-script=.*|greeter-setup-script=/usr/bin/numlockx on|' "$LIGHTDM_CONF"
fi

echo "✅ NumLock enabled at login screen"

# 3. Enable NumLock for Cinnamon sessions (both the current user & kiosk user)

make_autostart_numlock() {
    local target_home="$1"
    mkdir -p "$target_home/.config/autostart"

    cat <<EOF > "$target_home/.config/autostart/numlock.desktop"
[Desktop Entry]
Type=Application
Exec=numlockx on
Name=NumLock On
X-GNOME-Autostart-enabled=true
EOF

    chown -R "$(basename "$target_home")":"$(basename "$target_home")" "$target_home/.config/autostart" 2>/dev/null || true
}

# Autostart for kiosk user:
KIOSK_HOME="/home/kiosk"
mkdir -p "$KIOSK_HOME/.config/autostart"

cat <<EOF > "$KIOSK_HOME/.config/autostart/numlock.desktop"
[Desktop Entry]
Type=Application
Exec=numlockx on
Name=NumLock On
X-GNOME-Autostart-enabled=true
EOF

chown -R kiosk:kiosk "$KIOSK_HOME/.config"

# -----------------------------------------------------
# CINNAMON POWER / SCREENSAVER CONFIG
# -----------------------------------------------------

KIOSK_HOME="/home/kiosk"
KIOSK_DCONF_DIR="$KIOSK_HOME/.config/dconf"
mkdir -p "$KIOSK_DCONF_DIR"
DB_FILE="$KIOSK_DCONF_DIR/user"

echo "🔧 Configuring power/screen settings for kiosk user..."

# Generate dconf override script
cat <<'EOF' > /tmp/kiosk_dconf.ini
[org/cinnamon/desktop/screensaver]
lock-enabled=false
idle-activation-enabled=true
idle-delay=900  # 900 sec = 15 min

[org/cinnamon/settings-daemon/plugins/power]
sleep-inactive-ac-type='nothing'
sleep-inactive-ac-timeout=0
sleep-inactive-battery-type='nothing'
sleep-inactive-battery-timeout=0
idle-dim-ac=false
idle-dim-battery=false
sleep-display-ac=1800      # 1800 sec = 30 min
sleep-display-battery=1800

[org/cinnamon/desktop/session]
idle-delay=900   # 15 min

[org/cinnamon/desktop/keybindings/media-keys]
# Disable Windows/Super key opening menu
home=['']  # Removes binding for opening menu (Super_L)
EOF

# Load settings into kiosk user's dconf DB
sudo -u kiosk dconf load / < /tmp/kiosk_dconf.ini

echo "✅ Screen timeout, screen off, lock disabled, and sleep disabled."


# -----------------------------------------------------
# DISABLE CINNAMON START MENU ON WINDOWS/SUPER KEY
# -----------------------------------------------------

echo "🔧 Disabling Cinnamon menu from Super key..."

sudo -u kiosk dconf write /org/cinnamon/desktop/keybindings/media-keys/home "['']"

echo "✅ Windows key no longer opens the start menu."


echo "✅ NumLock enabled for all Cinnamon sessions"
echo "🎉 Setup complete."
