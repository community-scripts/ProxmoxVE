#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
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
$STD yarn --frozen-lockfile
$STD yarn next telemetry disable
$STD yarn build
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
ExecStart=yarn start
Restart=on-abnormal

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now jotty
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
