#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.docuseal.com/

APP="DocuSeal"
var_tags="${var_tags:-document;esignature;pdf}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-10}"
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

  if [[ ! -d /opt/docuseal ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "docuseal" "docusealco/docuseal"; then
    msg_info "Stopping Services"
    systemctl stop docuseal docuseal-sidekiq
    msg_ok "Stopped Services"

    msg_info "Backing up Data"
    cp /opt/docuseal/.env /opt/docuseal.env.bak
    [[ -d /opt/docuseal/data ]] && mv /opt/docuseal/data /opt/docuseal_data.bak
    msg_ok "Backed up Data"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "docuseal" "docusealco/docuseal" "tarball"

    msg_info "Restoring Data"
    mv /opt/docuseal.env.bak /opt/docuseal/.env
    [[ -d /opt/docuseal_data.bak ]] && mv /opt/docuseal_data.bak /opt/docuseal/data
    msg_ok "Restored Data"

    msg_info "Building Application"
    cd /opt/docuseal
    export PATH="/root/.rbenv/bin:/root/.rbenv/shims:${PATH}"
    eval "$(rbenv init - bash)" 2>/dev/null || true
    export RAILS_ENV=production
    export NODE_ENV=production
    export SECRET_KEY_BASE_DUMMY=1
    set -a
    source /opt/docuseal/.env
    set +a
    $STD bundle config set --local deployment 'true'
    $STD bundle config set --local without 'development:test'
    $STD bundle install -j"$(nproc)"
    $STD yarn install --network-timeout 1000000
    $STD ./bin/shakapacker
    $STD bundle exec rails db:migrate
    $STD bundle exec bootsnap precompile -j 1 --gemfile app/ lib/
    chown -R docuseal:docuseal /opt/docuseal
    msg_ok "Built Application"

    msg_info "Starting Services"
    systemctl start docuseal docuseal-sidekiq
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
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
