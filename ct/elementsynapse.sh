#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: tremor021
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/element-hq/synapse

APP="Element Synapse"
var_tags="${var_tags:-server}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
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
  if [[ ! -d /etc/matrix-synapse ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if [[ ! -f /opt/"${APP}"_version.txt ]]; then
    touch /opt/"${APP}"_version.txt
  fi
  if ! dpkg -l | grep -q '^ii.*gpg'; then
    $STD apt-get update
    $STD apt-get install -y gpg
  fi
  if [[ ! -x /usr/bin/node ]]; then
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" >/etc/apt/sources.list.d/nodesource.list
    $STD apt-get update
    $STD apt-get install -y nodejs
    $STD npm install -g yarn
  fi
  msg_info "Updating $APP LXC"
  $STD apt-get update
  $STD apt-get -y upgrade
  msg_ok "Updated $APP LXC"

  if [[ -f /etc/systemd/system/synapse-admin.service ]]; then
    msg_info "Updating Synapse-Admin"
    RELEASE=$(curl -fsSL https://api.github.com/repos/etkecc/synapse-admin/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
    if [[ "${RELEASE}" != "$(cat /opt/"${APP}"_version.txt)" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then
      temp_file=$(mktemp)
      systemctl stop synapse-admin
      rm -rf /opt/synapse-admin
      mkdir -p /opt/synapse-admin
      curl -fsSL "https://github.com/etkecc/synapse-admin/archive/refs/tags/v${RELEASE}.tar.gz" -o "$temp_file"
      tar xzf "$temp_file" -C /opt/synapse-admin --strip-components=1
      cd /opt/synapse-admin
      $STD yarn global add serve
      $STD yarn install --ignore-engines
      $STD yarn build
      mv ./dist ../ &&
        rm -rf * &&
        mv ../dist ./
      if [[ -z $(grep "ExecStart=/usr/local/bin/serve" /etc/systemd/system/synapse-admin.service) ]]; then
        sed -i 's|^ExecStart=.*|ExecStart=/usr/local/bin/serve -s dist -l 5173|' /etc/systemd/system/synapse-admin.service
        systemctl reenable synapse-admin
      fi
      systemctl start synapse-admin
      echo "${RELEASE}" >/opt/"${APP}"_version.txt
      rm -f "$temp_file"
      msg_ok "Updated successfully!"
    else
      msg_ok "No update required. ${APP} is already at v${RELEASE}"
    fi
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8008${CL}"
