#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/jez500/pricebuddy

APP="PriceBuddy"
var_tags="${var_tags:-shopping;price-tracker}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-3072}"
var_disk="${var_disk:-10}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-no}" # the bundled scraper runs Google Chrome, which is amd64-only
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/pricebuddy ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "pricebuddy" "jez500/pricebuddy"; then
    msg_info "Stopping PriceBuddy Worker"
    systemctl stop pricebuddy-worker
    msg_ok "Stopped PriceBuddy Worker"

    setup_composer
    NODE_VERSION="22" setup_nodejs

    create_backup /opt/pricebuddy/.env /opt/pricebuddy/storage

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "pricebuddy" "jez500/pricebuddy" "tarball"

    restore_backup

    msg_info "Updating PriceBuddy"
    cd /opt/pricebuddy
    sed -i "s/^APP_VERSION=.*/APP_VERSION=$(cat ~/.pricebuddy)/" .env
    $STD composer install --no-dev --optimize-autoloader --no-interaction
    $STD npm install
    $STD npm run build
    $STD php artisan storage:link
    $STD php artisan migrate --force
    $STD php artisan optimize
    $STD php artisan icons:cache
    $STD php artisan buddy:regenerate-price-cache
    chown -R www-data:www-data /opt/pricebuddy
    msg_ok "Updated PriceBuddy"

    msg_info "Starting PriceBuddy Worker"
    systemctl start pricebuddy-worker
    msg_ok "Started PriceBuddy Worker"
    msg_ok "Updated successfully!"
  fi

  if check_for_gh_release "seleniumbase-scrapper" "jez500/seleniumbase-scrapper"; then
    msg_info "Stopping SeleniumBase Scrapper"
    systemctl stop seleniumbase-scrapper
    msg_ok "Stopped SeleniumBase Scrapper"

    msg_info "Updating Google Chrome"
    apt_update_safe
    upgrade_packages_with_retry google-chrome-stable
    msg_ok "Updated Google Chrome"

    PYTHON_VERSION="3.12" setup_uv

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "seleniumbase-scrapper" "jez500/seleniumbase-scrapper" "tarball"

    msg_info "Updating SeleniumBase Scrapper"
    $STD uv venv --python 3.12 /opt/seleniumbase-scrapper/.venv
    $STD uv pip install --python /opt/seleniumbase-scrapper/.venv/bin/python \
      "seleniumbase==$(sed -n 's/^ARG SELENIUMBASE_VERSION=v//p' /opt/seleniumbase-scrapper/Dockerfile)" \
      flask \
      beautifulsoup4
    $STD /opt/seleniumbase-scrapper/.venv/bin/seleniumbase get chromedriver
    msg_ok "Updated SeleniumBase Scrapper"

    msg_info "Starting SeleniumBase Scrapper"
    systemctl start seleniumbase-scrapper
    msg_ok "Started SeleniumBase Scrapper"
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
echo -e "${INFO}${YW}Log in as admin@example.com - the password is APP_USER_PASSWORD in /opt/pricebuddy/.env${CL}"
