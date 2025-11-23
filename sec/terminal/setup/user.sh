#!/usr/bin/env bash
set -e
export PATH=$PATH:/sbin:/usr/sbin

KIOSK_USER="kiosk"
KIOSK_HOME="/home/$KIOSK_USER"

echo "👤 Creating non-privileged user '$KIOSK_USER'..."

# Create user if it doesn't exist
if id "$KIOSK_USER" &>/dev/null; then
  echo "User $KIOSK_USER already exists."
else
  useradd -m -s /bin/bash "$KIOSK_USER"
  passwd -d "$KIOSK_USER"         # no password login
  usermod -L "$KIOSK_USER"        # lock password so it can't be used remotely
fi

# Ensure no sudo/admin access
deluser "$KIOSK_USER" sudo 2>/dev/null || true
deluser "$KIOSK_USER" adm 2>/dev/null || true

echo "✅ User created (no password, no sudo privileges)."

# --- LightDM autologin setup ---
if [ -d /etc/lightdm ]; then
  echo "🖥️ Configuring LightDM autologin..."

  mkdir -p /etc/lightdm/lightdm.conf.d

  cat >/etc/lightdm/lightdm.conf.d/50-kiosk-autologin.conf <<EOF
[Seat:*]
autologin-user=$KIOSK_USER
autologin-user-timeout=0
user-session=cinnamon
EOF

  echo "✅ LightDM autologin configured for '$KIOSK_USER'."
else
  echo "⚠️ LightDM not found — skipping autologin config."
fi

# Optional: disable lock/switch user UI (if using Cinnamon)
if [ -d "$KIOSK_HOME" ]; then
  mkdir -p "$KIOSK_HOME/.config/autostart"
  chown -R "$KIOSK_USER:$KIOSK_USER" "$KIOSK_HOME"
fi

echo "✅ Kiosk user setup complete. Reboot to apply autologin."
