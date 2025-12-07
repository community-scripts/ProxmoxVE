#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://garagehq.deuxfleurs.fr/

APP="Garage"
var_tags="${var_tags:-object-storage}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-5}"
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
  if [[ ! -f /usr/local/bin/garage ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if [[ ! -d /opt/garage-webui ]]; then
    read -rp "${TAB3}Do you wish to add Garage WebUI to existing installation? [y/N] " webui
    if [[ "${webui}" =~ ^[Yy]$ ]]; then
      fetch_and_deploy_gh_release "garage-webui" "khairul169/garage-webui" "singlefile" "latest" "/opt/garage-webui" "garage-webui-*-linux-amd64"
      cat <<EOF > /etc/systemd/system/garage-webui.service
[Unit]
Description=Garage WebUI
After=network.target

[Service]
Environment="PORT=3919"
Environment="CONFIG_PATH=/etc/garage.toml"
ExecStart=/opt/garage-webui/garage-webui
Restart=always

[Install]
WantedBy=multi-user.target
EOF
      systemctl enable -q --now garage-webui
    fi
  fi

  GITEA_RELEASE=$(curl -fsSL https://api.github.com/repos/deuxfleurs-org/garage/tags | jq -r '.[0].name')
  if [[ "${GITEA_RELEASE}" != "$(cat ~/.garage 2>/dev/null)" ]] || [[ ! -f ~/.garage ]]; then
    msg_info "Stopping Garage Service"
    systemctl stop garage
    msg_ok "Stopped Garage Service"

    msg_info "Backing Up Data"
    cp /usr/local/bin/garage /usr/local/bin/garage.old 2>/dev/null || true
    cp /etc/garage.toml /etc/garage.toml.bak 2>/dev/null || true
    msg_ok "Backed Up Data"

    msg_info "Updating Garage"
    curl -fsSL "https://garagehq.deuxfleurs.fr/_releases/${GITEA_RELEASE}/x86_64-unknown-linux-musl/garage" -o /usr/local/bin/garage
    chmod +x /usr/local/bin/garage
    echo "${GITEA_RELEASE}" >~/.garage
    msg_ok "Updated Garage"

    if [[ -f /etc/systemd/system/garage-webui.service ]]; then
      msg_info "Stopping WebUI Service"
      systemctl stop garage-webui
      msg_ok "Stopped WebUI Service"

      CLEAN_INSTALL=1 fetch_and_deploy_gh_release "garage-webui" "khairul169/garage-webui" "singlefile" "latest" "/opt/garage-webui" "garage-webui-*-linux-amd64"

      msg_info "Starting WebUI Service"
      systemctl start garage-webui
      msg_ok "Started WebUI Service"
    fi
    
    msg_info "Starting Garage Service"
    systemctl start garage
    msg_ok "Started Garage Service"
    msg_ok "Updated successfully!"
  else
    msg_ok "No update required. Garage is already at ${GITEA_RELEASE}"
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
