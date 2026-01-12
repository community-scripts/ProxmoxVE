#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/booklore-app/BookLore

APP="BookLore"
var_tags="${var_tags:-books;library}"
var_cpu="${var_cpu:-3}"
var_ram="${var_ram:-3072}"
var_disk="${var_disk:-7}"
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

  if [[ ! -d /opt/booklore ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "booklore" "booklore-app/BookLore"; then
    JAVA_VERSION="21" setup_java
    NODE_VERSION="22" setup_nodejs
    setup_mariadb
    setup_yq

    msg_info "Stopping Service"
    systemctl stop booklore
    msg_ok "Stopped Service"

    if grep -qE "^BOOKLORE_(DATA_PATH|BOOKDROP_PATH|BOOKS_PATH|PORT)=" /opt/booklore_storage/.env 2>/dev/null; then
      msg_info "Migrating old environment variables"
      sed -i 's/^BOOKLORE_DATA_PATH=/APP_PATH_CONFIG=/g' /opt/booklore_storage/.env
      sed -i 's/^BOOKLORE_BOOKDROP_PATH=/APP_BOOKDROP_FOLDER=/g' /opt/booklore_storage/.env
      sed -i '/^BOOKLORE_BOOKS_PATH=/d' /opt/booklore_storage/.env
      sed -i '/^BOOKLORE_PORT=/d' /opt/booklore_storage/.env
      msg_ok "Migrated old environment variables"
    fi

    msg_info "Backing up old installation"
    mv /opt/booklore /opt/booklore_bak
    msg_ok "Backed up old installation"

    fetch_and_deploy_gh_release "booklore" "booklore-app/BookLore" "tarball"

    msg_info "Building Frontend"
    cd /opt/booklore/booklore-ui
    $STD npm install --force
    $STD npm run build --configuration=production
    msg_ok "Built Frontend"

    msg_info "Building Backend"
    cd /opt/booklore/booklore-api
    APP_VERSION=$(get_latest_github_release "booklore-app/BookLore")
    yq eval ".app.version = \"${APP_VERSION}\"" -i src/main/resources/application.yaml
    $STD ./gradlew clean build --no-daemon
    mkdir -p /opt/booklore/dist
    JAR_PATH=$(find /opt/booklore/booklore-api/build/libs -maxdepth 1 -type f -name "booklore-api-*.jar" ! -name "*plain*" | head -n1)
    if [[ -z "$JAR_PATH" ]]; then
      msg_error "Backend JAR not found"
      exit
    fi
    cp "$JAR_PATH" /opt/booklore/dist/app.jar
    msg_ok "Built Backend"

    msg_info "Starting Service"
    systemctl start booklore
    systemctl reload nginx
    rm -rf /opt/booklore_bak
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:6060${CL}"
