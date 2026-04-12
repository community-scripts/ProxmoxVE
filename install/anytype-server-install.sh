#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://anytype.io

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

setup_mongodb

msg_info "Configuring MongoDB Replica Set"
cat <<EOF >>/etc/mongod.conf

replication:
  replSetName: "rs0"
EOF
systemctl restart mongod
for i in $(seq 1 30); do
  if mongosh --quiet --eval "db.adminCommand('ping')" &>/dev/null; then
    break
  fi
  sleep 2
done
$STD mongosh --eval 'rs.initiate({_id: "rs0", members: [{_id: 0, host: "127.0.0.1:27017"}]})'
msg_ok "Configured MongoDB Replica Set"

msg_info "Installing Redis Stack"
setup_deb822_repo \
  "redis-stack" \
  "https://packages.redis.io/gpg" \
  "https://packages.redis.io/deb" \
  "jammy" \
  "main"
$STD apt install -y redis-stack-server
systemctl enable -q --now redis-stack-server
msg_ok "Installed Redis Stack"

fetch_and_deploy_gh_release "anytype" "grishy/any-sync-bundle" "prebuild" "latest" "/opt/anytype" "any-sync-bundle_*_linux_amd64.tar.gz"
chmod +x /opt/anytype/any-sync-bundle

msg_info "Configuring Anytype"
mkdir -p /opt/anytype/data/storage
cat <<EOF >/opt/anytype/.env
ANY_SYNC_BUNDLE_CONFIG=/opt/anytype/data/bundle-config.yml
ANY_SYNC_BUNDLE_CLIENT_CONFIG=/opt/anytype/data/client-config.yml
ANY_SYNC_BUNDLE_INIT_STORAGE=/opt/anytype/data/storage/
ANY_SYNC_BUNDLE_INIT_EXTERNAL_ADDRS=${LOCAL_IP}
ANY_SYNC_BUNDLE_INIT_MONGO_URI=mongodb://127.0.0.1:27017/
ANY_SYNC_BUNDLE_INIT_REDIS_URI=redis://127.0.0.1:6379/
ANY_SYNC_BUNDLE_LOG_LEVEL=info
EOF
msg_ok "Configured Anytype"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/anytype.service
[Unit]
Description=Anytype Sync Server (any-sync-bundle)
After=network-online.target mongod.service redis-stack-server.service
Wants=network-online.target
Requires=mongod.service redis-stack-server.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/anytype
EnvironmentFile=/opt/anytype/.env
ExecStart=/opt/anytype/any-sync-bundle start-bundle
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now anytype
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
