#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/databasus/databasus

APP="Databasus"
var_tags="${var_tags:-backup;postgresql;database}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
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

  if [[ ! -f /opt/databasus/databasus ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "databasus" "databasus/databasus"; then
    msg_info "Stopping Databasus"
    $STD systemctl stop databasus
    msg_ok "Stopped Databasus"

    msg_info "Backing up Configuration"
    cp /opt/databasus/.env /opt/databasus.env.bak
    msg_ok "Backed up Configuration"

    msg_info "Ensuring Database Clients"
    # Create PostgreSQL version symlinks for compatibility
    for v in 12 13 14 15 16 18; do
      ln -sf /usr/lib/postgresql/17 /usr/lib/postgresql/$v
    done
    # Install MongoDB Database Tools via direct .deb (no APT repo for Debian 13)
    if ! command -v mongodump &>/dev/null; then
      [[ "$(get_os_info id)" == "ubuntu" ]] && MONGO_DIST="ubuntu2204" || MONGO_DIST="debian12"
      fetch_and_deploy_from_url "https://fastdl.mongodb.org/tools/db/mongodb-database-tools-${MONGO_DIST}-x86_64-100.14.1.deb"
    fi
    [[ -f /usr/bin/mongodump ]] && ln -sf /usr/bin/mongodump /usr/local/mongodb-database-tools/bin/mongodump
    [[ -f /usr/bin/mongorestore ]] && ln -sf /usr/bin/mongorestore /usr/local/mongodb-database-tools/bin/mongorestore
    # Create MariaDB and MySQL client symlinks for compatibility
    ensure_dependencies mariadb-client
    mkdir -p /usr/local/mariadb-{10.6,12.1}/bin /usr/local/mysql-{5.7,8.0,8.4,9}/bin /usr/local/mongodb-database-tools/bin
    for dir in /usr/local/mariadb-{10.6,12.1}/bin; do
      ln -sf /usr/bin/mariadb-dump "$dir/mariadb-dump"
      ln -sf /usr/bin/mariadb "$dir/mariadb"
    done
    for dir in /usr/local/mysql-{5.7,8.0,8.4,9}/bin; do
      ln -sf /usr/bin/mariadb-dump "$dir/mysqldump"
      ln -sf /usr/bin/mariadb "$dir/mysql"
    done
    msg_ok "Ensured Database Clients"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "databasus" "databasus/databasus" "tarball" "latest" "/opt/databasus"

    msg_info "Updating Databasus"
    cd /opt/databasus/frontend
    $STD npm ci
    $STD npm run build
    cd /opt/databasus/backend
    $STD go mod download
    $STD /root/go/bin/swag init -g cmd/main.go -o swagger
    $STD env CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o databasus ./cmd/main.go
    mv /opt/databasus/backend/databasus /opt/databasus/databasus
    mkdir -p /opt/databasus/ui/build
    cp -r /opt/databasus/frontend/dist/* /opt/databasus/ui/build/
    cp -r /opt/databasus/backend/migrations /opt/databasus/
    chown -R postgres:postgres /opt/databasus
    msg_ok "Updated Databasus"

    msg_info "Restoring Configuration"
    cp /opt/databasus.env.bak /opt/databasus/.env
    rm -f /opt/databasus.env.bak
    chown postgres:postgres /opt/databasus/.env
    msg_ok "Restored Configuration"

    msg_info "Starting Databasus"
    $STD systemctl start databasus
    msg_ok "Started Databasus"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
