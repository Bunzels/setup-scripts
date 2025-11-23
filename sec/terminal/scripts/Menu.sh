#!/usr/bin/env bash
set -euo pipefail

title="DeerNET Terminal"
prompt="Pick an option:"
options=("Restart Terminal" "Shutdown Terminal" "Restart DeerNET" "Close DeerNET")

opt=$(zenity --title="$title" --height=350 --width=300 --text="$prompt" --list --column="Options" "${options[@]}")
# If user closed the dialog or pressed Cancel, exit silently
if [ $? -ne 0 ] || [ -z "${opt:-}" ]; then
  exit 0
fi

case "$opt" in
  "${options[0]}")
    # Restart the machine
    reboot
    ;;
  "${options[1]}")
    # Shutdown the machine
    shutdown -h now
    ;;
  "${options[2]}")
    # Restart DeerNET browser
    pkill -f chromium || true
    rm -rf "$HOME/.cache/chromium" 2>/dev/null || true
    # start chromium in background
    nohup chromium --noerrdialogs --disable-session-crashed-bubble --kiosk https://deernet.bunzels.com >/dev/null 2>&1 &
    ;;
  "${options[3]}")
    # Close DeerNET (requires admin password)
    correct_password="deernet2024"

    while true; do
      # Prompt for password; if they press Cancel, zenity exits non-zero
      PASSWORD=$(zenity --title="Admin Password" --password 2>/dev/null) || { exit 0; }
      if [ "$PASSWORD" = "$correct_password" ]; then
        pkill -f chromium || true
        exit 0
      else
        zenity --error --title="Password Incorrect" --text="Incorrect password. Please try again." >/dev/null 2>&1 || true
        # Loop continues and re-prompts
      fi
    done
    ;;
  *)
    # Fallback (shouldn't happen)
    exit 0
    ;;
esac

exit 0
