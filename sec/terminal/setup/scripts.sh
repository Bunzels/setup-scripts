#!/usr/bin/env bash
set -e
export PATH=$PATH:/sbin:/usr/sbin

cd /home/kiosk
rm -rf Scripts
mkdir -p Scripts
cd Scripts

# Download scripts to their proper filenames
wget -q -O DeerNET.sh https://raw.githubusercontent.com/Bunzels/setup-scripts/main/sec/terminal/scripts/DeerNET.sh
sed -i 's/\r$//' DeerNET.sh
wget -q -O Startup.sh https://raw.githubusercontent.com/Bunzels/setup-scripts/main/sec/terminal/scripts/Startup.sh
sed -i 's/\r$//' Startup.sh
wget -q -O Menu.sh https://raw.githubusercontent.com/Bunzels/setup-scripts/main/sec/terminal/scripts/Menu.sh
sed -i 's/\r$//' Menu.sh

# Make them executable
chmod +x DeerNET.sh Startup.sh Menu.sh

cd /home/administrator/Downloads

wget -q -O RustDeskSetup.sh https://raw.githubusercontent.com/Bunzels/setup-scripts/main/sec/terminal/scripts/RustDeskSetup.sh
sed -i 's/\r$//' RustDeskSetup.sh
wget -q -O Network.sh https://raw.githubusercontent.com/Bunzels/setup-scripts/main/sec/terminal/setup/network.sh
sed -i 's/\r$//' RustDeskSetup.sh

chmod +x RustDeskSetup.sh Network.sh

echo "✅ Terminal scripts downloaded and ready"

# --- Create autostart entry for Startup.sh ---
AUTOSTART_DIR="/home/kiosk/.config/autostart"
AUTOSTART_FILE="$AUTOSTART_DIR/Startup.desktop"

mkdir -p "$AUTOSTART_DIR"

cat <<EOF > "$AUTOSTART_FILE"
[Desktop Entry]
Type=Application
Exec=/home/kiosk/Scripts/Startup.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Startup
Comment=Launch DeerNET kiosk and configure shortcut
EOF

chmod +x "$AUTOSTART_FILE"
chown -R kiosk:kiosk "$AUTOSTART_DIR"

echo "✅ Autostart entry created at $AUTOSTART_FILE"

# Define the cron job
CRON_JOB="0 1 * * * /sbin/reboot"

# Check if the job already exists
if crontab -l 2>/dev/null | grep -qF "$CRON_JOB"; then
    echo "✅ Cron job already exists."
else
    echo "🧩 Adding daily reboot cron job..."
    # Add the job while preserving existing crontab entries
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    echo "✅ Cron job added: $CRON_JOB"
fi
