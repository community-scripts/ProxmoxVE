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

  if [[ ! -f /opt/wanderer/start.sh ]]; then
    msg_error "No wanderer Installation Found!"
    exit
  fi

  if check_for_gh_release "wanderer" "open-wanderer/wanderer"; then
    msg_info "Stopping service"
    systemctl stop wanderer-web
    msg_ok "Stopped service"

    create_backup /opt/wanderer/source/search
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "wanderer" "open-wanderer/wanderer" "tarball" "latest" "/opt/wanderer/source"
    restore_backup

    msg_info "Updating wanderer"
    cd /opt/wanderer/source/db
    $STD go mod tidy
    $STD go build
    cd /opt/wanderer/source/web
    $STD npm ci
    $STD npm run build
    mkdir -p /opt/wanderer/data/plugins
    [[ -e /data/plugins ]] || ln -sfn /opt/wanderer/data/plugins /data/plugins
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
  if check_for_gh_release "meilisearch" "meilisearch/meilisearch"; then
    msg_info "Stopping service"
    systemctl stop wanderer-web
    msg_ok "Stopped service"

    fetch_and_deploy_gh_release "meilisearch" "meilisearch/meilisearch" "binary" "latest" "/opt/wanderer/source/search"
    grep -q -- '--experimental-dumpless-upgrade' /opt/wanderer/start.sh || sed -i 's|meilisearch --master-key|meilisearch --experimental-dumpless-upgrade --master-key|' /opt/wanderer/start.sh

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
