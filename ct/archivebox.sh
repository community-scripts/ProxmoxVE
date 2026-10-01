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

  setup_uv

  msg_info "Stopping Service"
  systemctl stop archivebox
  msg_ok "Stopped Service"

  local migrate=0 py port base runtime
  if [[ ! -x /opt/archivebox/venv/bin/archivebox ]]; then
    migrate=1
    msg_info "Moving ArchiveBox to its own Python 3.13 environment"
    py="/usr/bin/python3.13"
    [[ -x "$py" ]] || ensure_dependencies python3.13 || true
    if [[ ! -x "$py" ]]; then
      $STD uv python install --install-dir /opt/archivebox/python 3.13
      py="$(UV_PYTHON_INSTALL_DIR=/opt/archivebox/python uv python find 3.13)"
    fi
    $STD uv venv --python "$py" /opt/archivebox/venv
    msg_ok "Moved ArchiveBox to its own Python 3.13 environment"
  fi

  port="$(awk -F: '/^ExecStart=/ {print $NF}' /etc/systemd/system/archivebox.service 2>/dev/null)"
  [[ "$port" =~ ^[0-9]+$ ]] || port=5797
  cat <<EOF >/etc/systemd/system/archivebox.service
[Unit]
Description=ArchiveBox Server
After=network.target

[Service]
User=archivebox
WorkingDirectory=/opt/archivebox/data
ExecStartPre=/opt/archivebox/venv/bin/archivebox init
ExecStart=/opt/archivebox/venv/bin/archivebox server 0.0.0.0:${port}
Restart=always

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload

  msg_info "Updating ArchiveBox"
  $STD uv pip install --python /opt/archivebox/venv/bin/python --upgrade archivebox
  ln -sf /opt/archivebox/venv/bin/archivebox /usr/local/bin/archivebox
  mkdir -p /home/archivebox/.config
  chown -R archivebox:archivebox /opt/archivebox /home/archivebox
  cd /opt/archivebox/data
  $STD sudo -u archivebox /opt/archivebox/venv/bin/archivebox init
  base="$(grep -oP '^BASE_URL\s*=\s*\K\S+' ArchiveBox.conf 2>/dev/null || true)"
  if [[ -z "$base" || "$base" =~ ^https?://[0-9.]+(:[0-9]+)?/?$ ]]; then
    base="http://$(hostname -I | awk '{print $1}'):${port}"
  fi
  $STD sudo -u archivebox /opt/archivebox/venv/bin/archivebox config --set "BASE_URL=${base}" MERCURY_ENABLED=False
  msg_ok "Updated ArchiveBox"

  msg_info "Installing Extractors (Patience)"
  runtime="/tmp/archivebox-runtime-$(id -u archivebox)"
  install -d -m 700 -o archivebox -g archivebox "$runtime"
  if $STD env HOME=/home/archivebox USER=archivebox LOGNAME=archivebox XDG_CONFIG_HOME=/home/archivebox/.config XDG_RUNTIME_DIR="$runtime" \
    /opt/archivebox/venv/bin/archivebox install; then
    msg_ok "Installed Extractors"
  else
    msg_warn "Some extractors failed to install - crawls stop until the next update succeeds"
  fi

  if [[ "$migrate" == 1 ]]; then
    msg_info "Migrating Existing Snapshots (Patience)"
    $STD sudo -u archivebox /opt/archivebox/venv/bin/archivebox update --rescan --migrate-only --index-only
    msg_ok "Migrated Existing Snapshots"
  fi

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
echo -e "${GATEWAY}${BGN}http://${IP}:5797/admin/${CL}"
