#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
# Engine comes from community-scripts/core; this repo only ships the scripts.
# A local core checkout wins (COMMUNITY_SCRIPTS_CORE_DIR, else a sibling ../core),
# so a fork or branch of core can be tested without editing this file.
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.chatwoot.com/

APP="Chatwoot"
var_tags="${var_tags:-support;chat;helpdesk;crm}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-6144}"
var_disk="${var_disk:-16}"
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

  if [[ ! -f /opt/chatwoot/.env ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "chatwoot" "chatwoot/chatwoot"; then
    msg_info "Stopping Services"
    systemctl stop chatwoot-web chatwoot-worker
    msg_ok "Stopped Services"

    create_backup /opt/chatwoot/.env /opt/chatwoot/storage

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "chatwoot" "chatwoot/chatwoot" "tarball"

    RUBY_VERSION=$(tr -d ' \n' </opt/chatwoot/.ruby-version)
    RUBY_VERSION="${RUBY_VERSION}" RUBY_INSTALL_RAILS="false" setup_ruby
    NODE_VERSION=$(tr -d ' \n' </opt/chatwoot/.nvmrc)
    NODE_VERSION="${NODE_VERSION}" NODE_MODULE="pnpm" setup_nodejs
    export PATH="$HOME/.rbenv/shims:$HOME/.rbenv/bin:$PATH"

    restore_backup

    msg_info "Updating Application"
    cd /opt/chatwoot
    $STD bundle config set --local without 'development test'
    $STD bundle config set --local deployment 'true'
    $STD bundle install
    $STD pnpm install --frozen-lockfile
    RAILS_ENV=production $STD bundle exec rails db:chatwoot_prepare
    RAILS_ENV=production $STD bundle exec rails assets:precompile
    msg_ok "Updated Application"

    msg_info "Starting Services"
    systemctl start chatwoot-web chatwoot-worker
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
echo -e "${GATEWAY}${BGN}http://${IP}:3000${CL}"
