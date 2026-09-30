#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 tteck
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/matze/wastebin

APP="Wastebin"
var_tags="${var_tags:-file;code}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-4}"
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
  if [[ ! -d /opt/wastebin ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  ensure_dependencies zstd
  if [[ -f /opt/${APP}_version.txt ]]; then
    mv /opt/"${APP}_version.txt" ~/.wastebin
  fi
  msg_info "Running Migration"
  if [[ ! -f /opt/wastebin-data/.env ]]; then
    mkdir -p /opt/wastebin-data
    cat <<EOF >/opt/wastebin-data/.env
WASTEBIN_DATABASE_PATH=/opt/wastebin-data/wastebin.db
WASTEBIN_CACHE_SIZE=1024
WASTEBIN_HTTP_TIMEOUT=30
WASTEBIN_SIGNING_KEY=$(openssl rand -hex 32)
WASTEBIN_PASTE_EXPIRATIONS=0,600,3600=d,86400,604800,2419200,29030400
EOF
    systemctl stop wastebin
    cat <<EOF >/etc/systemd/system/wastebin.service
[Unit]
Description=Wastebin Service
After=network.target

[Service]
WorkingDirectory=/opt/wastebin
ExecStart=/opt/wastebin/wastebin
EnvironmentFile=/opt/wastebin-data/.env

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
  fi
  msg_ok "Migration Done"
  if check_for_gh_release "wastebin" "matze/wastebin"; then
    msg_info "Stopping Wastebin"
    systemctl stop wastebin
    msg_ok "Wastebin Stopped"

    fetch_and_deploy_gh_release "wastebin" "matze/wastebin" "prebuild" "latest" "/opt/wastebin" "wastebin_*_$(arch_resolve "x86_64" "aarch64")-unknown-linux-musl.tar.zst"
    chmod +x /opt/wastebin/wastebin /opt/wastebin/wastebin-ctl

    msg_info "Starting Wastebin"
    systemctl start wastebin
    msg_ok "Started Wastebin"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:8088${CL}"
