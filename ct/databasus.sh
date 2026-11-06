#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/databasus/databasus

APP="Databasus"
var_tags="${var_tags:-backup;postgresql;database}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
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

  if [[ ! -f /opt/databasus/databasus ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  NODE_VERSION="24" NODE_MODULE="corepack" setup_nodejs

  if check_for_gh_release "databasus" "databasus/databasus"; then
    msg_info "Stopping Databasus"
    $STD systemctl stop databasus
    msg_ok "Stopped Databasus"

    ensure_dependencies libedit2 libgssapi-krb5-2 libncurses6 libreadline8t64
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "databasus" "databasus/databasus" "tarball" "latest" "/opt/databasus"
    GO_VERSION="$(grep -m1 '^go ' /opt/databasus/backend/go.mod | awk '{print $2}')" setup_go

    msg_info "Updating Databasus"
    RELEASE=$(cat ~/.databasus)
    export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
    cd /opt/databasus/frontend
    $STD corepack prepare pnpm@latest --activate
    $STD pnpm install --frozen-lockfile
    $STD env VITE_APP_VERSION="${RELEASE}" pnpm run build
    cd /opt/databasus/backend
    $STD env CGO_ENABLED=0 GOOS=linux GOARCH="$(arch_resolve)" go build -o /opt/databasus/databasus ./cmd/databasus
    mkdir -p /opt/databasus/agent-binaries
    for arch in amd64 arm64; do
      $STD env CGO_ENABLED=0 GOOS=linux GOARCH=$arch go build -ldflags "-X main.Version=${RELEASE}" -o /opt/databasus/agent-binaries/databasus-verification-agent-linux-$arch ./cmd/verification-agent
    done
    mkdir -p /opt/databasus/ui/build
    cp -r /opt/databasus/frontend/dist/* /opt/databasus/ui/build/
    sed -i '/^APP_VERSION=/d' /.env
    echo "APP_VERSION=${RELEASE}" >>/.env
    msg_ok "Updated Databasus"

    chown -R postgres:postgres /opt/databasus

    if ! grep -q "EnvironmentFile=/.env" /etc/systemd/system/databasus.service; then
      msg_info "Updating Service"
      sed -i 's|EnvironmentFile=.*|EnvironmentFile=/.env|' /etc/systemd/system/databasus.service
      $STD systemctl daemon-reload
      msg_ok "Updated Service"
    fi

    msg_info "Starting Databasus"
    $STD systemctl start databasus
    msg_ok "Started Databasus"
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
echo -e "${GATEWAY}${BGN}http://${IP}${CL}"
