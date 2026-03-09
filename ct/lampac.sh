#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.debian.org/

function header_info {
clear
cat <<"EOF"
   __                               
  / /   ____ _____ ___  ____  ____ 
 / /   / __ `/ __ `__ \/ __ \/ __ `/ 
/ /___/ /_/ / / / / / / /_/ / /_/ /  
\____/\__,_/_/ /_/ /_/ .___/\__,_/   
                    /_/                  
EOF
}
header_info
echo -e "Loading..."

APP="Debian"
var_tags="${var_tags:-os}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
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
  if [[ ! -d /var ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  msg_info "Updating $APP LXC"
  $STD apt update
  $STD apt -y upgrade
  msg_ok "Updated $APP LXC"
  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"