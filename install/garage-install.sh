#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Test Suite for tools.func
# License: MIT
# https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Purpose: Run comprehensive test suite for all setup_* functions from tools.func

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Setup Garage"
GITEA_RELEASE=$(curl -s https://api.github.com/repos/deuxfleurs-org/garage/tags | jq -r '.[0].name')
curl -fsSL "https://garagehq.deuxfleurs.fr/_releases/${GITEA_RELEASE}/x86_64-unknown-linux-musl/garage" -o /usr/local/bin/garage
chmod +x /usr/local/bin/garage
mkdir -p /var/lib/garage/{data,meta,snapshots}
mkdir -p /etc/garage
RPC_SECRET=$(openssl rand -hex 32)
ADMIN_TOKEN=$(openssl rand -base64 32)
METRICS_TOKEN=$(openssl rand -base64 32)
{
    echo "Garage Tokens and Secrets"
    echo "RPC Secret: $RPC_SECRET"
    echo "Admin Token: $ADMIN_TOKEN"
    echo "Metrics Token: $METRICS_TOKEN"
} >>~/garage.creds
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


motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
