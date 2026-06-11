#!/usr/bin/env bash
# One-time VPS bootstrap. Run as root on a fresh Ubuntu/Debian server:
#   scp Caddyfile medilens.service server-setup.sh root@VPS_IP:/root/
#   ssh root@VPS_IP 'bash /root/server-setup.sh'
set -euo pipefail

echo "==> Installing base packages"
apt-get update
apt-get install -y curl ca-certificates gnupg ufw debian-keyring debian-archive-keyring apt-transport-https

echo "==> Installing Node.js 22 (NodeSource)"
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt-get install -y nodejs

echo "==> Installing Caddy (official repo)"
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor --yes -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' > /etc/apt/sources.list.d/caddy-stable.list
apt-get update
apt-get install -y caddy

echo "==> Creating deploy user"
if ! id deploy &>/dev/null; then
  adduser --disabled-password --gecos "" deploy
fi
mkdir -p /home/deploy/.ssh
# Reuse the key you used to SSH in as root
cp /root/.ssh/authorized_keys /home/deploy/.ssh/authorized_keys
chown -R deploy:deploy /home/deploy/.ssh
chmod 700 /home/deploy/.ssh
chmod 600 /home/deploy/.ssh/authorized_keys

# deploy may restart the app service without a password (used by deploy scripts)
echo 'deploy ALL=(root) NOPASSWD: /usr/bin/systemctl restart medilens, /usr/bin/systemctl reload caddy' > /etc/sudoers.d/deploy
chmod 440 /etc/sudoers.d/deploy

echo "==> Creating site directories"
mkdir -p /var/www/softlightapps /srv/medilens
chown -R deploy:deploy /var/www/softlightapps /srv/medilens

echo "==> Firewall (SSH + HTTP + HTTPS)"
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

echo "==> Installing configs"
cp /root/Caddyfile /etc/caddy/Caddyfile
cp /root/medilens.service /etc/systemd/system/medilens.service
systemctl daemon-reload
systemctl enable medilens          # started by the first deploy-medilens.sh run
systemctl enable --now caddy
systemctl reload caddy

echo "==> Done. Next: run deploy-site.sh and deploy-medilens.sh from your PC."
