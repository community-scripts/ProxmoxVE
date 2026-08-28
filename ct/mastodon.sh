#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/mastodon/mastodon

APP="Mastodon"
var_tags="${var_tags:-social;fediverse;activitypub}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-20}"
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

  if [[ ! -d /opt/mastodon ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "mastodon" "mastodon/mastodon"; then
    msg_info "Stopping Services"
    systemctl stop mastodon-web mastodon-sidekiq mastodon-streaming
    msg_ok "Stopped Services"

    create_backup /opt/mastodon/public/system /opt/mastodon/.env.production

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "mastodon" "mastodon/mastodon" "tarball"
    sed -i "s/config.force_ssl = true/config.force_ssl = ENV.fetch('LOCAL_HTTPS', 'false') == 'true'/" /opt/mastodon/config/environments/production.rb
    sed -i "s/https = Rails.env.production? || ENV\['LOCAL_HTTPS'\] == 'true'/https = ENV.fetch('LOCAL_HTTPS', 'false') == 'true'/" /opt/mastodon/config/initializers/1_hosts.rb
    RUBY_VERSION="$(cat /opt/mastodon/.ruby-version)" RUBY_INSTALL_RAILS="false" setup_ruby

    msg_info "Installing Ruby Dependencies"
    cd /opt/mastodon
    export PATH="$HOME/.rbenv/shims:$HOME/.rbenv/bin:$PATH"
    $STD bundle config set --local without 'development test'
    $STD bundle config set --local deployment 'true'
    $STD bundle install -j"$(nproc)"
    msg_ok "Installed Ruby Dependencies"

    msg_info "Installing Node.js Dependencies"
    $STD yarn install
    msg_ok "Installed Node.js Dependencies"

    restore_backup

    msg_info "Running Database Migrations"
    RAILS_ENV=production $STD bundle exec rails db:migrate
    msg_ok "Ran Database Migrations"

    msg_info "Precompiling Assets"
    RAILS_ENV=production SECRET_KEY_BASE_DUMMY=1 $STD bundle exec rails assets:precompile
    msg_ok "Precompiled Assets"

    msg_info "Starting Services"
    systemctl start mastodon-web mastodon-sidekiq mastodon-streaming
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
