#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/icereed/paperless-gpt

APP="Paperless-GPT"
var_tags="${var_tags:-os}"
var_cpu="${var_cpu:-3}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-7}"
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
  if [[ ! -d /opt/paperless-gpt ]]; then
    msg_error "No Paperless-GPT installation found!"
    exit
  fi

  if check_for_gh_release "paperless-gpt" "icereed/paperless-gpt"; then
    msg_info "Stopping Service"
    systemctl stop paperless-gpt
    msg_ok "Service Stopped"

    if should_update_tool "node" "24"; then
      NODE_VERSION="24" setup_nodejs
    fi

    fetch_and_deploy_gh_release "paperless-gpt" "icereed/paperless-gpt" "tarball"
    GO_VERSION="$(grep -m1 '^go ' /opt/paperless-gpt/go.mod | awk '{print $2}')" setup_go

    msg_info "Updating Paperless-GPT"
    cd /opt/paperless-gpt/web-app
    $STD npm install
    $STD npm run build
    cd /opt/paperless-gpt
    go mod download
    export CC=musl-gcc
    CGO_ENABLED=1 go build -tags musl -o /dev/null github.com/mattn/go-sqlite3
    CGO_ENABLED=1 go build -tags musl -o paperless-gpt .
    msg_ok "Updated Paperless-GPT"

    msg_info "Starting Service"
    systemctl start paperless-gpt
    msg_ok "Started Service"
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
echo -e "${GATEWAY}${BGN}http://${IP}:8080${CL}"
