# Local Development

Prototype locally with Python (zero install):

```bash
cd /Users/joshbazzano/Projects/personal-website/personal-website
python3 -m http.server 8080
```

Then open http://localhost:8080

# Redeploy to Production

After pushing changes to GitHub, SSH into the droplet and run the deploy script:

```bash
ssh root@137.184.214.204
cd /tmp/website-setup
git pull
sudo bash deploy/deploy.sh
```

This pulls the latest code from GitHub, copies updated files to the web root, and reloads Nginx (~30 seconds).
