#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: cheesejaguar
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/maximhq/bifrost

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

# Gateway binaries live on the upstream CDN; GitHub also releases unrelated SDKs and plugins.
if ! check_for_gh_release "bifrost" "maximhq/bifrost" "${var_appversion:-}" "" "transports/v"; then
  msg_error "Could not select a Bifrost gateway release"
  exit 1
fi

msg_info "Installing Bifrost Gateway"
BIFROST_URL="https://downloads.getmaxim.ai/bifrost/${CHECK_UPDATE_RELEASE##*/}/linux/$(arch_resolve)"
mkdir -p /opt/bifrost /opt/bifrost-update
chmod 700 /opt/bifrost-update
curl_with_retry "${BIFROST_URL}/bifrost-http" /opt/bifrost-update/bifrost-http
curl_with_retry "${BIFROST_URL}/bifrost-http.sha256" /opt/bifrost-update/bifrost-http.sha256
cd /opt/bifrost-update || exit 1
$STD sha256sum --check bifrost-http.sha256
install -m 755 /opt/bifrost-update/bifrost-http /opt/bifrost/bifrost-http
cd /opt/bifrost || exit 1
rm -rf /opt/bifrost-update
msg_ok "Installed Bifrost Gateway"

msg_info "Configuring Bifrost"
mkdir -p /opt/bifrost_data
chmod 700 /opt/bifrost_data
cat <<EOF >/opt/bifrost_data/.env
BIFROST_ADMIN_PASSWORD=$(random_password 32)
BIFROST_ENCRYPTION_KEY=$(random_password 64)
BIFROST_SETUP_TOKEN=$(random_password 32)
EOF
cat <<'EOF' >/opt/bifrost_data/config.json
{
  "encryption_key": "env.BIFROST_ENCRYPTION_KEY",
  "setup_token": "env.BIFROST_SETUP_TOKEN",
  "client": {
    "enforce_auth_on_inference": true
  },
  "governance": {
    "auth_config": {
      "admin_username": "admin",
      "admin_password": "env.BIFROST_ADMIN_PASSWORD",
      "is_enabled": true
    }
  }
}
EOF
chmod 600 /opt/bifrost_data/.env /opt/bifrost_data/config.json
msg_ok "Configured Bifrost"

msg_info "Creating Bifrost Service"
cat <<EOF >/etc/systemd/system/bifrost.service
[Unit]
Description=Bifrost AI Gateway
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/bifrost_data
EnvironmentFile=/opt/bifrost_data/.env
UMask=0077
ExecStart=/opt/bifrost/bifrost-http -host 0.0.0.0 -port 8080 -app-dir /opt/bifrost_data
Restart=on-failure
RestartSec=5
TimeoutStopSec=60

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now bifrost
$STD curl --fail --silent --show-error --retry 30 --retry-connrefused --retry-delay 2 --retry-max-time 120 --max-time 5 http://127.0.0.1:8080/health
systemctl is-active --quiet bifrost
cat <<EOF >~/.bifrost
${CHECK_UPDATE_RELEASE}
EOF
msg_ok "Created Bifrost Service"

motd_ssh
customize
cleanup_lxc
