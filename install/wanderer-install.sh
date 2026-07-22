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

setup_go
NODE_VERSION="22" setup_nodejs
if [[ "$(arch_resolve)" == "arm64" ]]; then
  fetch_and_deploy_gh_release "meilisearch" "meilisearch/meilisearch" "singlefile" "latest" "/usr/local/bin" "meilisearch-linux-aarch64"
else
  fetch_and_deploy_gh_release "meilisearch" "meilisearch/meilisearch" "binary" "latest" "/opt/wanderer/source/search"
fi
mkdir -p /opt/wanderer/{source,data/pb_data,data/meili_data,data/plugins}
fetch_and_deploy_gh_release "wanderer" "open-wanderer/wanderer" "tarball" "latest" "/opt/wanderer/source"
mkdir -p /opt/wanderer/source/db/data
[[ -e /opt/wanderer/source/db/data/plugins ]] || ln -sfn /opt/wanderer/data/plugins /opt/wanderer/source/db/data/plugins

msg_info "Installing wanderer (patience)"
cd /opt/wanderer/source/db
$STD go mod tidy
$STD go build
cd /opt/wanderer/source/web
$STD npm ci
$STD npm run build
msg_ok "Installed wanderer"

msg_info "Installing wanderer plugins"
for plugin in hammerhead komoot strava; do
  fetch_and_deploy_gh_release "wanderer-plugin-${plugin}" "open-wanderer/wanderer" "prebuild" "latest" "/opt/wanderer/data/plugins" "wanderer-plugin-${plugin}.tar.gz" || msg_warn "Failed to install wanderer plugin: ${plugin}"
done
msg_ok "Installed wanderer plugins"

msg_info "Creating Service"
MEILI_KEY=$(openssl rand -hex 32)
POCKETBASE_KEY=$(openssl rand -hex 16)

cat <<EOF >/opt/wanderer/.env
ORIGIN=http://${LOCAL_IP}:3000
MEILI_HTTP_ADDR=${LOCAL_IP}:7700
MEILI_URL=http://${LOCAL_IP}:7700
MEILI_MASTER_KEY=${MEILI_KEY}
PB_URL=${LOCAL_IP}:8090
PUBLIC_POCKETBASE_URL=http://${LOCAL_IP}:8090
PUBLIC_VALHALLA_URL=https://valhalla1.openstreetmap.de
POCKETBASE_ENCRYPTION_KEY=${POCKETBASE_KEY}
PB_DB_LOCATION=/opt/wanderer/data/pb_data
MEILI_DB_PATH=/opt/wanderer/data/meili_data
EOF

cat <<EOF >/opt/wanderer/start.sh
#!/usr/bin/env bash

trap "kill 0" EXIT

cd /opt/wanderer/source/search && meilisearch --experimental-dumpless-upgrade --master-key \$MEILI_MASTER_KEY &
sleep 1
cd /opt/wanderer/source/db && ./pocketbase serve --http=\$PB_URL --dir=\$PB_DB_LOCATION &
cd /opt/wanderer/source/web && node build &

wait -n
EOF
chmod +x /opt/wanderer/start.sh

cat <<'EOF' >/usr/local/bin/wanderer-pb
#!/usr/bin/env bash
set -a
source /opt/wanderer/.env
set +a
cd /opt/wanderer/source/db
exec ./pocketbase "$@" --dir="$PB_DB_LOCATION"
EOF
chmod +x /usr/local/bin/wanderer-pb

cat <<EOF >/etc/systemd/system/wanderer-web.service
[Unit]
Description=wanderer
After=network.target
StartLimitIntervalSec=10
StartLimitBurst=5

[Service]
Type=simple
EnvironmentFile=/opt/wanderer/.env
ExecStart=/usr/bin/bash /opt/wanderer/start.sh
Restart=always
RestartSec=1

[Install]
WantedBy=multi-user.target
EOF
sleep 1
systemctl enable -q --now wanderer-web
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
