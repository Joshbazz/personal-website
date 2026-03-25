#!/bin/bash

# ============================================
# Deployment Script
# Run this to update your website
# ============================================

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

DOMAIN="joshbazzano.com"
WEB_ROOT="/var/www/${DOMAIN}"
REPO_URL="https://github.com/Joshbazz/personal-website.git"
BACKUP_DIR="/var/backups/website"

echo -e "${GREEN}Starting deployment...${NC}"

# Create backup
echo -e "${YELLOW}Creating backup...${NC}"
mkdir -p ${BACKUP_DIR}
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
tar -czf ${BACKUP_DIR}/backup_${TIMESTAMP}.tar.gz -C ${WEB_ROOT} . 2>/dev/null || true

# Keep only last 5 backups
ls -t ${BACKUP_DIR}/backup_*.tar.gz 2>/dev/null | tail -n +6 | xargs -r rm

# Pull latest code
echo -e "${YELLOW}Pulling latest code...${NC}"
rm -rf /tmp/website-repo
git clone ${REPO_URL} /tmp/website-repo

# Copy files
echo -e "${YELLOW}Updating website files...${NC}"
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

# Set ownership
chown -R www-data:www-data ${WEB_ROOT}

# Cleanup
rm -rf /tmp/website-repo

# Reload nginx (in case of config changes)
nginx -t && systemctl reload nginx

echo -e "${GREEN}Deployment complete!${NC}"
echo -e "Website updated at: https://${DOMAIN}"
