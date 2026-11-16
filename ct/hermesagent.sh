#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Stephen Chin (steveonjava)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://hermes-agent.nousresearch.com/

APP="Hermes Agent"
var_tags="${var_tags:-ai;automation;agent}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
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

  if [[ ! -x /home/hermes/.local/bin/hermes ]]; then
    msg_error "No Hermes Agent Installation Found!"
    exit
  fi

  confirm_external_installer "https://hermes-agent.nousresearch.com/" "hermes update (https://hermes-agent.nousresearch.com/)"

  if [[ -f /etc/systemd/system/hermes-dashboard.service ]]; then
    msg_info "Moving Hermes to its own user"
    systemctl disable -q --now hermes-dashboard
    rm -f /etc/systemd/system/hermes-dashboard.service
    systemctl daemon-reload
    mapfile -t root_hermes_pids < <(ps -eo user=,pid=,args= | awk '$1 == "root" && /\/home\/hermes\/\.hermes\// && /hermes_cli[.]main/ { print $2 }')
    if ((${#root_hermes_pids[@]})); then
      kill -TERM "${root_hermes_pids[@]}" 2>/dev/null || true
      for pid in "${root_hermes_pids[@]}"; do
        while kill -0 "$pid" 2>/dev/null; do
          sleep 0.1
        done
      done
    fi
    ensure_dependencies libatomic1
    sed -i '/^HOME=/d' /etc/default/hermes
    grep -q '^GATEWAY_HEALTH_URL=' /etc/default/hermes || echo "GATEWAY_HEALTH_URL=http://127.0.0.1:8642/health" >>/etc/default/hermes
    mkdir -p /home/hermes/.config/systemd/user
    cat <<EOF >/home/hermes/.config/systemd/user/hermes-dashboard.service
[Unit]
Description=Hermes Agent Web Dashboard
After=network-online.target

[Service]
Type=simple
UMask=0077
WorkingDirectory=%h
EnvironmentFile=/etc/default/hermes
ExecStart=%h/.local/bin/hermes dashboard --host 127.0.0.1 --port 9119 --no-open
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF
    msg_ok "Moved Hermes to its own user"
  fi

  # A writer racing chown makes files vanish between readdir and chown; one retry covers it.
  if ! chown -R hermes:hermes /home/hermes 2>/dev/null; then
    sleep 1
    chown -R hermes:hermes /home/hermes || msg_warn "Could not take ownership of everything under /home/hermes"
  fi
  $STD runuser -l hermes -c 'systemctl --user daemon-reload && systemctl --user enable hermes-dashboard'

  msg_info "Updating Hermes Agent"
  $STD setsid --wait runuser -l hermes -c '
    set -a; source /etc/default/hermes; set +a
    hermes update --yes
  '
  msg_ok "Updated Hermes Agent"

  msg_info "Starting Services"
  $STD runuser -l hermes -c 'systemctl --user start hermes-dashboard'
  msg_ok "Started Services"
  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}Hermes Agent setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Configure your model provider and gateway server inside the container:${CL}"
echo -e "${TAB}${BGN}hermes-setup${CL}"
echo -e "${INFO} When prompted to install the gateway service, choose 'user service'.${CL}"
echo -e "${INFO}${YW} Key for Hermes API Server stored in:${CL}"
echo -e "${TAB}${BGN}/home/hermes/.hermes/.env${CL}"
