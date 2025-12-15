#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: mrosero
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://tt-rss.org/

APP="TinyTinyRSS"
var_tags="${var_tags:-RSS;feed-reader}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-4}"
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
  if [[ ! -d /opt/tt-rss ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "tt-rss" "HubOrg/tt-rss"; then
    msg_info "Stopping Services"
    systemctl stop apache2
    msg_ok "Stopped Services"

    msg_info "Backing up Configuration"
    if [ -f /opt/tt-rss/config.php ]; then
      cp /opt/tt-rss/config.php /opt/tt-rss/config.php.backup
      msg_ok "Backed up Configuration"
    fi
    if [ -d /opt/tt-rss/feed-icons ]; then
      mv /opt/tt-rss/feed-icons /opt/tt-rss/feed-icons.backup
      msg_ok "Backed up Feed Icons"
    fi

    msg_info "Updating ${APP} to latest version"
    fetch_and_deploy_gh_release "tt-rss" "HubOrg/tt-rss" "tarball" "latest" "/opt/tt-rss"

    if [ -f /opt/tt-rss/config.php.backup ]; then
      cp /opt/tt-rss/config.php.backup /opt/tt-rss/config.php
      msg_ok "Restored Configuration"
    fi
    if [ -d /opt/tt-rss/feed-icons.backup ]; then
      mv /opt/tt-rss/feed-icons.backup /opt/tt-rss/feed-icons
      msg_ok "Restored Feed Icons"
    fi

    msg_info "Setting Permissions"
    chown -R www-data:www-data /opt/tt-rss
    chmod -R g+rX /opt/tt-rss
    chmod -R g+w /opt/tt-rss/feed-icons /opt/tt-rss/lock /opt/tt-rss/cache
    msg_ok "Set Permissions"

    msg_info "Starting Services"
    systemctl start apache2
    msg_ok "Started Services"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
