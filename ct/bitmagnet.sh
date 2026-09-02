#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/bitmagnet-io/bitmagnet

APP="Bitmagnet"
var_tags="${var_tags:-os}"
var_cpu="${var_cpu:-2}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"
if [[ -z "${var_os:-}" ]] && command -v pveversion >/dev/null 2>&1; then
  var_os=$(msg_menu "Choose the container OS" \
    "debian" "Debian 13" \
    "alpine" "Alpine (smaller footprint)")
fi

if [[ "${var_os:-}" == "alpine" ]]; then
  var_ram="${var_ram:-2048}"
  var_disk="${var_disk:-3}"
  var_version="${var_version:-3.24}"
else
  var_ram="${var_ram:-2048}"
  var_disk="${var_disk:-4}"
  var_version="${var_version:-13}"
fi

header_info "$APP"
variables
color
catch_errors

update_deb_based() {
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
    create_backup /opt/bitmagnet/.env \
      /opt/bitmagnet/config.yml
    msg_ok "Data backed up"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "bitmagnet" "bitmagnet-io/bitmagnet" "tarball"
    GO_VERSION="$(grep -m1 '^go ' /opt/bitmagnet/go.mod | awk '{print $2}')" setup_go
    restore_backup

    msg_info "Configuring Bitmagnet"
    cd /opt/bitmagnet
    VREL=v$(curl -fsSL https://api.github.com/repos/bitmagnet-io/bitmagnet/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
    $STD go build -ldflags "-s -w -X github.com/bitmagnet-io/bitmagnet/internal/version.GitTag=$VREL"
    chmod +x bitmagnet
    msg_ok "Configured Bitmagnet"

    msg_info "Starting Service"
    systemctl start bitmagnet-web
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
}

update_alpine() {
  if [[ ! -d /opt/bitmagnet ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -fsSL https://api.github.com/repos/bitmagnet-io/bitmagnet/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [ "${RELEASE}" != "$(cat /opt/bitmagnet_version.txt)" ] || [ ! -f /opt/bitmagnet_version.txt ]; then
    msg_info "Backing up database"
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
    msg_ok "Database backed up"

    msg_info "Updating ${APP} from $(cat /opt/bitmagnet_version.txt) to ${RELEASE}"
    $STD apk -U upgrade
    $STD service bitmagnet stop
    [ -f /opt/bitmagnet/.env ] && cp /opt/bitmagnet/.env /opt/
    [ -f /opt/bitmagnet/config.yml ] && cp /opt/bitmagnet/config.yml /opt/
    rm -rf /opt/bitmagnet/*
    temp_file=$(mktemp)
    curl -fsSL "https://github.com/bitmagnet-io/bitmagnet/archive/refs/tags/v${RELEASE}.tar.gz" -o "$temp_file"
    tar zxf "$temp_file" --strip-components=1 -C /opt/bitmagnet
    cd /opt/bitmagnet
    VREL=v$RELEASE
    $STD go build -ldflags "-s -w -X github.com/bitmagnet-io/bitmagnet/internal/version.GitTag=$VREL"
    chmod +x bitmagnet
    [ -f "/opt/.env" ] && cp "/opt/.env" /opt/bitmagnet/
    [ -f "/opt/config.yml" ] && cp "/opt/config.yml" /opt/bitmagnet/
    rm -f "$temp_file"
    echo "${RELEASE}" >/opt/bitmagnet_version.txt
    $STD service bitmagnet start
    msg_ok "Updated successfully!"
  else
    msg_ok "No update required. ${APP} is already at ${RELEASE}"
  fi
}

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  run_os_update
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:3333${CL}"
