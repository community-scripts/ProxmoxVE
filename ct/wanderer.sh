#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: rrole
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://wanderer.to

APP="Wanderer"
var_tags="${var_tags:-travelling;sport}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
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

  if check_for_gh_release "wanderer" "Flomp/wanderer"; then
    msg_info "Stopping service"
    systemctl stop wanderer-web
    msg_ok "Stopped service"

    fetch_and_deploy_gh_release "wanderer" "open-wanderer/wanderer" "tarball" "latest" "/opt/wanderer/source"

    msg_info "Updating wanderer"
    cd /opt/wanderer/source/db
    $STD go mod tidy
    $STD go build
    cd /opt/wanderer/source/web
    $STD npm ci --omit=dev
    $STD npm run build
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
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
