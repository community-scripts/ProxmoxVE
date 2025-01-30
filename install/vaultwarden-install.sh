#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get update
$STD apt-get -qqy install \
  git \
  build-essential \
  pkgconf \
  libssl-dev \
  libmariadb-dev-compat \
  libpq-dev \
  curl \
  sudo \
  argon2 \
  mc
msg_ok "Installed Dependencies"

WEBVAULT=$(curl -s https://api.github.com/repos/dani-garcia/bw_web_builds/releases/latest |
  grep "tag_name" |
  awk '{print substr($2, 2, length($2)-3) }')

VAULT=$(curl -s https://api.github.com/repos/dani-garcia/vaultwarden/releases/latest |
  grep "tag_name" |
  awk '{print substr($2, 2, length($2)-3) }')

msg_info "Installing Rust"
wget -qL https://sh.rustup.rs
$STD bash index.html -y --profile minimal
echo 'export PATH=~/.cargo/bin:$PATH' >>~/.bashrc
export PATH=~/.cargo/bin:$PATH
rm index.html
msg_ok "Installed Rust"

msg_info "Building Vaultwarden ${VAULT} (Patience)"
$STD git clone https://github.com/dani-garcia/vaultwarden
cd vaultwarden
$STD cargo build --features "sqlite,mysql,postgresql" --release
msg_ok "Built Vaultwarden ${VAULT}"

$STD addgroup --system vaultwarden
$STD adduser --system --home /opt/vaultwarden --shell /usr/sbin/nologin --no-create-home --gecos 'vaultwarden' --ingroup vaultwarden --disabled-login --disabled-password vaultwarden
mkdir -p /opt/vaultwarden/bin
mkdir -p /opt/vaultwarden/data
cp target/release/vaultwarden /opt/vaultwarden/bin/

msg_info "Downloading Web-Vault ${WEBVAULT}"
$STD curl -fsSLO https://github.com/dani-garcia/bw_web_builds/releases/download/$WEBVAULT/bw_web_$WEBVAULT.tar.gz
$STD tar -xzf bw_web_$WEBVAULT.tar.gz -C /opt/vaultwarden/
msg_ok "Downloaded Web-Vault ${WEBVAULT}"

cat <<EOF >/opt/vaultwarden/.env
ADMIN_TOKEN=''
ROCKET_ADDRESS=0.0.0.0
DATA_FOLDER=/opt/vaultwarden/data
DATABASE_MAX_CONNS=10
WEB_VAULT_FOLDER=/opt/vaultwarden/web-vault
WEB_VAULT_ENABLED=true
EOF

msg_info "Creating Service"
chown -R vaultwarden:vaultwarden /opt/vaultwarden/
chown root:root /opt/vaultwarden/bin/vaultwarden
chmod +x /opt/vaultwarden/bin/vaultwarden
chown -R root:root /opt/vaultwarden/web-vault/
chmod +r /opt/vaultwarden/.env

service_path="/etc/systemd/system/vaultwarden.service"
echo "[Unit]
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
WantedBy=multi-user.target" >$service_path
systemctl daemon-reload
$STD systemctl enable --now vaultwarden.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
