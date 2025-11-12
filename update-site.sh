#!/bin/bash

################################################################################
# Project Mayhem - Update Script
# Quickly update website files without full redeployment
################################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root (use sudo)"
   exit 1
fi

# Get web root
read -p "Enter web root directory [/var/www/projectmayhem]: " WEB_ROOT
WEB_ROOT=${WEB_ROOT:-/var/www/projectmayhem}

if [ ! -d "$WEB_ROOT" ]; then
    log_error "Web root directory does not exist: $WEB_ROOT"
    exit 1
fi

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

log_info "Updating website files in $WEB_ROOT..."

# Backup existing files
BACKUP_DIR="/tmp/projectmayhem-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp -r "$WEB_ROOT"/* "$BACKUP_DIR/" 2>/dev/null || true
log_info "Backup created at: $BACKUP_DIR"

# Copy updated files
cp "$SCRIPT_DIR/index.html" "$WEB_ROOT/"
cp "$SCRIPT_DIR/styles.css" "$WEB_ROOT/"
cp "$SCRIPT_DIR/script.js" "$WEB_ROOT/"

# Copy img directory
if [ -d "$SCRIPT_DIR/img" ]; then
    cp -r "$SCRIPT_DIR/img" "$WEB_ROOT/"
fi

# Set proper permissions
chown -R www-data:www-data "$WEB_ROOT"
chmod -R 755 "$WEB_ROOT"

# Clear nginx cache if exists
if [ -d "/var/cache/nginx" ]; then
    rm -rf /var/cache/nginx/*
fi

# Reload nginx
systemctl reload nginx

log_info "Website updated successfully!"
echo ""
echo "Backup location: $BACKUP_DIR"
echo "To rollback: cp -r $BACKUP_DIR/* $WEB_ROOT/"
