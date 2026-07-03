#!/usr/bin/env bash
# install.sh — sets up the native systemd service (no Docker required).
# This is a portable fallback for a fresh Pi; linuxvm itself runs this app
# as a Docker container instead (see NOTES.md).
# Usage: bash install.sh

set -e

PORT=8093
SERVICE=clem-schedule
INSTALL_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "📦 Installing Clem's Walk Schedule from: $INSTALL_DIR"

# Install systemd service
sudo cp "$INSTALL_DIR/clem-schedule.service" /etc/systemd/system/
sudo sed -i "s|/home/pi/Dev/clem_schedule|$INSTALL_DIR|g" /etc/systemd/system/clem-schedule.service
sudo sed -i "s|User=pi|User=$(whoami)|g" /etc/systemd/system/clem-schedule.service

sudo systemctl daemon-reload
sudo systemctl enable $SERVICE
sudo systemctl restart $SERVICE

echo ""
echo "✅ Service installed and started."
echo "   Listening on port $PORT"
echo "   Status: $(systemctl is-active $SERVICE)"
echo ""
echo "   Access at: http://$(hostname -I | awk '{print $1}'):$PORT"
echo ""
echo "📋 To add to your Pi menu, copy the card snippet from pi-menu-card.html"
