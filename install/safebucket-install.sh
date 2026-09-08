#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: renizmy
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/safebucket/safebucket

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y awscli
msg_ok "Installed Dependencies"

msg_info "Installing Garage"
useradd --system --no-create-home --shell /usr/sbin/nologin garage 2>/dev/null || true
GARAGE_VERSION=$(get_latest_gh_tag "deuxfleurs-org/garage" "v")
if [[ -z "$GARAGE_VERSION" ]]; then
  msg_error "Could not determine latest stable Garage version"
  exit 1
fi
curl -fsSL "https://garagehq.deuxfleurs.fr/_releases/${GARAGE_VERSION}/$(arch_resolve "x86_64-unknown-linux-musl" "aarch64-unknown-linux-musl")/garage" -o /usr/local/bin/garage
chmod +x /usr/local/bin/garage
mkdir -p /opt/garage/{data,meta}
RPC_SECRET=$(openssl rand -hex 32)
ADMIN_TOKEN=$(openssl rand -base64 32)
cat <<EOF >/opt/garage/garage.toml
metadata_dir = "/opt/garage/meta"
data_dir = "/opt/garage/data"
db_engine = "lmdb"
replication_factor = 1

rpc_bind_addr = "[::]:3901"
rpc_public_addr = "127.0.0.1:3901"
rpc_secret = "${RPC_SECRET}"

[s3_api]
s3_region = "garage"
api_bind_addr = "[::]:3900"
root_domain = ".s3.garage.localhost"

[admin]
api_bind_addr = "[::]:3903"
admin_token = "${ADMIN_TOKEN}"
EOF
chmod 600 /opt/garage/garage.toml
chown -R garage:garage /opt/garage
cat <<EOF >/etc/systemd/system/garage.service
[Unit]
Description=Garage Object Storage
After=network.target

[Service]
Type=simple
User=garage
Group=garage
WorkingDirectory=/opt/garage
ExecStart=/usr/local/bin/garage -c /opt/garage/garage.toml server
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now garage
msg_ok "Installed Garage"

msg_info "Configuring Garage Bucket"
RETRIES=0
until garage -c /opt/garage/garage.toml status &>/dev/null; do
  RETRIES=$((RETRIES + 1))
  if [[ $RETRIES -ge 60 ]]; then
    msg_error "Garage did not become ready within 60 seconds"
    exit 1
  fi
  sleep 1
done
NODE_ID=$(garage -c /opt/garage/garage.toml status 2>/dev/null | awk '/^[0-9a-f]/{print $1; exit}')
if [[ -z "$NODE_ID" ]]; then
  msg_error "Could not determine Garage node ID from cluster status"
  exit 1
fi
GARAGE_CAPACITY="${GARAGE_CAPACITY:-$(df -BG --output=avail /opt/garage | awk 'NR==2{gsub(/G/,"",$1); v=$1-1; print (v<1?1:v)"G"}')}"
$STD garage -c /opt/garage/garage.toml layout assign -z dc1 -c "${GARAGE_CAPACITY}" "${NODE_ID}"
$STD garage -c /opt/garage/garage.toml layout apply --version 1
GARAGE_KEY_INFO=$(garage -c /opt/garage/garage.toml key create safebucket-key)
GARAGE_ACCESS_KEY=$(echo "$GARAGE_KEY_INFO" | awk '/Key ID:/{print $3}')
GARAGE_SECRET_KEY=$(echo "$GARAGE_KEY_INFO" | awk '/Secret key:/{print $3}')
$STD garage -c /opt/garage/garage.toml bucket create safebucket
$STD garage -c /opt/garage/garage.toml bucket allow --read --write --owner safebucket --key safebucket-key
msg_ok "Configured Garage Bucket"

msg_info "Applying CORS Policy to Bucket"
export AWS_ACCESS_KEY_ID="${GARAGE_ACCESS_KEY}"
export AWS_SECRET_ACCESS_KEY="${GARAGE_SECRET_KEY}"
export AWS_DEFAULT_REGION="garage"
if aws s3api put-bucket-cors \
  --bucket safebucket \
  --endpoint-url "http://127.0.0.1:3900" \
  --cors-configuration '{"CORSRules":[{"AllowedHeaders":["*"],"AllowedMethods":["GET","PUT","POST","DELETE","HEAD"],"AllowedOrigins":["http://'"${LOCAL_IP}"':8080"],"ExposeHeaders":["ETag"]}]}' &>/dev/null; then
  msg_ok "Applied CORS Policy to Bucket"
else
  msg_warn "Could not apply CORS policy automatically; direct browser uploads may fail until CORS is configured manually"
fi
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_DEFAULT_REGION

fetch_and_deploy_gh_release "safebucket" "safebucket/safebucket" "singlefile" "latest" "/opt/safebucket" "safebucket-linux-$(arch_resolve)"

msg_info "Configuring Safebucket"
useradd --system --no-create-home --shell /usr/sbin/nologin safebucket 2>/dev/null || true
mkdir -p /opt/safebucket/data/{notifications,activity}
TOKEN_SECRET=$(openssl rand -base64 32)
MFA_KEY=$(openssl rand -base64 48 | tr -dc 'a-zA-Z0-9' | cut -c1-32)
ADMIN_PASSWORD=$(openssl rand -hex 12)
cat <<EOF >/opt/safebucket/config.yaml
app:
  profile: default
  log_level: info
  api_url: http://${LOCAL_IP}:8080
  web_url: http://${LOCAL_IP}:8080
  allowed_origins:
    - http://${LOCAL_IP}:8080
  port: 8080
  token_secret: "${TOKEN_SECRET}"
  mfa_encryption_key: "${MFA_KEY}"
  mfa_required: false
  admin_email: admin@safebucket.io
  admin_password: "${ADMIN_PASSWORD}"
  trash_retention_days: 7
  max_upload_size: 5368709120
  trusted_proxies:
    - 10.0.0.0/8
    - 172.16.0.0/12
    - 192.168.0.0/16
    - 127.0.0.0/8
    - ::1/128
    - fc00::/7
  static_files:
    enabled: true

database:
  type: sqlite
  sqlite:
    path: /opt/safebucket/data/safebucket.db

cache:
  type: memory

storage:
  type: s3
  s3:
    bucket_name: safebucket
    endpoint: 127.0.0.1:3900
    external_endpoint: http://${LOCAL_IP}:3900
    access_key: ${GARAGE_ACCESS_KEY}
    secret_key: ${GARAGE_SECRET_KEY}
    region: garage
    force_path_style: true
    use_tls: false

events:
  type: memory
  queues:
    notifications:
      name: safebucket-notifications
    object_deletion:
      name: safebucket-object-deletion
    bucket_events:
      name: safebucket-bucket-events

notifier:
  type: filesystem
  filesystem:
    directory: /opt/safebucket/data/notifications

activity:
  type: filesystem
  filesystem:
    directory: /opt/safebucket/data/activity

auth:
  providers:
    local:
      name: local
      type: local
      sharing:
        allowed: true
        domains: []
EOF
chmod 600 /opt/safebucket/config.yaml
chown -R safebucket:safebucket /opt/safebucket
msg_ok "Configured Safebucket"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/safebucket.service
[Unit]
Description=Safebucket File Sharing Platform
After=network-online.target garage.service
Wants=network-online.target
Requires=garage.service

[Service]
Type=simple
User=safebucket
Group=safebucket
WorkingDirectory=/opt/safebucket
Environment=CONFIG_FILE_PATH=/opt/safebucket/config.yaml
ExecStart=/opt/safebucket/safebucket
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now safebucket
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
