#!/bin/bash

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo ./uninstall_service.sh)"
  exit 1
fi

echo "Uninstalling Zenergy Wattage Monitor Service..."

# 1. Stop and Disable Service
if systemctl is-active --quiet zenergy-wattage; then
    systemctl stop zenergy-wattage
    echo "Stopped service."
fi

if systemctl is-enabled --quiet zenergy-wattage; then
    systemctl disable zenergy-wattage
    echo "Disabled service."
fi

# 2. Remove Service File
SERVICE_FILE="/etc/systemd/system/zenergy-wattage.service"
if [ -f "$SERVICE_FILE" ]; then
    rm "$SERVICE_FILE"
    echo "Removed service file: $SERVICE_FILE"
else
    echo "Service file not found: $SERVICE_FILE"
fi

# 3. Remove Monitor Script
INSTALL_PATH="/usr/local/bin/zenergy-wattage-monitor"
if [ -f "$INSTALL_PATH" ]; then
    rm "$INSTALL_PATH"
    echo "Removed monitor script: $INSTALL_PATH"
else
    echo "Monitor script not found: $INSTALL_PATH"
fi

# 4. Reload Daemon
systemctl daemon-reload
echo "Systemd daemon reloaded."

echo "Zenergy Wattage Monitor Service uninstalled successfully."
echo "Note: Log files in ~/.local/share/zenergy-wattage/ were NOT removed."
