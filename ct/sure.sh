#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://sure.am

APP="Sure"
var_tags="${var_tags:-finance}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-6}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/sure ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "Sure" "we-promise/sure"; then
    msg_info "Stopping Service"
    $STD systemctl stop sure
    msg_ok "Stopped Service"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "Sure" "we-promise/sure" "tarball" "latest" "/opt/sure"
    RUBY_VERSION="$(cat /opt/sure/.ruby-version)" RUBY_INSTALL_RAILS=false setup_ruby

    msg_info "Updating Sure"
    source ~/.profile
    cd /opt/sure
    export RAILS_ENV=production
    export BUNDLE_DEPLOYMENT=1
    export BUNDLE_WITHOUT=development
    $STD ./bin/bundle install
    $STD ./bin/bundle exec bootsnap precompile --gemfile -j 0
    $STD ./bin/bundle exec bootsnap precompile -j 0 app/ lib/
    export SECRET_KEY_BASE_DUMMY=1 && $STD ./bin/rails assets:precompile
    unset SECRET_KEY_BASE_DUMMY
    msg_ok "Updated Sure"

    msg_info "Starting Service"
    $STD systemctl start sure
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
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
