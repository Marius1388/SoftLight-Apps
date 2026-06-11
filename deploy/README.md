# Deploying softlightapps.com

Two sites, one VPS, served by Caddy (automatic HTTPS):

| Site | What | How it's served |
|---|---|---|
| `softlightapps.com` | This repo's static site | Caddy `file_server` from `/var/www/softlightapps` |
| `medilens.softlightapps.com` | `C:\projects\medilens-web` (TanStack Start SSR) | Node (systemd service `medilens`, port 3000) behind Caddy; static assets served by Caddy from `/srv/medilens/dist/client` |

## 1. DNS (registrar dashboard)

Create three **A records** pointing at the VPS IP:

| Type | Name | Value |
|---|---|---|
| A | `@` | VPS IP |
| A | `www` | VPS IP |
| A | `medilens` | VPS IP |

## 2. Put your SSH key on the VPS (once)

From Git Bash on this PC (uses your existing `~/.ssh/id_ed25519`):

```bash
ssh root@VPS_IP "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys" < ~/.ssh/id_ed25519.pub
```

(Enter the root password from your VPS provider when prompted.)

## 3. Bootstrap the server (once)

```bash
cd "/c/projects/SoftLight Apps/deploy"
scp Caddyfile medilens.service server-setup.sh root@VPS_IP:/root/
ssh root@VPS_IP 'bash /root/server-setup.sh'
```

Installs Node 22, Caddy, a `deploy` user, firewall rules, and both configs.

## 4. Deploy (repeat any time)

```bash
VPS_IP=1.2.3.4 bash deploy/deploy-site.sh        # static site
VPS_IP=1.2.3.4 bash deploy/deploy-medilens.sh    # builds + ships medilens-web
```

HTTPS certificates are issued automatically by Caddy on the first request
after DNS resolves — no certbot, no renewals to manage.

## Troubleshooting

```bash
ssh deploy@VPS_IP
systemctl status medilens          # app process
journalctl -u medilens -n 50       # app logs
sudo systemctl reload caddy        # after editing /etc/caddy/Caddyfile
journalctl -u caddy -n 50          # cert / proxy issues
```
