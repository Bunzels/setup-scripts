# #!/bin/bash
# # Disable Blueman and Print Queue applets from autostart (Cinnamon/Debian)

# set -eo pipefail
# export PATH=$PATH:/sbin:/usr/sbin

# USER_AUTOSTART="$HOME/.config/autostart"
# SYSTEM_AUTOSTART="/etc/xdg/autostart"

# mkdir -p "$USER_AUTOSTART"

# disable_autostart() {
#     local name="$1"
#     local src="$SYSTEM_AUTOSTART/$name.desktop"
#     local dest="$USER_AUTOSTART/$name.desktop"

#     if [[ -f "$src" ]]; then
#         echo "Disabling $name autostart..."
#         cp "$src" "$dest"
#         if grep -q '^Hidden=' "$dest"; then
#             sed -i 's/^Hidden=.*/Hidden=true/' "$dest"
#         else
#             echo "Hidden=true" >> "$dest"
#         fi
#     else
#         echo "Warning: $src not found — skipping."
#     fi
# }

# disable_autostart "blueman"
# disable_autostart "print-applet"   # typical name
# disable_autostart "system-config-printer-applet"  # fallback name

# echo "✅ Blueman and Print Queue applets disabled for user $USER."


# USER_HOME="/home/kiosk"
# DESKTOP_DIR="$USER_HOME/Desktop"
# SHORTCUT_FILE="$DESKTOP_DIR/DeerNET.desktop"

# mkdir -p "$DESKTOP_DIR"

# cat <<EOF > "$SHORTCUT_FILE"
# #!/usr/bin/env xdg-open
# [Desktop Entry]
# Name=DeerNET
# Exec=chromium --kiosk https://deernet.bunzels.com
# Comment=
# Terminal=false
# PrefersNonDefaultGPU=false
# Icon=chromium
# Type=Application
# EOF

# chmod +x "$SHORTCUT_FILE"
# chown kiosk:kiosk "$SHORTCUT_FILE"

# echo "✅ DeerNET desktop shortcut created at $SHORTCUT_FILE (Mint-compatible format)"

#!/bin/bash
# Disable Blueman and Print Queue applets from autostart (Cinnamon/Debian)

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

echo "✅ NumLock enabled for all Cinnamon sessions"
echo "🎉 Setup complete."
