#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: community-scripts
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/rommapp/romm

APP="ROMM"
var_tags="${var_tags:-gaming;media;roms}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-10}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

# Override the install script location for testing
var_install="romm"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/romm ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  msg_info "Stopping Service"
  systemctl stop romm
  msg_ok "Stopped Service"

  msg_info "Updating ${APP}"
  cd /opt/romm
  git pull origin main
  msg_ok "Updated Repository"

  msg_info "Updating Python Dependencies"
  /usr/local/bin/uv sync --all-extras
  msg_ok "Updated Python Dependencies"

  msg_info "Updating Frontend Dependencies"
  cd /opt/romm/frontend
  $STD npm install
  msg_ok "Updated Frontend Dependencies"

  msg_info "Starting Service"
  systemctl start romm
  msg_ok "Started Service"
  msg_ok "Updated successfully!"
  exit
}

start

# Custom build_container that uses your fork
build_container() {
  msg_info "Creating LXC container"
  DISK_REF="$var_disk"
  if [ "$var_disk" == "0" ]; then
    DISK_REF="$DISK_SIZE"
  fi

  CTID=$(pvesh get /cluster/nextid)
  TEMP_DIR=$(mktemp -d)
  pushd "$TEMP_DIR" >/dev/null

  export CTID
  export PCT_OSTYPE=debian
  export PCT_OSVERSION="$var_version"
  export PCT_DISK_SIZE="$DISK_REF"
  export PCT_OPTIONS="
    -features nesting=1
    -hostname $var_name
    -tags proxmox-helper-scripts
    -onboot 1
    -cores $var_cpu
    -memory $var_ram
    -net0 name=eth0,bridge=$BRG$MAC,ip=dhcp
  "
  bash -c "$(wget -qLO - https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/create_lxc.sh)" || exit

  msg_ok "LXC Container $CTID was successfully created."

  msg_info "Starting LXC Container"
  pct start "$CTID"
  msg_ok "Started LXC Container"

  lxc-attach -n "$CTID" -- bash -c "$(curl -fsSL https://raw.githubusercontent.com/onionrings29/ProxmoxVE/claude/dockerfile-ubuntu-setup-01Abox2T6edmGTHazHrG3QFw/install/romm-install.sh)"

  IP=$(pct exec "$CTID" ip a s dev eth0 | sed -n '/inet / s/\// /p' | awk '{print $2}')

  popd >/dev/null
  rm -rf "$TEMP_DIR"
}

build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"
