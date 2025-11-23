#!/bin/bash
set -eo pipefail
export PATH=$PATH:/sbin:/usr/sbin

echo "📦 Installing prerequisites..."
apt install -y curl gstreamer1.0-pipewire wget xvfb libgtk-3-0 libnotify4 libglib2.0-0 libnss3 libxss1 libasound2 || true

# --- Check if RustDesk is already installed ---
if dpkg -s rustdesk &>/dev/null; then
  echo "⚠️  RustDesk is already installed."
  read -rp "Do you want to overwrite the current installation? (y/N): " ANSWER
  ANSWER=${ANSWER,,}  # convert to lowercase
  if [[ "$ANSWER" != "y" && "$ANSWER" != "yes" ]]; then
    echo "⏹️  Skipping RustDesk installation."
    SKIP_RUSTDESK=true
  else
    echo "🧹 Removing existing RustDesk installation..."
    apt remove -y rustdesk || true
    SKIP_RUSTDESK=false
  fi
else
  SKIP_RUSTDESK=false
fi

if [ "$SKIP_RUSTDESK" = false ]; then
  echo "⬇️  Downloading RustDesk..."
  wget -q -O /tmp/rustdesk.deb https://github.com/rustdesk/rustdesk/releases/download/1.4.3/rustdesk-1.4.3-x86_64.deb

  echo "📦 Installing RustDesk..."
  if ! apt install -y /tmp/rustdesk.deb; then
    echo "🔧 Fixing dependencies..."
    apt-get -f install -y rustdesk || true
    apt install -y /tmp/rustdesk.deb
  fi
  rm -f /tmp/rustdesk.deb
  echo "✅ RustDesk installation complete."
fi

echo "📦 Installing Chromium..."
apt install -y chromium || true
echo "✅ Chromium installation complete."

echo "📦 Installing Microsoft TrueType fonts (ttf-mscorefonts-installer)..."

echo "deb http://deb.debian.org/debian bookworm contrib non-free" > /etc/apt/sources.list.d/bookworm-fonts.list

apt update -y

echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | debconf-set-selections
apt install -y ttf-mscorefonts-installer

# Clean up the temporary repo
rm -f /etc/apt/sources.list.d/bookworm-fonts.list
apt update -y

# Rebuild font cache
fc-cache -fv >/dev/null 2>&1 || true

echo "✅ MS Fonts installation complete."

