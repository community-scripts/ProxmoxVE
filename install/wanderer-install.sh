#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: rrole
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://wanderer.to | Github: https://github.com/open-wanderer/wanderer

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

NODE_VERSION="22" setup_nodejs
mkdir -p /opt/{wanderer,wanderer_data/pb_data,wanderer_data/meili_data,wanderer_data/plugins}
MEILISEARCH_DB_PATH="/opt/wanderer_data/meili_data" setup_meilisearch
fetch_and_deploy_gh_release "wanderer" "open-wanderer/wanderer" "tarball" "latest"
mkdir -p /opt/wanderer/db/data
[[ -e /opt/wanderer/db/data/plugins ]] || ln -sfn /opt/wanderer_data/plugins /opt/wanderer/db/data/plugins

GO_VERSION="$(grep -m1 '^go ' /opt/wanderer/db/go.mod | awk '{print $2}')" setup_go

msg_info "Installing wanderer (patience)"
cd /opt/wanderer/db
$STD go mod tidy
$STD go build
cd /opt/wanderer/web
$STD npm ci
$STD npm run build
msg_ok "Installed wanderer"

msg_info "Installing wanderer plugins"
for plugin in hammerhead komoot strava; do
  fetch_and_deploy_gh_release "wanderer-plugin-${plugin}" "open-wanderer/wanderer" "prebuild" "latest" "/opt/wanderer_data/plugins" "wanderer-plugin-${plugin}.tar.gz" || msg_warn "Failed to install wanderer plugin: ${plugin}"
done
msg_ok "Installed wanderer plugins"

msg_info "Creating Service"
POCKETBASE_KEY=$(openssl rand -hex 16)

cat <<EOF >/opt/wanderer/.env
ORIGIN=http://${LOCAL_IP}:3000
MEILI_HTTP_ADDR=127.0.0.1:7700
MEILI_URL=http://127.0.0.1:7700
MEILI_MASTER_KEY=${MEILISEARCH_MASTER_KEY}
PB_URL=${LOCAL_IP}:8090
PUBLIC_POCKETBASE_URL=http://${LOCAL_IP}:8090
PUBLIC_VALHALLA_URL=https://valhalla1.openstreetmap.de
POCKETBASE_ENCRYPTION_KEY=${POCKETBASE_KEY}
PB_DB_LOCATION=/opt/wanderer_data/pb_data
MEILI_DB_PATH=/opt/wanderer_data/meili_data
EOF

cat <<EOF >/etc/systemd/system/wanderer-pocketbase.service
[Unit]
Description=wanderer PocketBase
Wants=network.target
After=network.target
PartOf=wanderer-web.service
StartLimitIntervalSec=10
StartLimitBurst=5

[Service]
Type=simple
WorkingDirectory=/opt/wanderer/db
EnvironmentFile=/opt/wanderer/.env
ExecStart=/opt/wanderer/db/pocketbase serve --http=\${PB_URL} --dir=\${PB_DB_LOCATION}
Restart=always
RestartSec=1

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/wanderer-web.service
[Unit]
Description=wanderer
Wants=network.target meilisearch.service wanderer-pocketbase.service
After=network.target meilisearch.service wanderer-pocketbase.service
StartLimitIntervalSec=10
StartLimitBurst=5

[Service]
Type=simple
WorkingDirectory=/opt/wanderer/web
EnvironmentFile=/opt/wanderer/.env
ExecStart=/usr/bin/node build
Restart=always
RestartSec=1

[Install]
WantedBy=multi-user.target
EOF
sleep 1
systemctl enable -q --now wanderer-pocketbase wanderer-web
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
