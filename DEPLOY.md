# Hosting on Digital Ocean

This guide walks you through hosting your portfolio website on a Digital Ocean Droplet.

## Infrastructure Overview

```
┌─────────────────────────────────────────────────────────┐
│                    Digital Ocean                         │
│  ┌───────────────────────────────────────────────────┐  │
│  │              Droplet (Ubuntu 22.04)               │  │
│  │  ┌─────────────────────────────────────────────┐  │  │
│  │  │                 Nginx                        │  │  │
│  │  │  - Reverse proxy                            │  │  │
│  │  │  - SSL termination (Let's Encrypt)          │  │  │
│  │  │  - Static file serving                      │  │  │
│  │  │  - Gzip compression                         │  │  │
│  │  └─────────────────────────────────────────────┘  │  │
│  │                      │                            │  │
│  │                      ▼                            │  │
│  │  ┌─────────────────────────────────────────────┐  │  │
│  │  │           /var/www/joshbazzano.com          │  │  │
│  │  │  - index.html                               │  │  │
│  │  │  - styles.css                               │  │  │
│  │  │  - projects.html                            │  │  │
│  │  └─────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

## Requirements

- Digital Ocean account
- Domain name (joshbazzano.com) with DNS configured
- SSH key for secure access

## Cost Estimate

| Resource | Cost |
|----------|------|
| Basic Droplet (1GB RAM, 1 vCPU) | $6/month |
| Domain (if not owned) | ~$12/year |
| **Total** | **~$6-7/month** |

---

## Step 1: Create a Digital Ocean Droplet

1. **Log into Digital Ocean** at https://cloud.digitalocean.com

2. **Create a new Droplet:**
   - Click "Create" → "Droplets"
   - Choose **Ubuntu 22.04 LTS**
   - Select **Basic** plan
   - Choose **Regular SSD** → **$6/mo** (1 GB RAM, 1 vCPU, 25 GB SSD)
   - Choose a datacenter region close to your audience (e.g., NYC1)
   - Add your SSH key for authentication
   - Name it: `portfolio-server`
   - Click "Create Droplet"

3. **Note your Droplet's IP address** (e.g., `164.92.xxx.xxx`)

---

## Step 2: Configure DNS

Point your domain to your Droplet:

1. **In your domain registrar** (GoDaddy, Namecheap, etc.):
   - Set nameservers to Digital Ocean:
     ```
     ns1.digitalocean.com
     ns2.digitalocean.com
     ns3.digitalocean.com
     ```

2. **In Digital Ocean** (Networking → Domains):
   - Add your domain: `joshbazzano.com`
   - Create A records:
     ```
     @    → Your Droplet IP
     www  → Your Droplet IP
     ```

3. **Wait for DNS propagation** (can take up to 48 hours, usually faster)
   - Check with: `dig joshbazzano.com`

---

## Step 3: Initial Server Setup

SSH into your droplet and run these commands:

```bash
# Connect to your server
ssh root@YOUR_DROPLET_IP

# Update the system
apt update && apt upgrade -y

# Create a non-root user (recommended)
adduser josh
usermod -aG sudo josh

# Copy SSH keys to new user
rsync --archive --chown=josh:josh ~/.ssh /home/josh

# Switch to new user
su - josh
```

---

## Step 4: Run the Setup Script

```bash
# Clone your repository
git clone https://github.com/Joshbazz/first-repository.git
cd first-repository/deploy

# Make scripts executable
chmod +x setup.sh deploy.sh

# Run the setup (as root/sudo)
sudo ./setup.sh
```

The setup script will:
1. Install Nginx, Certbot, and Git
2. Configure the firewall (UFW)
3. Create the web directory
4. Clone and deploy your website
5. Configure Nginx
6. Obtain SSL certificate from Let's Encrypt
7. Set up automatic SSL renewal

---

## Step 5: Verify Installation

1. **Check Nginx status:**
   ```bash
   sudo systemctl status nginx
   ```

2. **Test your website:**
   - Open https://joshbazzano.com in a browser
   - Verify SSL certificate (padlock icon)

3. **Check SSL certificate:**
   ```bash
   sudo certbot certificates
   ```

---

## Updating Your Website

After making changes to your website locally:

1. **Commit and push to GitHub:**
   ```bash
   git add .
   git commit -m "Update website"
   git push
   ```

2. **Deploy to server:**
   ```bash
   ssh josh@YOUR_DROPLET_IP
   cd /path/to/deploy
   sudo ./deploy.sh
   ```

Or set up a webhook for automatic deployments (see Advanced section).

---

## Directory Structure on Server

```
/var/www/joshbazzano.com/
├── index.html          # Main portfolio page
├── styles.css          # Stylesheet
└── projects.html       # Projects page

/etc/nginx/
├── sites-available/
│   └── joshbazzano.com # Nginx config
└── sites-enabled/
    └── joshbazzano.com # Symlink

/etc/letsencrypt/
└── live/
    └── joshbazzano.com/
        ├── fullchain.pem
        └── privkey.pem
```

---

## Useful Commands

```bash
# Nginx
sudo systemctl status nginx      # Check status
sudo systemctl restart nginx     # Restart
sudo nginx -t                    # Test config
sudo tail -f /var/log/nginx/joshbazzano.com.access.log  # View logs

# SSL
sudo certbot certificates        # List certificates
sudo certbot renew --dry-run     # Test renewal
sudo certbot renew               # Force renewal

# Firewall
sudo ufw status                  # Check firewall
sudo ufw allow 'Nginx Full'      # Allow Nginx

# Server
df -h                            # Check disk space
free -m                          # Check memory
htop                             # Process monitor
```

---

## Troubleshooting

### Website not loading
```bash
# Check if Nginx is running
sudo systemctl status nginx

# Check Nginx error logs
sudo tail -f /var/log/nginx/error.log

# Test Nginx config
sudo nginx -t
```

### SSL certificate issues
```bash
# Check certificate status
sudo certbot certificates

# Renew certificates
sudo certbot renew

# Check Let's Encrypt logs
sudo tail -f /var/log/letsencrypt/letsencrypt.log
```

### DNS not resolving
```bash
# Check DNS propagation
dig joshbazzano.com
nslookup joshbazzano.com

# Verify A records point to your IP
dig +short joshbazzano.com
```

---

## Security Recommendations

1. **Keep system updated:**
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

2. **Enable automatic security updates:**
   ```bash
   sudo apt install unattended-upgrades
   sudo dpkg-reconfigure -plow unattended-upgrades
   ```

3. **Use SSH keys only** (disable password authentication):
   ```bash
   sudo nano /etc/ssh/sshd_config
   # Set: PasswordAuthentication no
   sudo systemctl restart sshd
   ```

4. **Install fail2ban** for brute-force protection:
   ```bash
   sudo apt install fail2ban
   sudo systemctl enable fail2ban
   ```

---

## Advanced: Automatic Deployments with GitHub Actions

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Deploy to server
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.HOST }}
          username: ${{ secrets.USERNAME }}
          key: ${{ secrets.SSH_KEY }}
          script: |
            cd /home/josh/first-repository/deploy
            sudo ./deploy.sh
```

Add these secrets in GitHub:
- `HOST`: Your Droplet IP
- `USERNAME`: josh
- `SSH_KEY`: Your private SSH key

---

## Support

- Digital Ocean Documentation: https://docs.digitalocean.com
- Nginx Documentation: https://nginx.org/en/docs/
- Let's Encrypt Documentation: https://letsencrypt.org/docs/
