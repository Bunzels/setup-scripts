#!/usr/bin/env bash
set -e
export PATH=$PATH:/sbin:/usr/sbin

cd /home/kiosk
rm -rf Scripts
mkdir -p Scripts
cd Scripts

# Download scripts to their proper filenames
wget -q --header="Authorization: Bearer wzf68i5wkX" -O DeerNET.sh https://dn.bunzserv.com/terminal/scripts/DeerNET.sh
sed -i 's/\r$//' DeerNET.sh
wget -q --header="Authorization: Bearer wzf68i5wkX" -O Startup.sh https://dn.bunzserv.com/terminal/scripts/Startup.sh
sed -i 's/\r$//' Startup.sh
wget -q --header="Authorization: Bearer wzf68i5wkX" -O Menu.sh https://dn.bunzserv.com/terminal/scripts/Menu.sh
sed -i 's/\r$//' Menu.sh

# Make them executable
chmod +x DeerNET.sh Startup.sh Menu.sh

cd /home/administrator/Downloads

wget -q --header="Authorization: Bearer wzf68i5wkX" -O RustDeskSetup.sh https://dn.bunzserv.com/terminal/scripts/RustDeskSetup.sh
sed -i 's/\r$//' RustDeskSetup.sh
wget -q --header="Authorization: Bearer wzf68i5wkX" -O Network.sh https://dn.bunzserv.com/terminal/setup/network.sh
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
