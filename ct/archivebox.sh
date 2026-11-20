#!/usr/bin/env bash
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
  if [[ ! -d /opt/archivebox ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "archivebox" "ArchiveBox/ArchiveBox"; then
    msg_info "Stopping ArchiveBox"
    systemctl stop archivebox
    msg_ok "Stopped ArchiveBox"

    export UV_PYTHON_INSTALL_DIR="/opt/archivebox/python"
    PYTHON_VERSION="3.13" setup_uv
    ensure_dependencies chromium

    if [[ ! -x /opt/archivebox/.venv/bin/archivebox ]]; then
      msg_info "Migrating ArchiveBox to 0.9"
      $STD uv pip uninstall --system --break-system-packages archivebox playwright
      rm -rf /home/archivebox/.cache/ms-playwright
      remove_old_tool_version "nodejs" "nodesource"
      sed -i -e '/^User=archivebox$/d' -e 's|^ExecStart=/usr/local/bin/archivebox |ExecStart=/opt/archivebox/.venv/bin/archivebox |' /etc/systemd/system/archivebox.service
      sed -i '/^ExecStart=/i ExecStartPre=-/bin/sh -c "echo 1G 2>/dev/null >/sys/fs/cgroup/memory.reclaim"' /etc/systemd/system/archivebox.service
      systemctl daemon-reload
      $STD uv venv --python 3.13 /opt/archivebox/.venv
      msg_ok "Migrated ArchiveBox to 0.9"
    fi

    msg_info "Updating ArchiveBox"
    $STD uv pip install --python /opt/archivebox/.venv/bin/python "archivebox==${CHECK_UPDATE_RELEASE#v}"
    ln -sf /opt/archivebox/.venv/bin/archivebox /usr/local/bin/archivebox
    cd /opt/archivebox/data
    $STD archivebox init
    if ! grep -q "^BASE_URL" ArchiveBox.conf; then
      $STD archivebox config --set "BASE_URL=http://${LOCAL_IP}:$(grep -oP 'server 0\.0\.0\.0:\K[0-9]+' /etc/systemd/system/archivebox.service)"
    fi
    echo 1G 2>/dev/null >/sys/fs/cgroup/memory.reclaim || true
    $STD archivebox install
    $STD archivebox update --migrate-only
    cat <<EOF >~/.archivebox
${CHECK_UPDATE_RELEASE#v}
EOF
    msg_ok "Updated ArchiveBox"

    msg_info "Starting ArchiveBox"
    systemctl start archivebox
    msg_ok "Started ArchiveBox"
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
echo -e "${GATEWAY}${BGN}http://${IP}:8000/admin/${CL}"
