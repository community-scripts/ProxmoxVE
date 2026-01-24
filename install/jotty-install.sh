#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/fccview/jotty

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

NODE_VERSION="22" NODE_MODULE="yarn" setup_nodejs
fetch_and_deploy_gh_release "jotty" "fccview/jotty" "tarball" "latest" "/opt/jotty"

msg_info "Installing ${APPLICATION}"
cd /opt/jotty
unset NODE_OPTIONS
export NODE_OPTIONS="--max-old-space-size=3072"
$STD yarn --frozen-lockfile
$STD yarn next telemetry disable
$STD yarn build

[ -d "public" ] && cp -r public .next/standalone/
[ -d "howto" ] && cp -r howto .next/standalone/
mkdir -p .next/standalone/.next
cp -r .next/static .next/standalone/.next/

mv .next/standalone /tmp/jotty_standalone
rm -rf ./* .next .git .gitignore .yarn
mv /tmp/jotty_standalone/* .
mv /tmp/jotty_standalone/.[!.]* . 2>/dev/null || true
rm -rf /tmp/jotty_standalone

mkdir -p data/{users,checklists,notes}

cat <<EOF >/opt/jotty/.env
NODE_ENV=production

# --- Uncomment to enable
# HTTPS=true
# SERVE_PUBLIC_IMAGES=yes
# SERVE_PUBLIC_FILES=yes
# SERVE_PUBLIC_VIDEOS=yes
# STOP_CHECK_UPDATES=yes
# --- For troubleshooting
# DEBUGGER=true

# --- SSO with OIDC (optional)
# SSO_MODE=oidc
# OIDC_ISSUER=<your-oidc-issuer-url>
# OIDC_CLIENT_ID=<oidc-client-id>
# APP_URL=<https://app.domain.tld>
# SSO_FALLBACK_LOCAL=yes
# OIDC_CLIENT_SECRET=your_client_secret
# OIDC_ADMIN_GROUPS=admins
EOF
msg_ok "Installed ${APPLICATION}"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/jotty.service
[Unit]
Description=jotty server
After=network.target

[Service]
WorkingDirectory=/opt/jotty
EnvironmentFile=/opt/jotty/.env
ExecStart=/usr/bin/node server.js
Restart=on-abnormal

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now jotty
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
