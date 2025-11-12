# Project Mayhem - Deployment Guide

Complete deployment guide for setting up Project Mayhem website with Nginx and Let's Encrypt SSL on Ubuntu.

## Prerequisites

- Ubuntu 20.04 or 22.04 server
- Root or sudo access
- Domain name pointed to your server's IP address
- Server with at least 1GB RAM

## Quick Deployment

### 1. Setup DNS Records

Before deploying, ensure your domain DNS records are configured:

```
Type: A
Name: @
Value: YOUR_SERVER_IP

Type: A
Name: www
Value: YOUR_SERVER_IP
```

**Important**: Wait for DNS propagation (can take up to 48 hours, usually much faster)

Verify DNS is working:
```bash
dig +short yourdomain.com
dig +short www.yourdomain.com
```

### 2. Upload Files to Server

```bash
# On your local machine
scp -r /path/to/projectmayhem root@YOUR_SERVER_IP:/root/

# Or use git
ssh root@YOUR_SERVER_IP
git clone https://github.com/yourusername/projectmayhem.git
cd projectmayhem
```

### 3. Run Deployment Script

```bash
# SSH into your server
ssh root@YOUR_SERVER_IP

# Navigate to project directory
cd /root/projectmayhem

# Make script executable
chmod +x deploy.sh

# Run deployment
sudo ./deploy.sh
```

### 4. Follow the Prompts

The script will ask for:
- **Domain name**: e.g., `projectmayhem.com`
- **Email**: For Let's Encrypt SSL certificate notifications
- **Installation directory**: Default is `/var/www/projectmayhem`

### 5. Verify Deployment

Visit your website:
- `https://yourdomain.com`
- `https://www.yourdomain.com`

Check SSL certificate:
```bash
sudo certbot certificates
```

## What the Deployment Script Does

1. **System Updates**: Updates Ubuntu packages
2. **Installs Software**: Nginx, Certbot, Python3-certbot-nginx
3. **Configures Firewall**: Opens ports 80 (HTTP), 443 (HTTPS), and 22 (SSH)
4. **Copies Files**: Moves website files to web root
5. **Nginx Configuration**: Creates optimized Nginx config with:
   - Gzip compression
   - Static asset caching
   - Security headers
   - Access/error logging
6. **SSL Certificate**: Obtains and installs Let's Encrypt SSL certificate
7. **Auto-Renewal**: Sets up automatic SSL certificate renewal
8. **Security Hardening**: Implements SSL best practices and security headers

## Manual Deployment (Alternative)

If you prefer manual deployment:

### 1. Install Dependencies

```bash
sudo apt-get update
sudo apt-get install -y nginx certbot python3-certbot-nginx
```

### 2. Copy Website Files

```bash
sudo mkdir -p /var/www/projectmayhem
sudo cp index.html styles.css script.js /var/www/projectmayhem/
sudo cp -r img /var/www/projectmayhem/
sudo chown -R www-data:www-data /var/www/projectmayhem
sudo chmod -R 755 /var/www/projectmayhem
```

### 3. Create Nginx Configuration

```bash
sudo nano /etc/nginx/sites-available/yourdomain.com
```

Paste this configuration (replace `yourdomain.com` with your domain):

```nginx
server {
    listen 80;
    listen [::]:80;
    server_name yourdomain.com www.yourdomain.com;

    root /var/www/projectmayhem;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }

    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml;
}
```

### 4. Enable Site

```bash
sudo ln -s /etc/nginx/sites-available/yourdomain.com /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx
```

### 5. Obtain SSL Certificate

```bash
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com
```

## Updating the Website

To update website files after initial deployment:

```bash
# Make update script executable
chmod +x update-site.sh

# Run update script
sudo ./update-site.sh
```

Or manually:

```bash
sudo cp index.html styles.css script.js /var/www/projectmayhem/
sudo cp -r img /var/www/projectmayhem/
sudo systemctl reload nginx
```

## Maintenance Commands

### Check Nginx Status
```bash
sudo systemctl status nginx
```

### View Access Logs
```bash
sudo tail -f /var/log/nginx/yourdomain.com_access.log
```

