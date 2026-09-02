#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: rrole
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://wanderer.to | Github: https://github.com/open-wanderer/wanderer

APP="Wanderer"
var_tags="${var_tags:-travelling;sport}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/wanderer/source && ! -d /opt/wanderer/db ]]; then
    msg_error "No wanderer Installation Found!"
    exit
  fi

  if [[ ! -f /etc/systemd/system/meilisearch.service ]]; then
    msg_info "Migrating MeiliSearch"
    systemctl stop wanderer-web

    rm -rf /opt/wanderer/source/search
    mkdir -p /opt/wanderer_data
    [[ -d /opt/wanderer/data/meili_data ]] && cp -r /opt/wanderer/data/meili_data /opt/wanderer_data/
    mkdir -p /opt/wanderer_data/meili_data
    rm -rf /opt/wanderer/data/meili_data
    MEILI_MASTER_KEY_VAL=$(grep -oP '^MEILI_MASTER_KEY=\K.*' /opt/wanderer/.env)
    cat <<EOF >/etc/meilisearch.toml
env = "production"
master_key = "$MEILI_MASTER_KEY_VAL"
db_path = "/opt/wanderer_data/meili_data"
dump_dir = "/var/lib/meilisearch/dumps"
snapshot_dir = "/var/lib/meilisearch/snapshots"
no_analytics = true
http_addr = "127.0.0.1:7700"
EOF
    mkdir -p /var/lib/meilisearch/dumps /var/lib/meilisearch/snapshots

    cat <<EOF >/etc/systemd/system/meilisearch.service
[Unit]
Description=Meilisearch
After=network.target

[Service]
ExecStart=/usr/bin/meilisearch --config-file-path /etc/meilisearch.toml
Restart=always

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable -q --now meilisearch

    sed -i \
      -e "s|^MEILI_HTTP_ADDR=.*|MEILI_HTTP_ADDR=127.0.0.1:7700|" \
      -e "s|^MEILI_URL=.*|MEILI_URL=http://127.0.0.1:7700|" \
      /opt/wanderer/.env

    msg_ok "Migrated Meilisearch"
  fi

  setup_meilisearch

  if [[ -f /opt/wanderer/start.sh || -d /opt/wanderer/source ]]; then
    msg_info "Migrating wanderer services"
    systemctl stop wanderer-web
    rm -f /opt/wanderer/start.sh

    mkdir -p /opt/wanderer_data
    [[ -d /opt/wanderer/data/pb_data ]] && cp -r /opt/wanderer/data/pb_data /opt/wanderer_data/
    [[ -d /opt/wanderer/data/plugins ]] && cp -r /opt/wanderer/data/plugins /opt/wanderer_data/
    mkdir -p /opt/wanderer_data/{pb_data,plugins}
    rm -rf /opt/wanderer/data

    [[ -d /opt/wanderer/source ]] && cp -r /opt/wanderer/source/. /opt/wanderer/
    rm -rf /opt/wanderer/source

    if [[ -d /opt/wanderer/db/data ]]; then
      [[ -e /opt/wanderer/db/data/plugins ]] || ln -sfn /opt/wanderer_data/plugins /opt/wanderer/db/data/plugins
    fi

    sed -i \
      -e "s|^PB_DB_LOCATION=.*|PB_DB_LOCATION=/opt/wanderer_data/pb_data|" \
      -e "s|^MEILI_DB_PATH=.*|MEILI_DB_PATH=/opt/wanderer_data/meili_data|" \
      /opt/wanderer/.env
    sed -i "s|^db_path =.*|db_path = \"/opt/wanderer_data/meili_data\"|" /etc/meilisearch.toml
    rm -f /usr/local/bin/wanderer-pb

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
    systemctl daemon-reload
    systemctl enable -q wanderer-pocketbase
    systemctl start wanderer-web
    msg_ok "Migrated wanderer services"
  fi

  if check_for_gh_release "wanderer" "open-wanderer/wanderer"; then
    msg_info "Stopping service"
    systemctl stop wanderer-web
    msg_ok "Stopped service"

    create_backup /opt/wanderer/.env
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "wanderer" "open-wanderer/wanderer" "tarball" "latest"
    restore_backup

    GO_VERSION="$(grep -m1 '^go ' /opt/wanderer/db/go.mod | awk '{print $2}')" setup_go

    msg_info "Updating wanderer"
    cd /opt/wanderer/db
    $STD go mod tidy
    $STD go build
    cd /opt/wanderer/web
    $STD npm ci
    $STD npm run build
    mkdir -p /opt/wanderer_data/plugins /opt/wanderer/db/data
    [[ -e /opt/wanderer/db/data/plugins ]] || ln -sfn /opt/wanderer_data/plugins /opt/wanderer/db/data/plugins
    msg_info "Installing wanderer plugins"
    for plugin in hammerhead komoot strava; do
      fetch_and_deploy_gh_release "wanderer-plugin-${plugin}" "open-wanderer/wanderer" "prebuild" "${CHECK_UPDATE_RELEASE:-latest}" "/opt/wanderer_data/plugins" "wanderer-plugin-${plugin}.tar.gz" || msg_warn "Failed to install wanderer plugin: ${plugin}"
    done
    msg_ok "Installed wanderer plugins"
    msg_ok "Updated wanderer"

    msg_info "Starting service"
    systemctl start wanderer-web
    msg_ok "Started service"
    msg_ok "Update Successful"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:3000${CL}"
