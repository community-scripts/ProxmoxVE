#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)

# Copyright (c) 2021-2026 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/DioCrafts/OxiCloud

APP="OxiCloud"
var_tags="${var_tags:-files;documents}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-6144}"
var_disk="${var_disk:-20}"
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

  if [[ ! -d /opt/oxicloud ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "OxiCloud" "DioCrafts/OxiCloud"; then
    msg_info "Stopping OxiCloud"
    systemctl stop oxicloud
    msg_ok "Stopped OxiCloud"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "OxiCloud" "DioCrafts/OxiCloud" "tarball" "latest" "/opt/oxicloud"
    TOOLCHAIN="$(grep -oP 'FROM\s+rust:\K[0-9]+\.[0-9]+(\.[0-9]+)?' /opt/oxicloud/Dockerfile | head -1)"
    RUST_TOOLCHAIN="${TOOLCHAIN:-stable}" setup_rust

    msg_info "Building Frontend SPA"
    cd /opt/oxicloud/frontend
    $STD npm ci
    $STD npm run build
    msg_ok "Built Frontend SPA"

    msg_info "Updating OxiCloud (Patience)"
    set -a
    source /etc/oxicloud/.env
    set +a
    cd /opt/oxicloud
    export DATABASE_URL
    export RUSTFLAGS="-C target-cpu=native"
    RAM_MB=$(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo)
    CARGO_JOBS=$((RAM_MB / 2560))
    [[ $CARGO_JOBS -lt 1 ]] && CARGO_JOBS=1
    [[ $CARGO_JOBS -gt $(nproc) ]] && CARGO_JOBS=$(nproc)
    $STD cargo build --release -j "$CARGO_JOBS" --bin oxicloud --bin migrate-nfc-filenames
    mv target/release/oxicloud /usr/local/bin/oxicloud
    mv target/release/migrate-nfc-filenames /usr/local/bin/migrate-nfc-filenames
    chmod +x /usr/local/bin/oxicloud /usr/local/bin/migrate-nfc-filenames
    rm -f /usr/bin/oxicloud
    rm -rf /opt/oxicloud/static
    mv /opt/oxicloud/static-dist /opt/oxicloud/static
    rm -rf /opt/oxicloud/target /opt/oxicloud/frontend/node_modules
    msg_ok "Updated OxiCloud"

    msg_info "Starting OxiCloud"
    systemctl start oxicloud
    msg_ok "Started OxiCloud"
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
echo -e "${GATEWAY}${BGN}http://${IP}:8086${CL}"
