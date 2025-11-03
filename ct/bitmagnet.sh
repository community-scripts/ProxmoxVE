#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/bitmagnet/bitmagnet

APP="Bitmagnet"
var_tags="${var_tags:-os}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
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
  if [[ ! -d /opt/bitmagnet ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "bitmagnet" "bitmagnet-io/bitmagnet"; then
    msg_info "Stopping Service"
    systemctl stop bitmagnet-web
    msg_ok "Stopped Service"

    msg_info "Backing up data"
    rm -f /tmp/backup.sql
    $STD sudo -u postgres pg_dump \
      --column-inserts \
      --data-only \
      --on-conflict-do-nothing \
      --rows-per-insert=1000 \
      --table=metadata_sources \
      --table=content \
      --table=content_attributes \
      --table=content_collections \
      --table=content_collections_content \
      --table=torrent_sources \
      --table=torrents \
      --table=torrent_files \
      --table=torrent_hints \
      --table=torrent_contents \
      --table=torrent_tags \
      --table=torrents_torrent_sources \
      --table=key_values \
      bitmagnet \
      >/tmp/backup.sql
    mv /tmp/backup.sql /opt/
    [ -f /opt/bitmagnet/.env ] && cp /opt/bitmagnet/.env /opt/
    [ -f /opt/bitmagnet/config.yml ] && cp /opt/bitmagnet/config.yml /opt/
    msg_ok "Data backed up"

    rm -rf /opt/bitmagnet
    fetch_and_deploy_gh_release "bitmagnet" "bitmagnet-io/bitmagnet"

    msg_info "Updating ${APP}"
    cd /opt/bitmagnet
    VREL=v$(curl -fsSL https://api.github.com/repos/bitmagnet-io/bitmagnet/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
    $STD go build -ldflags "-s -w -X github.com/bitmagnet-io/bitmagnet/internal/version.GitTag=$VREL"
    chmod +x bitmagnet
    [ -f "/opt/.env" ] && cp "/opt/.env" /opt/bitmagnet/
    [ -f "/opt/config.yml" ] && cp "/opt/config.yml" /opt/bitmagnet/
    msg_ok "Updated $APP"

    msg_info "Starting Service"
    systemctl start bitmagnet-web
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3333${CL}"
