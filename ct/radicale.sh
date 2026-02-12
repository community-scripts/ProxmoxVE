#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: tremor021
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://radicale.org/

APP="Radicale"
var_tags="${var_tags:-calendar}"
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
  if [[ ! -d /opt/radicale ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "Radicale" "Kozea/Radicale"; then
    msg_info "Stopping service"
    systemctl stop radicale
    msg_ok "Stopped service"

    msg_info "Backing up users file"
    cp /opt/radicale/users /opt/radicale_users_backup
    msg_ok "Backed up users file"

    PYTHON_VERSION="3.13" setup_uv
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "Radicale" "Kozea/Radicale" "tarball" "latest" "/opt/radicale"

    msg_info "Restoring users file"
    rm -f /opt/radicale/users
    mv /opt/radicale_users_backup /opt/radicale/users
    msg_ok "Restored users file"

    if grep -q 'start.sh' /etc/systemd/system/radicale.service; then
      sed -i -e '/^Description/i[Unit]' \
        -e '\|^ExecStart|iWorkingDirectory=/opt/radicale' \
        -e 's|^ExecStart=.*|ExecStart=/usr/local/bin/uv run -m radicale --config /etc/radicale/config|' /etc/systemd/system/radicale.service
      systemctl daemon-reload
    fi
    if [[ ! -f /etc/radicale/config ]]; then
      msg_info "Migrating to config file (/etc/radicale/config)"
      mkdir -p /etc/radicale
      cat <<EOF >/etc/radicale/config
[server]
hosts = 0.0.0.0:5232

[auth]
type = htpasswd
htpasswd_filename = /opt/radicale/users
htpasswd_encryption = sha512

[storage]
type = multifilesystem
filesystem_folder = /var/lib/radicale/collections

[web]
type = internal
EOF
      msg_ok "Migrated to config (/etc/radicale/config)"
    fi
    msg_info "Starting service"
    systemctl start radicale
    msg_ok "Started service"
    msg_ok "Updated Successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:5232${CL}"
