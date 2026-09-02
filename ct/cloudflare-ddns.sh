#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: edoardop13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/favonia/cloudflare-ddns

APP="Cloudflare-DDNS"
var_tags="${var_tags:-network}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-3}"
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

  if [[ ! -f /usr/local/bin/ddns ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "cloudflare-ddns" "favonia/cloudflare-ddns"; then
    msg_info "Stopping Service"
    systemctl stop cloudflare-ddns
    msg_ok "Stopped Service"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "cloudflare-ddns" "favonia/cloudflare-ddns" "tarball"
    GO_VERSION="$(grep -m1 '^go ' /opt/cloudflare-ddns/go.mod | awk '{print $2}')" setup_go

    msg_info "Updating ${APP}"
    cd /opt/cloudflare-ddns
    export CGO_ENABLED=0 GOOS=linux
    $STD go build -trimpath -ldflags="-s -w" -o /usr/local/bin/ddns ./cmd/ddns
    msg_ok "Updated ${APP}"

    msg_info "Removing Build Dependencies"
    rm -rf /usr/local/go /usr/local/bin/go /usr/local/bin/gofmt /root/go /root/.cache/go-build /opt/cloudflare-ddns
    msg_ok "Removed Build Dependencies"

    msg_info "Starting Service"
    systemctl start cloudflare-ddns
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description
msg_ok "Completed successfully!\n"
