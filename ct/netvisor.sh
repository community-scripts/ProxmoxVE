#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/maynayza/netvisor

APP="NetVisor"
var_tags="${var_tags:-analytics}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
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
    cp /opt/netvisor/.env /opt/netvisor.env
    msg_ok "Backed up configurations"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "netvisor" "mayanayza/netvisor" "tarball" "latest" "/opt/netvisor"

    TOOLCHAIN="$(grep "channel" /opt/netvisor/backend/rust-toolchain.toml | awk -F\" '{print $2}')"
    RUST_TOOLCHAIN=$TOOLCHAIN setup_rust

    mv /opt/netvisor.env /opt/netvisor/.env
    msg_info "Creating frontend UI"
    export PUBLIC_SERVER_HOSTNAME=default
    export PUBLIC_SERVER_PORT=60072
    cd /opt/netvisor/ui
    $STD npm ci --no-fund --no-audit
    $STD npm run build
    msg_ok "Created frontend UI"

    msg_info "Building Netvisor-server (patience)"
    cd /opt/netvisor/backend
    $STD cargo build --release --bin server
    mv ./target/release/server /usr/bin/netvisor-server
    msg_ok "Built Netvisor-server"

    msg_info "Building Netvisor-daemon (amd64 version)"
    $STD cargo build --release --bin daemon
    cp ./target/release/daemon /usr/bin/netvisor-daemon
    msg_ok "Built Netvisor-daemon (amd64 version)"

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
