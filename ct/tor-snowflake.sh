#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: KernelSailor
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://snowflake.torproject.org/

APP="tor-snowflake"
var_tags="${var_tags:-privacy;proxy;tor}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"
var_nesting="${var_nesting:-0}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  msg_info "Updating Container OS"
  $STD apt update
  $STD apt upgrade -y
  msg_ok "Updated Container OS"

  if [[ ! -d /opt/tor-snowflake ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if GITLAB_URL="https://gitlab.torproject.org" check_for_gl_release "tor-snowflake" "tpo/anti-censorship/pluggable-transports/snowflake"; then
    msg_info "Stopping Service"
    systemctl stop snowflake-proxy
    msg_ok "Stopped Service"

    CLEAN_INSTALL=1 GITLAB_URL="https://gitlab.torproject.org" fetch_and_deploy_gl_release "tor-snowflake" "tpo/anti-censorship/pluggable-transports/snowflake" "tarball"

    msg_info "Building Snowflake"
    cd /opt/tor-snowflake/proxy
    $STD go build -o snowflake-proxy .
    msg_ok "Built Snowflake"

    msg_info "Starting Service"
    systemctl start snowflake-proxy
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"

