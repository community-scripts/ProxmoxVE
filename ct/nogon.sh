#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/asciimoo/nogon

APP="Nogon"
var_tags="${var_tags:-search;browser-history;personal}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-20}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -f /usr/local/bin/nogon && ! -f /usr/local/bin/hister ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  MIGRATING=false
  [[ -f /usr/local/bin/hister ]] && MIGRATING=true

  if [[ "$MIGRATING" == "true" ]] || check_for_gh_release "nogon" "asciimoo/nogon"; then
    msg_info "Stopping Service"
    if [[ "$MIGRATING" == "true" ]]; then
      systemctl disable -q --now hister
    else
      systemctl stop nogon
    fi
    msg_ok "Stopped Service"

    fetch_and_deploy_gh_release "nogon" "asciimoo/nogon" "singlefile" "latest" "/usr/local/bin" "nogon_*_linux_$(arch_resolve)"

    if [[ "$MIGRATING" == "true" ]]; then
      msg_info "Migrating Hister to Nogon"
      CONFIG_FILE=/etc/nogon/config.yaml
      [[ -f /etc/hister/config.yaml ]] && CONFIG_FILE=/etc/hister/config.yaml
      cat <<EOF >/etc/systemd/system/nogon.service
[Unit]
Description=Nogon Search Engine
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/nogon listen --config ${CONFIG_FILE}
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
      rm -f /etc/systemd/system/hister.service /usr/local/bin/hister ~/.hister
      systemctl daemon-reload
      systemctl enable -q nogon
      sed -i 's/hister/nogon/g' /usr/bin/update
      msg_ok "Migrated Hister to Nogon"
    fi

    msg_info "Starting Service"
    systemctl start nogon
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
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:4433${CL}"
