#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/sebadob/rauthy

APP="Rauthy"
var_tags="${var_tags:-auth;sso;oidc}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-6144}"
var_disk="${var_disk:-12}"
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

  if [[ ! -f /opt/rauthy/rauthy ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "rauthy" "sebadob/rauthy"; then
    setup_rust
    fetch_and_deploy_gh_release "rauthy" "sebadob/rauthy" "tarball" "latest" "/opt/rauthy-build"

    msg_info "Building Rauthy (Patience)"
    cd /opt/rauthy-build
    tar -xf assets/static_html/static_v1.tar.gz
    tar -xf assets/static_html/templates_html.tar.gz
    if ! CURL_RETRIES=8 curl_with_retry "https://mds.fidoalliance.org/" "/opt/rauthy-build/mds.jwt"; then
      rm -rf /opt/rauthy-build
      msg_error "The FIDO MDS download was rate-limited (HTTP 429); Rauthy was not changed, try the update again later"
      exit 7
    fi
    CARGO_PROFILE_DEV_DEBUG=0 $STD cargo run --bin fido-mds-prep -- --source mds.jwt
    CARGO_PROFILE_RELEASE_LTO=thin CARGO_PROFILE_RELEASE_CODEGEN_UNITS=16 \
      $STD cargo build --release --bin rauthy
    msg_ok "Built Rauthy"

    msg_info "Stopping Rauthy"
    systemctl stop rauthy
    mv /opt/rauthy-build/target/release/rauthy /opt/rauthy/rauthy
    cd /opt
    rm -rf /opt/rauthy-build ~/.cargo/registry
    msg_ok "Stopped Rauthy"

    msg_info "Starting Rauthy"
    systemctl start rauthy
    msg_ok "Started Rauthy"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}https://${IP}:8443/auth/v1/${CL}"