### View Error Logs
```bash
sudo tail -f /var/log/nginx/yourdomain.com_error.log
```

### Check SSL Certificate
```bash
sudo certbot certificates
```

### Renew SSL Certificate Manually
```bash
sudo certbot renew
```

### Test Nginx Configuration
```bash
sudo nginx -t
```

### Reload Nginx (after config changes)
```bash
sudo systemctl reload nginx
```

### Restart Nginx
```bash
sudo systemctl restart nginx
```

### Run Maintenance Script
```bash
sudo /usr/local/bin/projectmayhem-maintenance.sh
```

## Firewall Configuration

If using UFW:

```bash
# Allow HTTP and HTTPS
sudo ufw allow 'Nginx Full'

# Allow SSH (important!)
sudo ufw allow OpenSSH

# Enable firewall
sudo ufw enable

# Check status
sudo ufw status
```

## Troubleshooting

### Website Not Loading

1. Check if Nginx is running:
   ```bash
   sudo systemctl status nginx
   ```

2. Check error logs:
   ```bash
   sudo tail -n 50 /var/log/nginx/error.log
   ```

3. Verify DNS:
   ```bash
   dig +short yourdomain.com
   ```

### SSL Certificate Issues

1. Check certificate status:
   ```bash
   sudo certbot certificates
   ```

2. Try obtaining certificate again:
   ```bash
   sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com
   ```

3. Check if ports are open:
   ```bash
   sudo netstat -tlnp | grep :80
   sudo netstat -tlnp | grep :443
   ```

### Permission Errors

```bash
sudo chown -R www-data:www-data /var/www/projectmayhem
sudo chmod -R 755 /var/www/projectmayhem
```

### Nginx Configuration Errors

```bash
sudo nginx -t
```

This will show any syntax errors in your Nginx configuration.

## Performance Optimization

### Enable HTTP/2

Already included in SSL configuration by Certbot.

### Add CloudFlare (Optional)

For additional DDoS protection and CDN:

1. Sign up for CloudFlare (free tier available)
2. Point your domain to CloudFlare nameservers
3. Configure CloudFlare DNS to point to your server
4. Enable "Full (strict)" SSL mode in CloudFlare

### Monitor Performance

```bash
# Install htop for system monitoring
sudo apt-get install htop
htop

# Monitor Nginx connections
watch -n 1 'sudo netstat -an | grep :80 | wc -l'
```

## Security Best Practices

1. **Keep System Updated**
   ```bash
   sudo apt-get update && sudo apt-get upgrade -y
   ```

2. **Setup Fail2Ban** (protects against brute force)
   ```bash
   sudo apt-get install fail2ban
   sudo systemctl enable fail2ban
   ```

3. **Regular Backups**
   ```bash
   # Backup website files
   sudo tar -czf projectmayhem-backup-$(date +%Y%m%d).tar.gz /var/www/projectmayhem
   
   # Backup Nginx config
   sudo tar -czf nginx-config-backup-$(date +%Y%m%d).tar.gz /etc/nginx
   ```

4. **Monitor Logs**
   ```bash
   # Check for suspicious activity
   sudo tail -f /var/log/nginx/*_access.log
   ```

## Uninstalling

To completely remove the installation:

```bash
# Stop Nginx
sudo systemctl stop nginx

# Remove website files
sudo rm -rf /var/www/projectmayhem

# Remove Nginx config
sudo rm /etc/nginx/sites-available/yourdomain.com
sudo rm /etc/nginx/sites-enabled/yourdomain.com

# Revoke SSL certificate (optional)
sudo certbot revoke --cert-path /etc/letsencrypt/live/yourdomain.com/cert.pem

# Remove certbot
sudo apt-get remove --purge certbot python3-certbot-nginx

# Remove nginx (optional)
sudo apt-get remove --purge nginx
```

## Support

For issues or questions:
- Check Nginx error logs first
- Verify DNS configuration
- Ensure firewall ports are open
- Check SSL certificate validity

## License

This deployment script is provided as-is for the Project Mayhem cryptocurrency token website.

---

**Remember**: The first rule of Project Mayhem is you do not ask questions.
