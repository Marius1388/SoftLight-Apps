#!/usr/bin/env bash
# Deploy the static softlightapps.com site. Run from this repo (Git Bash):
#   VPS_IP=1.2.3.4 bash deploy/deploy-site.sh
set -euo pipefail

: "${VPS_IP:?Set VPS_IP, e.g. VPS_IP=1.2.3.4 bash deploy/deploy-site.sh}"
VPS="deploy@${VPS_IP}"
SRC="$(cd "$(dirname "$0")/.." && pwd)"

scp "$SRC/index.html" \
    "$SRC/styles.css" \
    "$SRC/app-ads.txt" \
    "$SRC/developer icon.png" \
    "$SRC/Header image.png" \
    "$SRC/medilens-logo.png" \
    "$SRC/smilevillage-logo.png" \
    "$VPS:/var/www/softlightapps/"

echo "Deployed. Check https://softlightapps.com"
