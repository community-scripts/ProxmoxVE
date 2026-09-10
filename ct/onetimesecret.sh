#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Hai Tran (epiHATR)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://onetimesecret.com/ | Github: https://github.com/onetimesecret/onetimesecret

APP="OneTimeSecret"
var_tags="${var_tags:-security;privacy;secrets}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-10}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-no}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  SSL_VALUE="${OTS_SSL:-}"
  if [[ -n "${SSL_VALUE}" ]]; then
    case "${SSL_VALUE,,}" in
    1 | true | yes | on) SSL_VALUE="true" ;;
    0 | false | no | off) SSL_VALUE="false" ;;
    *)
      msg_error "Invalid OTS_SSL value '${OTS_SSL}' (use true/false)"
      exit 1
      ;;
    esac
  fi

  if [[ ! -d /opt/onetimesecret ]] || [[ ! -f /opt/onetimesecret/.env ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "onetimesecret" "onetimesecret/onetimesecret"; then
    msg_info "Stopping Service"
    systemctl stop onetimesecret
    msg_ok "Stopped Service"

    create_backup /opt/onetimesecret/.env

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "onetimesecret" "onetimesecret/onetimesecret" "tarball"
    RUBY_VERSION=$(tr -d ' \n' </opt/onetimesecret/.ruby-version 2>/dev/null)
    RUBY_VERSION="${RUBY_VERSION:-3.4.10}" setup_ruby

    PNPM_VERSION=$(sed -n 's/.*"packageManager": "pnpm@\([^"]*\)".*/\1/p' /opt/onetimesecret/package.json)
    NODE_VERSION=$(tr -d ' \n' </opt/onetimesecret/.nvmrc 2>/dev/null)
    NODE_VERSION="${NODE_VERSION:-25}" NODE_MODULE="pnpm@${PNPM_VERSION:-11.1.2}" setup_nodejs

    restore_backup

    msg_info "Reconciling Application"
    systemctl enable -q --now redis-server
    cd /opt/onetimesecret
    mkdir -p tmp/pids log
    $STD bash bin/setup reconcile
    msg_ok "Reconciled Application"

    msg_info "Building Frontend"
    cd /opt/onetimesecret
    $STD pnpm run build
    msg_ok "Built Frontend"

    msg_info "Starting Service"
    systemctl start onetimesecret
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

DISPLAY_HOST="${OTS_HOST:-$IP}"
case "${OTS_SSL:-false,,}" in
1 | true | yes | on)
  DISPLAY_SCHEME="https"
  ;;
*)
  DISPLAY_SCHEME="http"
  ;;
esac

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}${DISPLAY_SCHEME}://${DISPLAY_HOST}${CL}"
