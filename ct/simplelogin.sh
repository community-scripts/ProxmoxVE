#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/simple-login/app

APP="SimpleLogin"
var_tags="${var_tags:-email;privacy;alias}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-10}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
#var_arm64="${var_arm64:-no}" # unset = ask the user; set yes/no only when verified
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/simplelogin ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "simplelogin" "simple-login/app"; then
    msg_info "Stopping Services"
    systemctl stop simplelogin-webapp simplelogin-email simplelogin-job
    msg_ok "Stopped Services"

    create_backup /opt/simplelogin/.env \
      /opt/simplelogin/dkim \
      /opt/simplelogin/openid-rsa.key \
      /opt/simplelogin/openid-rsa.pub \
      /opt/simplelogin/uploads \
      /opt/simplelogin/.gnupg

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "simplelogin" "simple-login/app"

    restore_backup
    grep -q '^METRICS_BACKENDS=' /opt/simplelogin/.env || echo "METRICS_BACKENDS=noop" >>/opt/simplelogin/.env

    msg_info "Installing Dependencies"
    cd /opt/simplelogin
    $STD uv venv
    $STD uv pip install setuptools hatchling editables
    export CMAKE_POLICY_VERSION_MINIMUM=3.5
    $STD uv sync --locked --no-dev --no-build-isolation --no-install-package newrelic
    if [[ -f /opt/simplelogin/static/package.json ]]; then
      cd /opt/simplelogin/static
      $STD npm ci
    fi
    msg_ok "Installed Dependencies"

    msg_info "Running Database Migrations"
    cd /opt/simplelogin
    $STD .venv/bin/alembic upgrade head
    msg_ok "Ran Database Migrations"

    msg_info "Starting Services"
    systemctl start simplelogin-webapp simplelogin-email simplelogin-job
    msg_ok "Started Services"
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
echo -e "${GATEWAY}${BGN}http://${IP}${CL}"
