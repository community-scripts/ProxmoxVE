#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
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

  if [[ ! -d /opt/wanderer/source ]]; then
    msg_error "No wanderer Installation Found!"
    exit
  fi

  if [[ ! -f /etc/systemd/system/meilisearch.service ]]; then
    msg_info "Migrating MeiliSearch"
    systemctl stop wanderer-web

    rm -rf /opt/wanderer/source/search
    MEILI_MASTER_KEY_VAL=$(grep -oP '^MEILI_MASTER_KEY=\K.*' /opt/wanderer/.env)
    cat <<EOF >/etc/meilisearch.toml
env = "production"
master_key = "$MEILI_MASTER_KEY_VAL"
db_path = "/opt/wanderer/data/meili_data"
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

  if [[ -f /opt/wanderer/start.sh ]]; then
    msg_info "Migrating wanderer services"
    systemctl stop wanderer-web
    rm -f /opt/wanderer/start.sh
    rm -rf /opt/wanderer/source/search

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
WorkingDirectory=/opt/wanderer/source/db
EnvironmentFile=/opt/wanderer/.env
ExecStart=/opt/wanderer/source/db/pocketbase serve --http=\${PB_URL} --dir=\${PB_DB_LOCATION}
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
WorkingDirectory=/opt/wanderer/source/web
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

    create_backup /opt/wanderer/source
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "wanderer" "open-wanderer/wanderer" "tarball" "latest" "/opt/wanderer/source"
    restore_backup

    msg_info "Updating wanderer"
    cd /opt/wanderer/source/db
    $STD go mod tidy
    $STD go build
    cd /opt/wanderer/source/web
    $STD npm ci
    $STD npm run build
    mkdir -p /opt/wanderer/data/plugins /opt/wanderer/source/db/data
    [[ -e /opt/wanderer/source/db/data/plugins ]] || ln -sfn /opt/wanderer/data/plugins /opt/wanderer/source/db/data/plugins
    msg_info "Installing wanderer plugins"
    for plugin in hammerhead komoot strava; do
      fetch_and_deploy_gh_release "wanderer-plugin-${plugin}" "open-wanderer/wanderer" "prebuild" "${CHECK_UPDATE_RELEASE:-latest}" "/opt/wanderer/data/plugins" "wanderer-plugin-${plugin}.tar.gz" || msg_warn "Failed to install wanderer plugin: ${plugin}"
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
