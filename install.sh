#!/bin/bash

# Exit on error
set -e

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# Get installation directory
INSTALL_DIR=$(pwd)
echo "Installing in $INSTALL_DIR"

# Update system
echo "Updating system..."
apt update
apt upgrade -y

# Install dependencies
echo "Installing dependencies..."
apt install -y python3-pip python3-venv nginx supervisor

# Create virtual environment
echo "Creating virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Install Python dependencies
echo "Installing Python dependencies..."
pip install -r requirements.txt

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
  echo "Creating .env file..."
  cp .env.example .env
  echo "Please edit .env file with your configuration"
fi

# Configure Nginx
echo "Configuring Nginx..."
sed -i "s|/path/to/tg_poster|$INSTALL_DIR|g" nginx/bot.conf
cp nginx/bot.conf /etc/nginx/sites-available/
ln -sf /etc/nginx/sites-available/bot.conf /etc/nginx/sites-enabled/
systemctl restart nginx

# Configure Supervisor
echo "Configuring Supervisor..."
sed -i "s|/path/to/tg_poster|$INSTALL_DIR|g" supervisor/tg_poster.conf
sed -i "s|/path/to/venv|$INSTALL_DIR/venv|g" supervisor/tg_poster.conf
sed -i "s|your_username|$(logname)|g" supervisor/tg_poster.conf
cp supervisor/tg_poster.conf /etc/supervisor/conf.d/
supervisorctl reread
supervisorctl update

echo "Installation complete!"
echo "Please edit .env file with your configuration if you haven't already"
echo "Then restart the services with: supervisorctl restart tg_poster tg_poster_api"
