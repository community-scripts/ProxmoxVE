#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://garagehq.deuxfleurs.fr/

APP="Alpine-Garage"
var_tags="${var_tags:-alpine;object-storage}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-5}"
var_os="${var_os:-alpine}"
var_version="${var_version:-3.22}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  if [[ ! -f /usr/local/bin/garage ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if [[ ! -d /opt/garage-webui ]]; then
    read -rp "${TAB3}Do you wish to add Garage WebUI to existing installation? [y/N] " webui
    if [[ "${webui}" =~ ^[Yy]$ ]]; then
      RELEASE=$(curl -s https://api.github.com/repos/khairul169/garage-webui/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
      curl -fsSL "https://github.com/khairul169/garage-webui/releases/download/${RELEASE}/garage-webui-v${RELEASE}-linux-amd64" -o /opt/garage-webui/garage-webui
      chmod +x /opt/garage-webui/garage-webui
      cat <<'EOF' >/etc/init.d/garage-webui
#!/sbin/openrc-run
name="Garage WebUI"
description="Garage WebUI"
command="/opt/garage-webui/garage-webui"
command_args=""
command_background="yes"
pidfile="/run/garage-webui.pid"
depend() {
    need net
}

start_pre() {
    export CONFIG_PATH="/etc/garage.toml"
}
EOF
      chmod +x /etc/init.d/garage-webui
      $STD rc-update add garage-webui default
      $STD rc-service garage-webui start
    fi
  fi

  GITEA_RELEASE=$(curl -fsSL https://api.github.com/repos/deuxfleurs-org/garage/tags | jq -r '.[0].name')
  if [[ "${GITEA_RELEASE}" != "$(cat ~/.garage 2>/dev/null)" ]] || [[ ! -f ~/.garage ]]; then
    msg_info "Stopping Service"
    rc-service garage stop
    msg_ok "Stopped Service"

    msg_info "Backing Up Data"
    cp /usr/local/bin/garage /usr/local/bin/garage.old
    cp /etc/garage.toml /etc/garage.toml.bak
    msg_ok "Backed Up Data"

    msg_info "Updating Garage"
    curl -fsSL "https://garagehq.deuxfleurs.fr/_releases/${GITEA_RELEASE}/x86_64-unknown-linux-musl/garage" -o /usr/local/bin/garage
    chmod +x /usr/local/bin/garage
    echo "${GITEA_RELEASE}" >~/.garage
    msg_ok "Updated Garage"

    if [[ -f /etc/init.d/garage-webui ]]; then
      msg_info "Stopping Garage WebUI Service"
      rc-service garage-webui stop
      msg_ok "Stopped Garage WebUI Service"

      RELEASE=$(curl -s https://api.github.com/repos/khairul169/garage-webui/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
      if [[ "${RELEASE}" != "$(cat ~/.garage-webui 2>/dev/null)" ]] || [[ ! -f ~/.garage-webui ]]; then
        msg_info "Updating Garage WebUI"
        rm -f /opt/garage-webui/garage-webui
        curl -fsSL "https://github.com/khairul169/garage-webui/releases/download/${RELEASE}/garage-webui-v${RELEASE}-linux-amd64" -o /opt/garage-webui/garage-webui
        chmod +x /opt/garage-webui/garage-webui
        echo "${RELEASE}" >~/.garage-webui
        msg_ok "Updated Garage WebUI"
    fi
  fi

    msg_info "Starting Services"
    rc-service garage start || rc-service garage restart
    if [[ -f /etc/init.d/garage-webui ]]; then
      rc-service garage-webui start
    fi
    msg_ok "Started Services"
    msg_ok "Updated successfully!"
  else
    msg_ok "No update required. Garage is already at ${GITEA_RELEASE}"
  fi
  exit 0
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
