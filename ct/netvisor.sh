#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/scanopy/scanopy

APP="Scanopy"
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

  msg_info "Stopping services"
  systemctl -q disable --now netvisor-daemon netvisor-server
  msg_ok "Stopped services"

  NODE_VERSION="24" setup_nodejs
  CLEAN_INSTALL=1 fetch_and_deploy_gh_release "scanopy" "scanopy/scanopy" "tarball" "latest" "/opt/scanopy"

  ensure_dependencies pkg-config libssl-dev
  TOOLCHAIN="$(grep "channel" /opt/scanopy/backend/rust-toolchain.toml | awk -F\" '{print $2}')"
  RUST_TOOLCHAIN=$TOOLCHAIN setup_rust

  mv /opt/netvisor/.env /opt/scanopy/.env
  if [[ -f /opt/netvisor/oidc.toml ]]; then
    mv /opt/netvisor/oidc.toml /opt/scanopy/oidc.toml
  fi
  if ! grep -q "PUBLIC_URL" /opt/scanopy/.env; then
    sed -i "\|_PATH=|a\NETVISOR_PUBLIC_URL=http://${LOCAL_IP}:60072" /opt/scanopy/.env
  fi
  sed -i 's|_TARGET=.*$|_URL=http://127.0.0.1:60072|' /opt/scanopy/.env
  sed -i 's/NETVISOR/SCANOPY/g; s|netvisor/|scanopy/|' /opt/scanopy/.env

  msg_info "Creating frontend UI"
  export PUBLIC_SERVER_HOSTNAME=default
  export PUBLIC_SERVER_PORT=""
  cd /opt/scanopy/ui
  $STD npm ci --no-fund --no-audit
  $STD npm run build
  msg_ok "Created frontend UI"

  msg_info "Building Scanopy-server (patience)"
  cd /opt/scanopy/backend
  $STD cargo build --release --bin server
  mv ./target/release/server /usr/bin/scanopy-server
  msg_ok "Built Scanopy-server"

  msg_info "Building Scanopy-daemon"
  $STD cargo build --release --bin daemon
  cp ./target/release/daemon /usr/bin/scanopy-daemon
  msg_ok "Built Scanopy-daemon"

  sed -i '/^  \"server_target.*$/d' /root/.config/daemon/config.json
  sed -i -e 's|-target|-url|' \
    -e 's| --server-port |:|' \
    -e 's/NetVisor/Scanopy/' \
    -e 's/netvisor/scanopy/' \
    /etc/systemd/system/netvisor-daemon.service
  mv /etc/systemd/system/netvisor-daemon.service /etc/systemd/system/scanopy-daemon.service
  sed -i -e 's/NetVisor/Scanopy/' \
    -e 's/netvisor/scanopy/g' \
    /etc/systemd/system/netvisor-server.service
  mv /etc/systemd/system/netvisor-server.service /etc/systemd/system/scanopy-server.service
  systemctl daemon-reload

  msg_info "Starting services"
  systemctl -q enable --now scanopy-server scanopy-daemon
  msg_ok "Updated successfully!"

  sed -i 's/netvisor/scanopy/' /usr/bin/update
  mv ~/NetVisor.creds ~/scanopy.creds
  rm ~/.netvisor
  rm -rf /opt/netvisor

  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:60072${CL}"
echo -e "${INFO}${YW} Then create your account, and run the 'configure_daemon.sh' script to setup the daemon.${CL}"
