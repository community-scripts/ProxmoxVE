#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/dreeveapp/dreeve

APP="Dreeve"
var_tags="${var_tags:-fitness;dashboard}"
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

  if [[ ! -d /opt/dreeve ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "dreeve" "dreeveapp/dreeve"; then
    msg_info "Stopping Service"
    systemctl stop dreeve
    msg_ok "Stopped Service"

    create_backup /opt/dreeve/.env.local /opt/dreeve/Caddyfile

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "dreeve" "dreeveapp/dreeve" "tarball"

    restore_backup

    msg_info "Installing PHP Dependencies (Patience)"
    cd /opt/dreeve
    export COMPOSER_ALLOW_SUPERUSER=1
    export APP_ENV=prod
    $STD /opt/frankenphp/frankenphp php-cli /usr/local/bin/composer install --no-dev --optimize-autoloader --no-interaction --no-scripts
    msg_ok "Installed PHP Dependencies"

    msg_info "Running Migrations"
    mkdir -p /opt/dreeve/var/{cache,log}
    set -a
    source /opt/dreeve/.env.local
    set +a
    $STD /opt/frankenphp/frankenphp php-cli bin/console app:db:migrate --no-interaction
    $STD /opt/frankenphp/frankenphp php-cli bin/console assets:install public --no-interaction
    rm -rf /opt/dreeve/var/cache/prod
    $STD /opt/frankenphp/frankenphp php-cli bin/console cache:warmup --env=prod
    msg_ok "Ran Migrations"

    msg_info "Starting Service"
    systemctl start dreeve
    msg_ok "Started Service"
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
echo -e "${GATEWAY}${BGN}http://${IP}:8080${CL}"
echo -e "${INFO}${YW}Admin credentials: ~/dreeve.creds (inside the container)${CL}"
echo -e "${INFO}${YW}Add your Strava API credentials to /opt/dreeve/.env.local first${CL}"
