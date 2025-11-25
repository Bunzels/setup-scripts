#!/usr/bin/env bash
set -euo pipefail

title="DeerNET Terminal"
prompt="Pick an option:"
options=("Restart Terminal" "Shutdown Terminal" "Restart DeerNET" "Close DeerNET")

opt=$(zenity --title="$title" --height=350 --width=300 --text="$prompt" --list --column="Options" "${options[@]}")

if [ $? -ne 0 ] || [ -z "${opt:-}" ]; then
  exit 0
fi

case "$opt" in
  "${options[0]}")
    # Restart machine via systemd D-Bus
    busctl call org.freedesktop.login1 /org/freedesktop/login1 \
      org.freedesktop.login1.Manager Reboot b 1
    ;;

  "${options[1]}")
    # Shutdown machine via systemd D-Bus
    busctl call org.freedesktop.login1 /org/freedesktop/login1 \
      org.freedesktop.login1.Manager PowerOff b 1
    ;;

  "${options[2]}")
    pkill -f chromium || true
    rm -rf "$HOME/.cache/chromium" 2>/dev/null || true
    nohup chromium --noerrdialogs --disable-session-crashed-bubble --kiosk https://deernet.bunzels.com >/dev/null 2>&1 &
    ;;

  "${options[3]}")
    correct_password="deernet2024"

    while true; do
      PASSWORD=$(zenity --title="Admin Password" --password 2>/dev/null) || exit 0
      if [ "$PASSWORD" = "$correct_password" ]; then
        pkill -f chromium || true
        exit 0
      else
        zenity --error --title="Password Incorrect" --text="Incorrect password. Please try again." >/dev/null 2>&1 || true
      fi
    done
    ;;

  *)
    exit 0
    ;;
esac

exit 0
