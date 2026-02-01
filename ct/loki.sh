#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: hoholms
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/grafana/loki

APP="Loki"
var_tags="${var_tags:-monitoring;logs}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-2}"
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

  if ! dpkg -s loki >/dev/null 2>&1; then
    msg_error "No ${APP} Installation Found!"
    exit 1
  fi

  while true; do
    CHOICE=$(
      whiptail --backtitle "Proxmox VE Helper Scripts" --title "SUPPORT" --menu "Select option" 11 58 3 \
        "1" "Update Loki & Promtail" \
        "2" "Allow 0.0.0.0 for listening" \
        "3" "Allow only ${LOCAL_IP} for listening" 3>&2 2>&1 1>&3
    )
    exit_status=$?
    if [ $exit_status == 1 ]; then
      clear
      exit-script
    fi
    header_info
    case $CHOICE in
    1)
      msg_info "Stopping Loki"
      systemctl stop loki
      if systemctl is-active --quiet promtail 2>/dev/null || dpkg -s promtail >/dev/null 2>&1; then
        systemctl stop promtail
      fi
      msg_ok "Stopped Loki"

      msg_info "Updating Loki"
      $STD apt update
      $STD apt install -y --only-upgrade loki
      if dpkg -s promtail >/dev/null 2>&1; then
        $STD apt install -y --only-upgrade promtail
      fi
      msg_ok "Updated Loki"

      msg_info "Starting Loki"
      systemctl start loki
      if dpkg -s promtail >/dev/null 2>&1; then
        systemctl start promtail
      fi
      msg_ok "Started Loki"
      msg_ok "Updated successfully!"
      exit
      ;;
    2)
      msg_info "Configuring Loki to listen on 0.0.0.0"
      sed -i 's/http_listen_address:.*/http_listen_address: 0.0.0.0/' /etc/loki/config.yml
      sed -i 's/http_listen_port:.*/http_listen_port: 3100/' /etc/loki/config.yml
      systemctl restart loki
      msg_ok "Configured Loki to listen on 0.0.0.0"
      exit
      ;;
    3)
      msg_info "Configuring Loki to listen on ${LOCAL_IP}"
      sed -i "s/http_listen_address:.*/http_listen_address: $LOCAL_IP/" /etc/loki/config.yml
      sed -i 's/http_listen_port:.*/http_listen_port: 3100/' /etc/loki/config.yml
      systemctl restart loki
      msg_ok "Configured Loki to listen on ${LOCAL_IP}"
      exit
      ;;
    esac
  done
  exit 0
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access loki using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3100${CL}\n"
if dpkg -s promtail >/dev/null 2>&1; then
  echo -e "${INFO}${YW} Access promtail using the following URL:${CL}"
  echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:9080${CL}"
fi
