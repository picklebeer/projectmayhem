#!/bin/bash

################################################################################
# Project Mayhem - Deployment Script
# Deploys website with Nginx and Let's Encrypt SSL on Ubuntu
################################################################################

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root (use sudo)"
   exit 1
fi

# Get configuration from user
echo ""
echo "================================"
echo "PROJECT MAYHEM DEPLOYMENT SCRIPT"
echo "================================"
echo ""

# Prompt for domain name
read -p "Enter your domain name (e.g., projectmayhem.com): " DOMAIN_NAME
if [[ -z "$DOMAIN_NAME" ]]; then
    log_error "Domain name is required"
    exit 1
fi

# Prompt for email for Let's Encrypt
read -p "Enter your email for Let's Encrypt SSL certificate: " EMAIL
if [[ -z "$EMAIL" ]]; then
    log_error "Email is required"
    exit 1
fi

# Prompt for web root directory
read -p "Enter installation directory [/var/www/projectmayhem]: " WEB_ROOT
WEB_ROOT=${WEB_ROOT:-/var/www/projectmayhem}

# Confirm settings
echo ""
log_info "Configuration Summary:"
echo "  Domain: $DOMAIN_NAME"
echo "  Email: $EMAIL"
echo "  Web Root: $WEB_ROOT"
echo ""
read -p "Proceed with deployment? (y/n): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    log_warn "Deployment cancelled"
    exit 0
fi

################################################################################
# 1. Update system and install dependencies
################################################################################
log_info "Updating system packages..."
apt-get update -qq
apt-get upgrade -y -qq

log_info "Installing Nginx and Certbot..."
apt-get install -y nginx certbot python3-certbot-nginx

################################################################################
# 2. Configure firewall
################################################################################
log_info "Configuring UFW firewall..."
if command -v ufw &> /dev/null; then
    ufw allow 'Nginx Full'
    ufw allow OpenSSH
    # Enable UFW if not already enabled
    ufw --force enable
    log_info "Firewall configured (HTTP, HTTPS, SSH allowed)"
else
    log_warn "UFW not found, skipping firewall configuration"
fi

################################################################################
# 3. Create web root and copy files
################################################################################
log_info "Creating web root directory: $WEB_ROOT"
mkdir -p "$WEB_ROOT"

log_info "Copying website files..."
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Copy website files
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

log_info "Website files copied successfully"

################################################################################
# 4. Create Nginx configuration
################################################################################
log_info "Creating Nginx configuration..."

NGINX_CONF="/etc/nginx/sites-available/$DOMAIN_NAME"

cat > "$NGINX_CONF" <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN_NAME www.$DOMAIN_NAME;

    root $WEB_ROOT;
    index index.html;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # Main location
    location / {
        try_files \$uri \$uri/ =404;
    }

    # Cache static assets
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Deny access to hidden files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/javascript application/json image/svg+xml;

    # Logging
    access_log /var/log/nginx/${DOMAIN_NAME}_access.log;
    error_log /var/log/nginx/${DOMAIN_NAME}_error.log;
}
EOF

# Enable site
ln -sf "$NGINX_CONF" "/etc/nginx/sites-enabled/$DOMAIN_NAME"

# Remove default site if it exists
if [ -L "/etc/nginx/sites-enabled/default" ]; then
    rm "/etc/nginx/sites-enabled/default"
fi

# Test Nginx configuration
log_info "Testing Nginx configuration..."
nginx -t

# Restart Nginx
log_info "Restarting Nginx..."
systemctl restart nginx
systemctl enable nginx

log_info "Nginx configured successfully"

################################################################################
# 5. Obtain SSL certificate with Let's Encrypt
################################################################################
log_info "Obtaining SSL certificate from Let's Encrypt..."

