#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/booklore-app/BookLore

APP="BookLore"
var_tags="${var_tags:-books;library}"
var_cpu="${var_cpu:-3}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-7}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/booklore ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "booklore" "booklore-app/BookLore"; then
    msg_info "Stopping $APP"
    systemctl stop booklore
    msg_ok "Stopped $APP"

    msg_info "backup old install"
    mv /opt/booklore /opt/booklore_bak
    msg_ok "backup done"

    fetch_and_deploy_gh_release "booklore" "booklore-app/BookLore"

    msg_info "Building Frontend"
    cd /opt/booklore/booklore-ui
    $STD npm install --force
    $STD npm run build --configuration=production
    msg_ok "Built Frontend"

    msg_info "Building Backend"
    cd /opt/booklore/booklore-api
    APP_VERSION=$(curl -fsSL https://api.github.com/repos/booklore-app/BookLore/releases/latest | yq '.tag_name' | sed 's/^v//')
    yq eval ".app.version = \"${APP_VERSION}\"" -i src/main/resources/application.yaml
    $STD ./gradlew clean build --no-daemon
    mkdir -p /opt/booklore/dist
    JAR_PATH=$(find /opt/booklore/booklore-api/build/libs -maxdepth 1 -type f -name "booklore-api-*.jar" ! -name "*plain*" | head -n1)
    if [[ -z "$JAR_PATH" ]]; then
      msg_error "Backend JAR not found"
      exit 1
    fi
    cp "$JAR_PATH" /opt/booklore/dist/app.jar
    msg_ok "Built Backend"

    msg_info "Starting $APP"
    systemctl start booklore
    systemctl reload nginx
    rm -rf /opt/booklore_bak
    msg_ok "Started $APP"
    msg_ok "Updated Successfully"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:6060${CL}"
