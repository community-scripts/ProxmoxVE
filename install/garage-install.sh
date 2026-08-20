#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://garagehq.deuxfleurs.fr/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

setup_deb_based() {
  msg_info "Setup Garage"
  GITEA_RELEASE=$(curl -s https://api.github.com/repos/deuxfleurs-org/garage/tags | jq -r '.[0].name')
  curl -fsSL "https://garagehq.deuxfleurs.fr/_releases/${GITEA_RELEASE}/$(arch_resolve "x86_64" "aarch64")-unknown-linux-musl/garage" -o /usr/local/bin/garage
  chmod +x /usr/local/bin/garage
  mkdir -p /var/lib/garage/{data,meta,snapshots}
  mkdir -p /etc/garage
  RPC_SECRET=$(openssl rand -hex 32)
  ADMIN_TOKEN=$(openssl rand -base64 32)
  METRICS_TOKEN=$(openssl rand -base64 32)
  cat <<EOF >~/garage.creds
Garage Tokens and Secrets
RPC Secret: $RPC_SECRET
Admin Token: $ADMIN_TOKEN
Metrics Token: $METRICS_TOKEN
EOF
  echo $GITEA_RELEASE >>~/.garage
  cat <<EOF >/etc/garage.toml
metadata_dir = "/var/lib/garage/meta"
data_dir = "/var/lib/garage/data"
db_engine = "sqlite"
replication_factor = 1

rpc_bind_addr = "[::]:3901"
rpc_public_addr = "127.0.0.1:3901"
rpc_secret = "${RPC_SECRET}"

[s3_api]
s3_region = "garage"
api_bind_addr = "[::]:3900"
root_domain = ".s3.garage.localhost"

[s3_web]
bind_addr = "[::]:3902"
root_domain = ".web.garage.localhost"
index = "index.html"

[k2v_api]
api_bind_addr = "[::]:3904"

[admin]
api_bind_addr = "[::]:3903"
admin_token = "${ADMIN_TOKEN}"
metrics_token = "${METRICS_TOKEN}"
EOF
  msg_ok "Set up Garage"

  msg_info "Creating service"
  cat <<'EOF' >/etc/systemd/system/garage.service
[Unit]
Description=Garage Object Storage (Deuxfleurs)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/garage -c /etc/garage.toml server
Restart=always
RestartSec=5
User=root
WorkingDirectory=/var/lib/garage
Environment=RUST_LOG=info
StandardOutput=append:/var/log/garage.log
StandardError=append:/var/log/garage.log
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
  $STD systemctl enable -q --now garage
  msg_ok "Created Service"
}

setup_alpine() {
  msg_info "Installing Dependencies"
  $STD apk add --no-cache openssl
  msg_ok "Installed Dependencies"

  GITEA_RELEASE=$(curl -s https://api.github.com/repos/deuxfleurs-org/garage/tags | jq -r '.[0].name')
  curl -fsSL "https://garagehq.deuxfleurs.fr/_releases/${GITEA_RELEASE}/$(arch_resolve "x86_64" "aarch64")-unknown-linux-musl/garage" -o /usr/local/bin/garage
  chmod +x /usr/local/bin/garage
  mkdir -p /var/lib/garage/{data,meta,snapshots}
  mkdir -p /etc/garage
  RPC_SECRET=$(openssl rand -hex 64 | cut -c1-64)
  ADMIN_TOKEN=$(openssl rand -base64 32)
  METRICS_TOKEN=$(openssl rand -base64 32)
  cat <<EOF >~/garage.creds
Garage Tokens and Secrets
RPC Secret: $RPC_SECRET
Admin Token: $ADMIN_TOKEN
Metrics Token: $METRICS_TOKEN
EOF
  echo $GITEA_RELEASE >>~/.garage
  cat <<EOF >/etc/garage.toml
metadata_dir = "/var/lib/garage/meta"
data_dir = "/var/lib/garage/data"
db_engine = "sqlite"
replication_factor = 1

rpc_bind_addr = "0.0.0.0:3901"
rpc_public_addr = "127.0.0.1:3901"
rpc_secret = "${RPC_SECRET}"

[s3_api]
s3_region = "garage"
api_bind_addr = "0.0.0.0:3900"
root_domain = ".s3.garage"

[s3_web]
bind_addr = "0.0.0.0:3902"
root_domain = ".web.garage"
index = "index.html"

[k2v_api]
api_bind_addr = "0.0.0.0:3904"

[admin]
api_bind_addr = "0.0.0.0:3903"
admin_token = "${ADMIN_TOKEN}"
metrics_token = "${METRICS_TOKEN}"
EOF
  msg_ok "Configured Garage"

  msg_info "Creating Service"
  cat <<'EOF' >/etc/init.d/garage
#!/sbin/openrc-run
name="Garage Object Storage"
command="/usr/local/bin/garage"
command_args="server"
command_background="yes"
pidfile="/run/garage.pid"
depend() {
    need net
}
EOF

  chmod +x /etc/init.d/garage
  $STD rc-update add garage default
  $STD rc-service garage restart || rc-service garage start
  msg_ok "Service active"
}

run_os_setup

motd_ssh
customize
cleanup_lxc
