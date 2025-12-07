#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
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

msg_info "Installing Dependencies"
$STD apk add --no-cache openssl
msg_ok "Installed Dependencies"

GITEA_RELEASE=$(curl -s https://api.github.com/repos/deuxfleurs-org/garage/tags | jq -r '.[0].name')
curl -fsSL "https://garagehq.deuxfleurs.fr/_releases/${GITEA_RELEASE}/x86_64-unknown-linux-musl/garage" -o /usr/local/bin/garage
chmod +x /usr/local/bin/garage
mkdir -p /var/lib/garage/{data,meta,snapshots}
mkdir -p /etc/garage
RPC_SECRET=$(openssl rand -hex 64 | cut -c1-64)
ADMIN_TOKEN=$(openssl rand -base64 32)
METRICS_TOKEN=$(openssl rand -base64 32)
{
  echo "Garage Tokens and Secrets"
  echo "RPC Secret: $RPC_SECRET"
  echo "Admin Token: $ADMIN_TOKEN"
  echo "Metrics Token: $METRICS_TOKEN"
} >~/garage.creds
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

read -rp "${TAB3}Do you wish to add Garage WebUI? [y/N] " webui
if [[ "${webui}" =~ ^[Yy]$ ]]; then
  mkdir -p /opt/garage-webui
  RELEASE=$(curl -s https://api.github.com/repos/khairul169/garage-webui/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
  curl -fsSL "https://github.com/khairul169/garage-webui/releases/download/${RELEASE}/garage-webui-v${RELEASE}-linux-amd64" -o /opt/garage-webui/garage-webui
  chmod +x /opt/garage-webui/garage-webui 
  echo "${RELEASE}" >~/.garage-webui
fi

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

if [[ "${webui}" =~ ^[Yy]$ ]]; then
  cat <<'EOF' >/etc/init.d/garage-webui
#!/sbin/openrc-run
name="Garage WebUI"
description="Garage WebUI"
command="/opt/garage-webui/garage-webui"
command_args=""
command_background="yes"
pidfile="/run/garage-webui.pid"
depend() {
    need net
}

start_pre() {
    export CONFIG_PATH="/etc/garage.toml"
}
EOF
fi
chmod +x /etc/init.d/garage-webui
$STD rc-update add garage-webui default
$STD rc-service garage-webui start
msg_ok "Service Created"

motd_ssh
customize
