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

echo "✅ Blueman and Print Queue applets disabled."


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

mkdir -p "$USER_HOME/.config/autostart"

cat <<EOF > "$USER_HOME/.config/autostart/numlock.desktop"
[Desktop Entry]
Type=Application
Exec=numlockx on
Name=NumLock On
X-GNOME-Autostart-enabled=true
EOF

chown -R kiosk:kiosk /home/kiosk

echo "✅ NumLock enabled inside Cinnamon sessions."


# =====================================================
# CINNAMON + GNOME POWER/LOCK SETTINGS (dconf compile)
# =====================================================

echo "🔧 Applying Cinnamon/Power/Lock configuration..."

KIOSK_DCONF_BASE="/home/kiosk/.config/dconf"
KIOSK_DCONF_DIR="$KIOSK_DCONF_BASE/user.d"

mkdir -p "$KIOSK_DCONF_DIR"

chown -R kiosk:kiosk /home/kiosk/.config
chown -R kiosk:kiosk /home/kiosk/.config/dconf

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

[org/gnome/desktop/screensaver]
lock-enabled=false

[org/gnome/settings-daemon/plugins/power]
sleep-inactive-ac-type='nothing'
sleep-inactive-battery-type='nothing'
EOF

sudo -u kiosk dconf compile "$KIOSK_DCONF_BASE/user" "$KIOSK_DCONF_DIR"

echo "✅ dconf database compiled successfully."


# =====================================================
# DISABLE LOCK ON SUSPEND (AccountsService)
# =====================================================

echo "🔧 Disabling lock-on-suspend..."

mkdir -p /var/lib/AccountsService/users
cat <<EOF >/var/lib/AccountsService/users/kiosk
[User]
SystemAccount=false
XSession=cinnamon
LockOnSuspend=false
EOF

chmod 644 /var/lib/AccountsService/users/kiosk

echo "✅ Lock on suspend disabled."


# =====================================================
# DISABLE ALL SYSTEM SLEEP
# =====================================================

echo "🔧 Disabling all system sleep modes..."

systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target || true

echo "✅ System sleep disabled."


# =====================================================
# NIGHTLY REBOOT AT 2 AM
# =====================================================

echo "🔧 Adding nightly reboot cron job..."

cat <<EOF >/etc/cron.d/kiosk-reboot
# Reboot every day at 2:00 AM
0 2 * * * root /sbin/shutdown -r now
EOF

chmod 644 /etc/cron.d/kiosk-reboot

echo "✅ Nightly 2 AM reboot scheduled."


# =====================================================
# POLKIT RULE — FORCE ALLOW REBOOT/SHUTDOWN FOR KIOSK
# =====================================================

echo "🔧 Adding polkit override for reboot/shutdown..."

cat <<'EOF' >/etc/polkit-1/rules.d/49-kiosk-reboot.rules
polkit.addRule(function(action, subject) {

    if (subject.user == "kiosk") {

        if (
            action.id == "org.freedesktop.login1.reboot" ||
            action.id == "org.freedesktop.login1.reboot-multiple-sessions" ||
            action.id == "org.freedesktop.login1.reboot-ignore-inhibit" ||
            action.id == "org.freedesktop.login1.power-off" ||
            action.id == "org.freedesktop.login1.power-off-multiple-sessions" ||
            action.id == "org.freedesktop.login1.power-off-ignore-inhibit"
        ) {
            return polkit.Result.YES;
        }
    }
});
EOF

chmod 644 /etc/polkit-1/rules.d/49-kiosk-reboot.rules

echo "✅ Kiosk user can reboot/shutdown from the menu."


# =====================================================
# USB BLOCKING FOR KIOSK USER ONLY (POLKIT)
# =====================================================

echo "🔧 Blocking USB flash drives for kiosk user..."

cat <<'EOF' >/etc/polkit-1/rules.d/60-kiosk-block-usb.rules
polkit.addRule(function(action, subject) {

    if (subject.user == "kiosk") {

        // Block all filesystem mounts
        if (action.id.indexOf("org.freedesktop.udisks2.filesystem-mount") === 0 ||
            action.id.indexOf("org.freedesktop.udisks2.encrypted-unlock") === 0 ||
            action.id.indexOf("org.freedesktop.udisks2.loop-setup") === 0) {
            return polkit.Result.NO;
        }

        // Block MTP phones (Android, cameras)
        if (action.id.indexOf("org.freedesktop.udisks2.eject-media") === 0 ||
            action.id.indexOf("org.freedesktop.udisks2.eject-media-other-seat") === 0) {
            return polkit.Result.NO;
        }
    }
});
EOF

chmod 644 /etc/polkit-1/rules.d/60-kiosk-block-usb.rules

echo "✅ USB flash drives blocked for kiosk user."


# =====================================================
# DONE
# =====================================================

echo "🎉 Setup complete — full kiosk lockdown, power control, and USB blocking applied."
