#!/usr/bin/env bash
# Build and deploy medilens.softlightapps.com. Run from anywhere (Git Bash):
#   VPS_IP=1.2.3.4 bash deploy/deploy-medilens.sh
set -euo pipefail

: "${VPS_IP:?Set VPS_IP, e.g. VPS_IP=1.2.3.4 bash deploy/deploy-medilens.sh}"
VPS="deploy@${VPS_IP}"
APP="/c/projects/medilens-web"

cd "$APP"
echo "==> Building"
npm run build

echo "==> Packaging"
tar czf /tmp/medilens-deploy.tgz dist server.prod.mjs package.json package-lock.json

echo "==> Uploading"
scp /tmp/medilens-deploy.tgz "$VPS:/tmp/"

echo "==> Installing on server"
ssh "$VPS" '
  set -e
  cd /srv/medilens
  rm -rf dist
  tar xzf /tmp/medilens-deploy.tgz
  rm /tmp/medilens-deploy.tgz
  npm ci --omit=dev
  sudo systemctl restart medilens
'

rm /tmp/medilens-deploy.tgz
echo "Deployed. Check https://medilens.softlightapps.com"
