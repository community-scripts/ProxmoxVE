#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
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
$STD apt install -y git \
  build-essential \
  pkgconf \
  libssl-dev \
  libmariadb-dev-compat \
  libpq-dev \
  argon2 \
  ssl-cert
msg_ok "Installed Dependencies"

WEBVAULT=$(curl -fsSL https://api.github.com/repos/dani-garcia/bw_web_builds/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
VAULT=$(curl -fsSL https://api.github.com/repos/dani-garcia/vaultwarden/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')

msg_info "Installing Rust"
curl -fsSL https://sh.rustup.rs -o rustup-init.sh
$STD bash rustup-init.sh -y --profile minimal
echo 'export PATH="$HOME/.cargo/bin:$PATH"' >>~/.bashrc
export PATH="$HOME/.cargo/bin:$PATH"
rm rustup-init.sh
msg_ok "Installed Rust"

msg_info "Building Vaultwarden ${VAULT} (Patience)"
$STD git clone https://github.com/dani-garcia/vaultwarden
cd vaultwarden || exit
$STD cargo build --features "sqlite,mysql,postgresql" --release
msg_ok "Built Vaultwarden ${VAULT}"

$STD addgroup --system vaultwarden
$STD adduser --system --home /opt/vaultwarden --shell /usr/sbin/nologin --no-create-home --gecos 'vaultwarden' --ingroup vaultwarden --disabled-login --disabled-password vaultwarden
mkdir -p /opt/vaultwarden/bin
mkdir -p /opt/vaultwarden/data
cp target/release/vaultwarden /opt/vaultwarden/bin/

msg_info "Downloading Web-Vault ${WEBVAULT}"
$STD curl -fsSLO https://github.com/dani-garcia/bw_web_builds/releases/download/"$WEBVAULT"/bw_web_"$WEBVAULT".tar.gz
$STD tar -xzf bw_web_"$WEBVAULT".tar.gz -C /opt/vaultwarden/
msg_ok "Downloaded Web-Vault ${WEBVAULT}"

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
$STD systemctl enable --now vaultwarden
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
