#!/usr/bin/env bash
# enable-sudo-interactive.sh
# Re-runs itself as root via `su -c` (interactive password prompt),
# then installs sudo and grants 'administrator' sudo privileges.
clear

set -euo pipefail

TARGET_USER="administrator"
CREATE_NOPASSWD=false   # set to true if you want NOPASSWD entry created

# If not root, re-exec via su so su prompts for password interactively.
if [[ $EUID -ne 0 ]]; then
  echo "DeerNET Terminal Setup Script"
  echo "This script requires root. You will be prompted for the root password."
  # Re-exec script under su -c so the current terminal remains the TTY for password entry.
  # Use printf to build the command safely for many shells.
  exec su -c "bash \"$(printf '%q' "$0")\" -- \"$@\""
fi

# ---- running as root from here ----
echo "Running as root: installing sudo (if missing) and granting sudo to user '$TARGET_USER'..."

# Basic checks
if ! id "$TARGET_USER" &>/dev/null; then
  echo "User '$TARGET_USER' does not exist. Create it first or set TARGET_USER to a valid username."
  exit 1
fi

apt-get update -y

# Install sudo if not present
if ! command -v sudo &>/dev/null; then
  echo "Installing sudo..."
  apt-get install -y sudo
else
  echo "sudo is already installed."
fi

apt-get update -y
apt install -y passwd

# Add user to sudo group (Debian recommended)
if id -nG "$TARGET_USER" | grep -qw sudo; then
  echo "User '$TARGET_USER' is already in the sudo group."
else
  /usr/sbin/usermod -aG sudo "$TARGET_USER"
  echo "Added '$TARGET_USER' to sudo group."
fi

#apt purge -y rustdesk
#rm -rf /root/.config/rustdesk /home/*/.config/rustdesk

wget -qO /tmp/software.sh https://raw.githubusercontent.com/Bunzels/setup-scripts/main/sec/terminal/setup/software.sh
sed -i 's/\r$//' /tmp/software.sh
bash /tmp/software.sh
rm /tmp/software.sh

clear

wget -qO /tmp/user.sh https://raw.githubusercontent.com/Bunzels/setup-scripts/main/sec/terminal/setup/user.sh
sed -i 's/\r$//' /tmp/user.sh
bash /tmp/user.sh
rm /tmp/user.sh

clear

wget -qO /tmp/scripts.sh https://raw.githubusercontent.com/Bunzels/setup-scripts/main/sec/terminal/setup/scripts.sh
sed -i 's/\r$//' /tmp/scripts.sh
bash /tmp/scripts.sh
rm /tmp/scripts.sh

clear

wget -qO /tmp/ui.sh https://raw.githubusercontent.com/Bunzels/setup-scripts/main/sec/terminal/setup/ui.sh
sed -i 's/\r$//' /tmp/ui.sh
bash /tmp/ui.sh
rm /tmp/ui.sh

clear

# wget -qO /tmp/network.sh https://raw.githubusercontent.com/Bunzels/setup-scripts/main/sec/terminal/setup/network.sh
# sed -i 's/\r$//' /tmp/network.sh
# bash /tmp/network.sh
# rm /tmp/network.sh

# clear

rm -- "$0"

systemctl reboot
