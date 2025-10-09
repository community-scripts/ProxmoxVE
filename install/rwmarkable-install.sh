#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/fccview/rwMarkable

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

NODE_VERSION="22" NODE_MODULE="yarn" setup_nodejs
fetch_and_deploy_gh_release "rwMarkable" "fccview/rwMarkable" "tarball" "latest" "/opt/rwmarkable"

msg_info "Installing ${APPLICATION}"
cd /opt/rwmarkable
$STD yarn --frozen-lockfile
$STD yarn next telemetry disable
$STD yarn build
mkdir -p data/{users,checklists,notes}

cat <<EOF >/opt/rwmarkable/.env
NODE_ENV=production
# HTTPS=true

# --- SSO with OIDC (optional)
# SSO_MODE=oidc
# OIDC_ISSUER=<your-oidc-issuer-url>
# OIDC_CLIENT_ID=<oidc-client-id>
# APP_URL=<https://app.domain.tld>
# SSO_FALLBACK_LOCAL=true # Allow both SSO and normal login
# OIDC_CLIENT_SECRET=your_client_secret  # Enable confidential client mode with client authentication
# OIDC_ADMIN_GROUPS=admins # Map provider groups to admin role
EOF
msg_ok "Installed ${APPLICATION}"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/rwmarkable.service
[Unit]
Description=rwMarkable server
After=network.target

[Service]
WorkingDirectory=/opt/rwmarkable
EnvironmentFile=/opt/rwmarkable/.env
ExecStart=yarn start
Restart=on-abnormal

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now rwmarkable
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
