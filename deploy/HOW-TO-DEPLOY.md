# How to get your changes into production

*A guide for future you. No prior deployment knowledge assumed.*

## The big picture

There are **three copies** of each site, and it helps to keep them straight:

```
1. Your PC                    2. GitHub                   3. The VPS (production)
   C:\projects\...        →      backup / history      →     what visitors see at
   where you edit code           (git push)                  softlightapps.com
```

**Important:** GitHub and production are *not* connected. Pushing to GitHub
does **not** update the live site. The live site only changes when you run a
deploy script from your PC. So a full "ship it" is always two steps:
**push to GitHub** (backup) + **run the deploy script** (go live).

Run everything below in **Git Bash** (right-click in the folder → "Git Bash here",
or use the terminal in VS Code set to Git Bash).

---

## Updating the main site (softlightapps.com)

Source: `C:\projects\SoftLight Apps` — plain HTML/CSS, no build step.

```bash
cd "/c/projects/SoftLight Apps"

# 1. Save your work in git and back it up to GitHub
git add -A
git commit -m "describe what you changed"
git push

# 2. Put it live (copies the files to the server)
VPS_IP=13.140.166.131 bash deploy/deploy-site.sh
```

That's it. Refresh https://softlightapps.com — changes appear immediately
(hard-refresh with Ctrl+F5 if your browser cached the old page).

> Note: if you add a **new** image or file to the site, also add it to the
> `scp` list inside `deploy/deploy-site.sh`, otherwise it won't be uploaded.

---

## Updating MediLens (medilens.softlightapps.com)

Source: `C:\projects\medilens-web` — this one has a build step, but the
deploy script runs it for you.

```bash
cd /c/projects/medilens-web

# 1. Save and back up
git add -A
git commit -m "describe what you changed"
git push

# 2. Build + upload + restart the server app (takes ~1 minute)
VPS_IP=13.140.166.131 bash "/c/projects/SoftLight Apps/deploy/deploy-medilens.sh"
```

The script builds the site, uploads it, installs dependencies on the server,
and restarts the `medilens` service. When it prints
`Deployed. Check https://medilens.softlightapps.com`, you're live.

---

## "Is everything still running?"

```bash
ssh deploy@13.140.166.131            # log into the server
systemctl status medilens            # MediLens app — should say "active (running)"
systemctl status caddy               # web server — should say "active (running)"
journalctl -u medilens -n 50         # last 50 log lines from the MediLens app
exit                                 # leave the server
```

Both services start automatically if the VPS reboots. HTTPS certificates
renew themselves — you never need to touch them.

## If a deploy goes wrong

- **Site shows an error after deploying MediLens** → look at the logs:
  `ssh deploy@13.140.166.131 "journalctl -u medilens -n 50"`
- **Deploy script fails to connect** → the VPS may be down; check your
  provider's dashboard, and that you can `ssh deploy@13.140.166.131`.
- **Rollback** = deploy the previous version: in the project,
  `git log --oneline` to find the last good commit,
  `git checkout <commit-id>`, run the deploy script, then `git checkout main`.

## What's actually on the server (reference)

| Thing | Where | What it does |
|---|---|---|
| Caddy | `/etc/caddy/Caddyfile` | Web server: HTTPS, serves static files, forwards MediLens page requests to the Node app |
| Static site | `/var/www/softlightapps/` | The files deploy-site.sh uploads |
| MediLens app | `/srv/medilens/` | Built app + Node server on port 3000 |
| `medilens` service | `/etc/systemd/system/medilens.service` | Keeps the Node app running, restarts it if it crashes |

One-time setup (already done, only needed again if you ever rebuild the VPS
from scratch) is in [README.md](README.md).
