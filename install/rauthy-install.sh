#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/sebadob/rauthy

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
  pkg-config
msg_ok "Installed Dependencies"

setup_rust
fetch_and_deploy_gh_release "rauthy" "sebadob/rauthy" "tarball" "latest" "/opt/rauthy-build"

msg_info "Building Rauthy (Patience)"
cd /opt/rauthy-build
tar -xf assets/static_html/static_v1.tar.gz
tar -xf assets/static_html/templates_html.tar.gz
if ! CURL_RETRIES=8 curl_with_retry "https://mds.fidoalliance.org/" "/opt/rauthy-build/mds.jwt"; then
  msg_error "The FIDO MDS download was rate-limited (HTTP 429); run the script again in a few minutes"
  exit 7
fi
CARGO_PROFILE_DEV_DEBUG=0 $STD cargo run --bin fido-mds-prep -- --source mds.jwt
CARGO_PROFILE_RELEASE_LTO=thin CARGO_PROFILE_RELEASE_CODEGEN_UNITS=16 \
  $STD cargo build --release --bin rauthy
mkdir -p /opt/rauthy
mv target/release/rauthy /opt/rauthy/rauthy
cd /opt
rm -rf /opt/rauthy-build ~/.cargo/registry
msg_ok "Built Rauthy"

create_self_signed_cert "rauthy"

msg_info "Configuring Rauthy"
mkdir -p /opt/rauthy_data
ENC_KEY_ID=$(openssl rand -hex 4)
cat <<EOF >/opt/rauthy_data/config.toml
## Reference: https://sebadob.github.io/rauthy/config/config.html

[bootstrap]
# Password for admin@localhost, only read when the database is created on the first start
password_plain = '$(random_password)'

[cluster]
node_id = 1
nodes = ['1 localhost:8100 localhost:8200']
data_dir = '/opt/rauthy_data/hiqlite'
secret_raft = '$(random_password 48)'
secret_api = '$(random_password 48)'

[email]
#smtp_url = 'smtp.example.com'
#smtp_username = 'rauthy@example.com'
#smtp_password = ''
#smtp_from = 'Rauthy <rauthy@example.com>'

[encryption]
keys = ['${ENC_KEY_ID}/$(openssl rand -base64 32)']
key_active = '${ENC_KEY_ID}'

[mfa]
# Passkeys need a DNS name, so admin MFA cannot be set up while Rauthy is reached by IP
admin_force_mfa = false

[server]
scheme = 'https'
pub_url = '${LOCAL_IP}:8443'

[tls]
cert_path = '/etc/ssl/rauthy/rauthy.crt'
key_path = '/etc/ssl/rauthy/rauthy.key'

[webauthn]
# Must be a domain, an IP is rejected; set both to the public DNS name before registering passkeys
rp_id = 'localhost'
rp_origin = 'https://localhost:8443'
EOF
chmod 600 /opt/rauthy_data/config.toml
msg_ok "Configured Rauthy"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/rauthy.service
[Unit]
Description=Rauthy
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/rauthy_data
Environment=MALLOC_CONF=abort_conf:true,narenas:8,tcache_max:4096,dirty_decay_ms:5000,muzzy_decay_ms:5000
ExecStart=/opt/rauthy/rauthy serve -c /opt/rauthy_data/config.toml
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now rauthy
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
