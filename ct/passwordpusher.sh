#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/pglombardo/PasswordPusher

APP="PasswordPusher"
var_tags="${var_tags:-security;sharing;password}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-4}"
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

  if [[ ! -d /opt/passwordpusher ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "passwordpusher" "pglombardo/PasswordPusher"; then
    msg_info "Stopping Service"
    systemctl stop passwordpusher
    msg_ok "Stopped Service"

    create_backup /opt/passwordpusher/storage /opt/passwordpusher/.env.production

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "passwordpusher" "pglombardo/PasswordPusher" "tarball"
    RUBY_VERSION="$(cat /opt/passwordpusher/.ruby-version)" RUBY_INSTALL_RAILS="false" setup_ruby

    msg_info "Installing Gem Dependencies"
    cd /opt/passwordpusher
    export PATH="$HOME/.rbenv/shims:$HOME/.rbenv/bin:$PATH"
    $STD bundle config set --local without 'development test'
    $STD bundle config set --local deployment 'true'
    $STD bundle install
    msg_ok "Installed Gem Dependencies"

    msg_info "Installing JS Dependencies"
    $STD yarn install --frozen-lockfile
    msg_ok "Installed JS Dependencies"

    msg_info "Running Database Migrations"
    RAILS_ENV=production $STD bundle exec rails db:migrate
    msg_ok "Ran Database Migrations"

    msg_info "Precompiling Assets"
    RAILS_ENV=production SECRET_KEY_BASE_DUMMY=1 $STD bundle exec rails assets:precompile
    msg_ok "Precompiled Assets"

    restore_backup

    msg_info "Starting Service"
    systemctl start passwordpusher
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
echo -e "${GATEWAY}${BGN}http://${IP}:5100${CL}"
