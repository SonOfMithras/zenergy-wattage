#!/bin/bash

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo ./install_service.sh)"
  exit 1
fi

# Get the real user (who invoked sudo)
REAL_USER=$SUDO_USER
if [ -z "$REAL_USER" ]; then
  echo "Could not determine the real user. Are you running with sudo?"
  exit 1
fi

# Get the real user's home directory
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

echo "Installing Zenergy Wattage Monitor Service for user: $REAL_USER"

# 1. Install monitor script
INSTALL_PATH="/usr/local/bin/zenergy-wattage-monitor"
cp monitor.py "$INSTALL_PATH"
chmod +x "$INSTALL_PATH"
echo "Installed monitor script to $INSTALL_PATH"

# 2. Create Systemd Service
SERVICE_FILE="/etc/systemd/system/zenergy-wattage.service"
cat <<EOF > "$SERVICE_FILE"
[Unit]
Description=Zenergy Wattage Monitor
After=network.target

[Service]
Type=simple
User=$REAL_USER
ExecStart=/usr/bin/python3 $INSTALL_PATH --log $REAL_HOME/.local/share/zenergy-wattage/cpu_wattage.log
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

echo "Created service file at $SERVICE_FILE"

# 3. Reload and Enable
systemctl daemon-reload
systemctl enable zenergy-wattage
systemctl start zenergy-wattage

echo "Service zenergy-wattage installed and started!"
echo "Check status with: systemctl status zenergy-wattage"
