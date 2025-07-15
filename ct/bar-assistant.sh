#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: bvdberg01 | CanbiZ
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/karlomikus/bar-assistant
# Source: https://github.com/karlomikus/vue-salt-rim
# Source: https://www.meilisearch.com/

APP="Bar-Assistant"
var_tags="${var_tags:-cocktails;drinks}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/bar-assistant ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE_MEILISEARCH=$(curl -fsSL https://api.github.com/repos/meilisearch/meilisearch/releases/latest | jq -r '.tag_name | sub("^v"; "")')
  RELEASE_BARASSISTANT=$(curl -fsSL https://api.github.com/repos/karlomikus/bar-assistant/releases/latest | jq -r '.tag_name | sub("^v"; "")')
  RELEASE_SALTRIM=$(curl -fsSL https://api.github.com/repos/karlomikus/vue-salt-rim/releases/latest | jq -r '.tag_name | sub("^v"; "")')

  if [[ "${RELEASE_BARASSISTANT}" != "$(cat ~/.bar-assistant 2>/dev/null)" ]] || [[ ! -f ~/.bar-assistant ]]; then
    msg_info "Stopping nginx"
    systemctl stop nginx
    msg_ok "Stopped nginx"

    msg_info "Backing up Bar Assistant"
    mv /opt/bar-assistant /opt/bar-assistant-backup
    msg_ok "Backed up Bar Assistant"

    fetch_and_deploy_gh_release "bar-assistant" "karlomikus/bar-assistant" "tarball" "latest" "/opt/bar-assistant"

    msg_info "Updating ${APP} to ${RELEASE_BARASSISTANT}"
    cp -r /opt/bar-assistant-backup/.env /opt/bar-assistant/.env
    cp -r /opt/bar-assistant-backup/storage/bar-assistant /opt/bar-assistant/storage/bar-assistant
    cd /opt/bar-assistant
    $STD composer install --no-interaction
    $STD php artisan migrate --force
    $STD php artisan storage:link
    $STD php artisan bar:setup-meilisearch
    $STD php artisan scout:sync-index-settings
    $STD php artisan config:cache
    $STD php artisan route:cache
    $STD php artisan event:cache
    chown -R www-data:www-data /opt/bar-assistant
    msg_ok "Updated $APP to ${RELEASE_BARASSISTANT}"

    msg_info "Starting nginx"
    systemctl start nginx
    msg_ok "Started nginx"

    msg_info "Cleaning up"
    rm -rf /opt/bar-assistant-backup
    msg_ok "Cleaned"
  else
    msg_ok "No update required. ${APP} is already at ${RELEASE_BARASSISTANT}"
  fi

  if [[ "${RELEASE_SALTRIM}" != "$(cat ~/.vue-salt-rim 2>/dev/null)" ]] || [[ ! -f ~/.vue-salt-rim ]]; then
    msg_info "Backing up Vue Salt Rim"
    mv /opt/vue-salt-rim /opt/vue-salt-rim-backup
    msg_ok "Backed up Vue Salt Rim"

    msg_info "Stopping nginx"
    systemctl stop nginx
    msg_ok "Stopped nginx"

    fetch_and_deploy_gh_release "vue-salt-rim" "karlomikus/vue-salt-rim" "tarball" "latest" "/opt/vue-salt-rim"

    msg_info "Updating Salt Rim to ${RELEASE_SALTRIM}"
    cp /opt/vue-salt-rim-backup/public/config.js /opt/vue-salt-rim/public/config.js
    cd /opt/vue-salt-rim
    $STD npm install
    $STD npm run build
    msg_ok "Updated $APP to ${RELEASE_SALTRIM}"

    msg_info "Starting nginx"
    systemctl start nginx
    msg_ok "Started nginx"

    msg_info "Cleaning up"
    rm -rf /opt/vue-salt-rim-backup
    msg_ok "Cleaned"
    msg_ok "Updated"
  else
    msg_ok "No update required. Salt Rim is already at ${RELEASE_SALTRIM}"
  fi

  if [[ "${RELEASE_MEILISEARCH}" != "$(cat ~/.meilisearch 2>/dev/null)" ]] || [[ ! -f ~/.meilisearch ]]; then
    msg_info "Stopping Meilisearch"
    systemctl stop meilisearch
    msg_ok "Stopped Meilisearch"

    fetch_and_deploy_gh_release "meilisearch" "meilisearch/meilisearch" "binary"

    msg_info "Starting Meilisearch"
    systemctl start meilisearch
    msg_ok "Started Meilisearch"

    msg_ok "Updated Meilisearch"
  else
    msg_ok "No update required. Meilisearch is already at ${RELEASE_MEILISEARCH}"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