# Check if certificate already exists
if [ -d "/etc/letsencrypt/live/$DOMAIN_NAME" ]; then
    log_warn "Certificate already exists for $DOMAIN_NAME"
    read -p "Renew existing certificate? (y/n): " RENEW
    if [[ "$RENEW" =~ ^[Yy]$ ]]; then
        certbot renew --nginx
    fi
else
    # Obtain new certificate
    certbot --nginx -d "$DOMAIN_NAME" -d "www.$DOMAIN_NAME" \
        --non-interactive \
        --agree-tos \
        --email "$EMAIL" \
        --redirect
fi

# Setup auto-renewal
log_info "Setting up automatic SSL certificate renewal..."
systemctl enable certbot.timer
systemctl start certbot.timer

################################################################################
# 6. Final security hardening
################################################################################
log_info "Applying additional security configurations..."

# Update Nginx SSL configuration
NGINX_SSL_CONF="/etc/nginx/snippets/ssl-params.conf"

cat > "$NGINX_SSL_CONF" <<EOF
# SSL Configuration
ssl_protocols TLSv1.2 TLSv1.3;
ssl_prefer_server_ciphers on;
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
ssl_session_timeout 1d;
ssl_session_cache shared:SSL:50m;
ssl_session_tickets off;
ssl_stapling on;
ssl_stapling_verify on;

# Security headers
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
EOF

# Reload Nginx to apply changes
systemctl reload nginx

################################################################################
# 7. Create maintenance script
################################################################################
log_info "Creating maintenance script..."

MAINTENANCE_SCRIPT="/usr/local/bin/projectmayhem-maintenance.sh"

cat > "$MAINTENANCE_SCRIPT" <<'MAINT_EOF'
#!/bin/bash
# Project Mayhem - Maintenance Script

echo "Project Mayhem Maintenance"
echo "=========================="
echo ""

# Check Nginx status
echo "Nginx Status:"
systemctl status nginx --no-pager | head -n 3
echo ""

# Check SSL certificate expiry
echo "SSL Certificate Status:"
certbot certificates
echo ""

# Check disk usage
echo "Disk Usage:"
df -h / | tail -n 1
echo ""

# Recent access log summary (top 10 IPs)
echo "Top 10 Visitor IPs (last 1000 requests):"
tail -n 1000 /var/log/nginx/*_access.log 2>/dev/null | \
    awk '{print $1}' | sort | uniq -c | sort -rn | head -n 10
echo ""

# Check for errors in last hour
echo "Recent Nginx Errors:"
find /var/log/nginx/ -name "*error.log" -mmin -60 -exec tail {} \; | tail -n 10
MAINT_EOF

chmod +x "$MAINTENANCE_SCRIPT"

################################################################################
# Deployment Complete
################################################################################
echo ""
echo "========================================"
log_info "DEPLOYMENT COMPLETE!"
echo "========================================"
echo ""
echo "Your Project Mayhem website is now live at:"
echo "  https://$DOMAIN_NAME"
echo "  https://www.$DOMAIN_NAME"
echo ""
echo "Important locations:"
echo "  Web Root: $WEB_ROOT"
echo "  Nginx Config: $NGINX_CONF"
echo "  Access Logs: /var/log/nginx/${DOMAIN_NAME}_access.log"
echo "  Error Logs: /var/log/nginx/${DOMAIN_NAME}_error.log"
echo ""
echo "Useful commands:"
echo "  Check status: systemctl status nginx"
echo "  Reload config: systemctl reload nginx"
echo "  Check SSL: certbot certificates"
echo "  Maintenance: $MAINTENANCE_SCRIPT"
echo ""
log_warn "Make sure your DNS A records point to this server's IP address:"
EXTERNAL_IP=$(curl -s ifconfig.me)
echo "  $DOMAIN_NAME -> $EXTERNAL_IP"
echo "  www.$DOMAIN_NAME -> $EXTERNAL_IP"
echo ""
log_info "The first rule of Project Mayhem is: You DO NOT talk about Project Mayhem"
echo ""
