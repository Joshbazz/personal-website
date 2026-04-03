#!/bin/bash

# ============================================
# Digital Ocean Droplet Setup Script
# For hosting bazzanotech.com
# ============================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Website Setup Script${NC}"
echo -e "${GREEN}========================================${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root (use sudo)${NC}"
    exit 1
fi

# Variables - UPDATE THESE
DOMAIN="bazzanotech.com"
OLD_DOMAIN="joshbazzano.com"
EMAIL="josh@bazzanotech.com"
WEB_ROOT="/var/www/${DOMAIN}"
REPO_URL="https://github.com/Joshbazz/personal-website.git"

echo -e "\n${YELLOW}Step 1: Updating system packages...${NC}"
apt update && apt upgrade -y

echo -e "\n${YELLOW}Step 2: Installing required packages...${NC}"
apt install -y nginx certbot python3-certbot-nginx git ufw

echo -e "\n${YELLOW}Step 3: Configuring firewall...${NC}"
ufw allow 'Nginx Full'
ufw allow OpenSSH
ufw --force enable

echo -e "\n${YELLOW}Step 4: Creating web directory...${NC}"
mkdir -p ${WEB_ROOT}
chown -R www-data:www-data ${WEB_ROOT}
chmod -R 755 ${WEB_ROOT}

echo -e "\n${YELLOW}Step 5: Cloning repository...${NC}"
if [ -d "/tmp/website-repo" ]; then
    rm -rf /tmp/website-repo
fi
git clone ${REPO_URL} /tmp/website-repo

echo -e "\n${YELLOW}Step 6: Copying website files...${NC}"
cp /tmp/website-repo/index.html ${WEB_ROOT}/
cp /tmp/website-repo/styles.css ${WEB_ROOT}/
cp /tmp/website-repo/business.css ${WEB_ROOT}/
cp /tmp/website-repo/josh.html ${WEB_ROOT}/
cp /tmp/website-repo/projects.html ${WEB_ROOT}/
cp /tmp/website-repo/services.html ${WEB_ROOT}/
cp /tmp/website-repo/work.html ${WEB_ROOT}/
cp /tmp/website-repo/about.html ${WEB_ROOT}/
cp /tmp/website-repo/contact.html ${WEB_ROOT}/
cp /tmp/website-repo/404.html ${WEB_ROOT}/
cp /tmp/website-repo/50x.html ${WEB_ROOT}/
cp /tmp/website-repo/sitemap.xml ${WEB_ROOT}/
cp /tmp/website-repo/robots.txt ${WEB_ROOT}/
cp -r /tmp/website-repo/media ${WEB_ROOT}/

# Set proper ownership
chown -R www-data:www-data ${WEB_ROOT}

echo -e "\n${YELLOW}Step 7: Setting up Nginx configuration...${NC}"
# Create initial HTTP-only config for Certbot
cat > /etc/nginx/sites-available/${DOMAIN} << 'NGINX_CONF'
server {
    listen 80;
    listen [::]:80;
    server_name bazzanotech.com www.bazzanotech.com;
    root /var/www/bazzanotech.com;
    index index.html;

    location / {
        try_files $uri $uri/ $uri.html =404;
    }
}
NGINX_CONF

# Enable the site
ln -sf /etc/nginx/sites-available/${DOMAIN} /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test and reload Nginx
nginx -t
systemctl reload nginx

echo -e "\n${YELLOW}Step 8: Obtaining SSL certificates...${NC}"
# Get cert for new domain
certbot --nginx -d ${DOMAIN} -d www.${DOMAIN} --non-interactive --agree-tos --email ${EMAIL}
# Get cert for old domain (needed for HTTPS redirect)
certbot --nginx -d ${OLD_DOMAIN} -d www.${OLD_DOMAIN} --non-interactive --agree-tos --email ${EMAIL}

echo -e "\n${YELLOW}Step 9: Updating Nginx with full SSL configuration...${NC}"
# Copy the full nginx config (includes redirect from old domain)
cp /tmp/website-repo/deploy/nginx.conf /etc/nginx/sites-available/${DOMAIN}

# Test and reload
nginx -t
systemctl reload nginx

echo -e "\n${YELLOW}Step 10: Setting up automatic SSL renewal...${NC}"
systemctl enable certbot.timer
systemctl start certbot.timer

echo -e "\n${YELLOW}Step 11: Cleaning up...${NC}"
rm -rf /tmp/website-repo

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "\nYour website should now be live at:"
echo -e "  ${GREEN}https://${DOMAIN}${NC}"
echo -e "\n${OLD_DOMAIN} will redirect to ${DOMAIN}"
echo -e "\nUseful commands:"
echo -e "  - Check Nginx status: ${YELLOW}systemctl status nginx${NC}"
echo -e "  - View access logs: ${YELLOW}tail -f /var/log/nginx/${DOMAIN}.access.log${NC}"
echo -e "  - View error logs: ${YELLOW}tail -f /var/log/nginx/${DOMAIN}.error.log${NC}"
echo -e "  - Test SSL renewal: ${YELLOW}certbot renew --dry-run${NC}"
echo -e "  - Update website: ${YELLOW}./deploy.sh${NC}"
