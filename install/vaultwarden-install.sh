#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/dani-garcia/vaultwarden

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  build-essential \
  pkgconf \
  libssl-dev \
  libmariadb-dev-compat \
  libpq-dev \
  argon2 \
  ssl-cert
msg_ok "Installed Dependencies"

setup_rust
fetch_and_deploy_gh_release "vaultwarden" "dani-garcia/vaultwarden" "tarball" "latest" "/tmp/vaultwarden-src"

msg_info "Building Vaultwarden (Patience)"
cd /tmp/vaultwarden-src
$STD cargo build --features "sqlite,mysql,postgresql" --release
msg_ok "Built Vaultwarden"

msg_info "Setting up Vaultwarden"
$STD addgroup --system vaultwarden
$STD adduser --system --home /opt/vaultwarden --shell /usr/sbin/nologin --no-create-home --gecos 'vaultwarden' --ingroup vaultwarden --disabled-login --disabled-password vaultwarden
mkdir -p /opt/vaultwarden/{bin,data,web-vault}
cp target/release/vaultwarden /opt/vaultwarden/bin/
cd ~ && rm -rf /tmp/vaultwarden-src
msg_ok "Set up Vaultwarden"

fetch_and_deploy_gh_release "vaultwarden_webvault" "dani-garcia/bw_web_builds" "prebuild" "latest" "/opt/vaultwarden/web-vault" "bw_web_*.tar.gz"

msg_info "Configuring Vaultwarden"
cat <<EOF >/opt/vaultwarden/.env
ADMIN_TOKEN=''
ROCKET_ADDRESS=0.0.0.0
ROCKET_TLS='{certs="/opt/vaultwarden/ssl-cert-snakeoil.pem",key="/opt/vaultwarden/ssl-cert-snakeoil.key"}'
DATA_FOLDER=/opt/vaultwarden/data
DATABASE_MAX_CONNS=10
WEB_VAULT_FOLDER=/opt/vaultwarden/web-vault
WEB_VAULT_ENABLED=true
EOF
mv /etc/ssl/certs/ssl-cert-snakeoil.pem /opt/vaultwarden/
mv /etc/ssl/private/ssl-cert-snakeoil.key /opt/vaultwarden/

chown -R vaultwarden:vaultwarden /opt/vaultwarden/
chown root:root /opt/vaultwarden/bin/vaultwarden
chmod +x /opt/vaultwarden/bin/vaultwarden
chown -R root:root /opt/vaultwarden/web-vault/
chmod +r /opt/vaultwarden/.env
msg_ok "Configured Vaultwarden"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/vaultwarden.service
[Unit]
Description=Bitwarden Server (Powered by Vaultwarden)
Documentation=https://github.com/dani-garcia/vaultwarden
After=network.target

[Service]
User=vaultwarden
Group=vaultwarden
EnvironmentFile=-/opt/vaultwarden/.env
ExecStart=/opt/vaultwarden/bin/vaultwarden
LimitNOFILE=65535
LimitNPROC=4096
PrivateTmp=true
PrivateDevices=true
ProtectHome=true
ProtectSystem=strict
DevicePolicy=closed
ProtectControlGroups=yes
ProtectKernelModules=yes
ProtectKernelTunables=yes
RestrictNamespaces=yes
RestrictRealtime=yes
MemoryDenyWriteExecute=yes
LockPersonality=yes
WorkingDirectory=/opt/vaultwarden
ReadWriteDirectories=/opt/vaultwarden/data
AmbientCapabilities=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now vaultwarden
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
