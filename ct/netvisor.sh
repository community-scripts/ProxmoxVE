#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/maynayza/netvisor

APP="NetVisor"
var_tags="${var_tags:-analytics}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-3072}"
var_disk="${var_disk:-6}"
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

  if [[ ! -d /opt/netvisor ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "netvisor" "mayanayza/netvisor"; then
    msg_info "Stopping services"
    systemctl stop netvisor-daemon netvisor-server
    msg_ok "Stopped services"

    msg_info "Backing up configurations"
    cp /opt/netvisor/.env /opt/netvisor.env.bak
    msg_ok "Backed up configurations"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "netvisor" "mayanayza/netvisor" "tarball" "latest" "/opt/netvisor"

    if ! dpkg -l | grep -q "pkg-config"; then
      $STD apt install -y pkg-config
    fi
    if ! dpkg -l | grep -q "libssl-dev"; then
      $STD apt install -y libssl-dev
    fi
    TOOLCHAIN="$(grep "channel" /opt/netvisor/backend/rust-toolchain.toml | awk -F\" '{print $2}')"
    RUST_TOOLCHAIN=$TOOLCHAIN setup_rust

    cp /opt/netvisor.env.bak /opt/netvisor/.env
    LOCAL_IP="$(hostname -I | awk '{print $1}')"
    if ! grep -q "PUBLIC_URL"; then
      sed -i "\|_PATH=|a\NETVISOR_PUBLIC_URL=http://${LOCAL_IP}:60072" /opt/netvisor/.env
    fi
    sed -i 's|_TARGET=.*$|_URL=http://127.0.0.1:60072|' /opt/netvisor/.env

    msg_info "Creating frontend UI"
    export PUBLIC_SERVER_HOSTNAME=default
    export PUBLIC_SERVER_PORT=""
    cd /opt/netvisor/ui
    $STD npm ci --no-fund --no-audit
    $STD npm run build
    msg_ok "Created frontend UI"

    msg_info "Building Netvisor-server (patience)"
    cd /opt/netvisor/backend
    $STD cargo build --release --bin server
    mv ./target/release/server /usr/bin/netvisor-server
    msg_ok "Built Netvisor-server"

    msg_info "Building Netvisor-daemon"
    $STD cargo build --release --bin daemon
    cp ./target/release/daemon /usr/bin/netvisor-daemon
    msg_ok "Built Netvisor-daemon"

    sed -i -e 's|-target|-url|' \
      -e 's| --server-port |:|' \
      /etc/systemd/system/netvisor-daemon.service
    sed -i '/^  \"server_target.*$/d' /root/.config/daemon/config.json
    systemctl daemon-reload

    msg_info "Starting services"
    systemctl start netvisor-server netvisor-daemon
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:60072${CL}"
