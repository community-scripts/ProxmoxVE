#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 tteck
# Author: tteck
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://archivebox.io/ | Github: https://github.com/ArchiveBox/ArchiveBox

APP="ArchiveBox"
var_tags="${var_tags:-archive;bookmark}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
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
  if [[ ! -d /opt/archivebox ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  NODE_VERSION="22" NODE_MODULE="@postlight/parser@latest,single-file-cli@latest" setup_nodejs
  export UV_PYTHON_INSTALL_DIR="/opt/archivebox/python"
  PYTHON_VERSION="3.13" setup_uv

  ensure_dependencies chromium

  msg_info "Stopping Service"
  systemctl stop archivebox
  msg_ok "Stopped Service"

  # Earlier installs used the system interpreter, which caps ArchiveBox at 0.7.4.
  if [[ ! -x /opt/archivebox/venv/bin/archivebox ]]; then
    msg_info "Moving ArchiveBox to its own Python 3.13 environment"
    $STD uv venv --python 3.13 /opt/archivebox/venv
    # Keep whatever port this container already answers on, or a reverse proxy in front
    # of it would silently stop resolving.
    local port
    port="$(awk -F: '/^ExecStart=/ {print $NF}' /etc/systemd/system/archivebox.service 2>/dev/null)"
    [[ "$port" =~ ^[0-9]+$ ]] || port=5797
    cat <<EOF >/etc/systemd/system/archivebox.service
[Unit]
Description=ArchiveBox Server
After=network.target

[Service]
User=archivebox
WorkingDirectory=/opt/archivebox/data
ExecStart=/opt/archivebox/venv/bin/archivebox server 0.0.0.0:${port}
Restart=always

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    msg_ok "Moved ArchiveBox to its own Python 3.13 environment (port ${port})"
  fi

  msg_info "Updating ArchiveBox"
  $STD uv pip install --python /opt/archivebox/venv/bin/python --upgrade archivebox playwright
  $STD /opt/archivebox/venv/bin/playwright install-deps chromium
  chown -R archivebox:archivebox /opt/archivebox/python /opt/archivebox/venv
  # Without this a shell still reaches the old 0.7.4 entry point against a 0.9 collection.
  ln -sf /opt/archivebox/venv/bin/archivebox /usr/local/bin/archivebox
  cd /opt/archivebox/data
  $STD sudo -u archivebox /opt/archivebox/venv/bin/archivebox init
  msg_ok "Updated ArchiveBox"

  msg_info "Starting Service"
  systemctl start archivebox
  msg_ok "Started Service"
  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:5797/admin/login${CL}"
