#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/searxng/searxng

APP="SearXNG"
var_tags="${var_tags:-search}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-7}"
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
  if [[ ! -d /usr/local/searxng/searxng-src ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  chown -R searxng:searxng /usr/local/searxng/searxng-src
  if su -s /bin/bash -c "git -C /usr/local/searxng/searxng-src pull" searxng | grep -q 'Already up to date'; then
     msg_ok "There is currently no update available."
     exit
  fi

  msg_info "Updating SearXNG installation"
  msg_info "Stopping Service"
  systemctl stop searxng
  msg_ok "Stopped Service"

  msg_info "Updating SearXNG"
  $STD su -s /bin/bash searxng -c '
    python3 -m venv /usr/local/searxng/searx-pyenv &&
    . /usr/local/searxng/searx-pyenv/bin/activate &&
    pip install -U pip setuptools wheel pyyaml lxml msgspec typing_extensions &&
    pip install --use-pep517 --no-build-isolation -e /usr/local/searxng/searxng-src
    '
  msg_ok "Updated SearXNG"
  
  msg_info "Starting Services"
  systemctl start searxng
  msg_ok "Started Services"
  msg_ok "Updated successfully!"
 fi
 exit
}
start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8888${CL}"
