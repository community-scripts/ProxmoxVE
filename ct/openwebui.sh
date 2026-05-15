#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: tteck | Co-Author: havardthom | Co-Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://openwebui.com/

APP="Open WebUI"
var_tags="${var_tags:-ai;interface}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-8192}"
var_disk="${var_disk:-50}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"
var_gpu="${var_gpu:-yes}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  ensure_dependencies zstd build-essential libmariadb-dev

  if [[ -d /opt/open-webui ]]; then
    msg_warn "Legacy installation detected — migrating to uv based install..."
    msg_info "Stopping Service"
    systemctl stop open-webui
    msg_ok "Stopped Service"

    msg_info "Creating Backup"
    mkdir -p /opt/open-webui-backup
    cp -a /opt/open-webui/backend/data /opt/open-webui-backup/data || true
    cp -a /opt/open-webui/.env /opt/open-webui-backup/.env || true
    msg_ok "Created Backup"

    msg_info "Removing legacy installation"
    rm -rf /opt/open-webui
    rm -rf /root/.open-webui || true
    msg_ok "Removed legacy installation"

    msg_info "Installing uv-based Open-WebUI"
    PYTHON_VERSION="3.12" setup_uv
    $STD uv tool install --python 3.12 --constraint <(echo "numba>=0.60") open-webui[all]
    msg_ok "Installed uv-based Open-WebUI"

    msg_info "Restoring data"
    mkdir -p /root/.open-webui
    cp -a /opt/open-webui-backup/data/* /root/.open-webui/ || true
    cp -a /opt/open-webui-backup/.env /root/.env || true
    rm -rf /opt/open-webui-backup || true
    msg_ok "Restored data"

    msg_info "Recreating Service"
    cat <<EOF >/etc/systemd/system/open-webui.service
[Unit]
Description=Open WebUI Service
After=network.target

[Service]
Type=simple
Environment=DATA_DIR=/root/.open-webui
EnvironmentFile=-/root/.env
ExecStart=/root/.local/bin/open-webui serve
WorkingDirectory=/root
Restart=on-failure
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
EOF

    $STD systemctl daemon-reload
    systemctl enable -q --now open-webui
    msg_ok "Recreated Service"

    msg_ok "Migration completed"
    exit 0
  fi

  if [[ ! -d /root/.open-webui ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if [ -x "/usr/bin/ollama" ]; then
    msg_info "Checking for Ollama Update"
    if check_for_gh_release "ollama" "ollama/ollama"; then
      msg_info "Stopping Ollama Service"
      systemctl stop ollama
      msg_ok "Stopped Service"

      rm -rf /usr/lib/ollama /usr/bin/ollama
      if ! fetch_and_deploy_gh_release "ollama" "ollama/ollama" "prebuild" "latest" "/usr/lib/ollama" "ollama-linux-amd64.tar.zst"; then
        msg_error "Ollama download or deployment failed – check network connectivity and GitHub API availability"
      else
        ln -sf /usr/lib/ollama/bin/ollama /usr/bin/ollama
        msg_ok "Updated Ollama to ${CHECK_UPDATE_RELEASE}"
      fi

      msg_info "Starting Ollama Service"
      systemctl start ollama
      msg_ok "Started Service"
    fi
  fi

  msg_info "Updating Open WebUI via uv"
  PYTHON_VERSION="3.12" setup_uv
  $STD uv tool install --force --python 3.12 --constraint <(echo "numba>=0.60") open-webui[all]
  systemctl restart open-webui
  msg_ok "Updated Open WebUI"
  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"
