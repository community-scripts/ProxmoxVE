#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/mozilla-services/syncstorage-rs

APP="Firefox-Syncserver"
var_tags="${var_tags:-sync;firefox}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-3072}"
var_disk="${var_disk:-10}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
#var_arm64="${var_arm64:-yes}" # built from source, nothing x86-only, but not yet run on arm64
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -f /usr/local/bin/syncserver ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "firefox-syncserver" "mozilla-services/syncstorage-rs"; then
    msg_info "Stopping Firefox Syncserver"
    systemctl stop firefox-syncserver
    msg_ok "Stopped Firefox Syncserver"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "firefox-syncserver" "mozilla-services/syncstorage-rs" "tarball"
    setup_rust

    msg_info "Building Firefox Syncserver (Patience)"
    cd /opt/firefox-syncserver
    $STD cargo build --release --locked --no-default-features --features=syncstorage-db/postgres --features=tokenserver-db/postgres --features=py_verifier
    cp target/release/syncserver /usr/local/bin/syncserver
    rm -rf target
    $STD uv venv --python /usr/bin/python3 /opt/firefox-syncserver/.venv
    $STD uv pip install --python /opt/firefox-syncserver/.venv/bin/python pyfxa tokenlib cryptography
    msg_ok "Built Firefox Syncserver"

    msg_info "Starting Firefox Syncserver"
    systemctl start firefox-syncserver
    msg_ok "Started Firefox Syncserver"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}In Firefox, set identity.sync.tokenserver.uri in about:config to:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:8000/1.0/sync/1.5${CL}"
