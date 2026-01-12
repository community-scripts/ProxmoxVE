#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://tomcat.apache.org/

APP="Apache-Tomcat"
var_tags="${var_tags:-webserver}"
var_disk="${var_disk:-5}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
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

  TOMCAT_DIR=$(ls -d /opt/tomcat-* 2>/dev/null | head -n1)
  if [[ -z "$TOMCAT_DIR" || ! -d "$TOMCAT_DIR" ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  # Detect major version and current version from install path (e.g., /opt/tomcat-11 -> 11)
  TOMCAT_MAJOR=$(basename "$TOMCAT_DIR" | grep -oP 'tomcat-\K[0-9]+')
  if [[ -z "$TOMCAT_MAJOR" ]]; then
    msg_error "Cannot determine Tomcat major version from path: $TOMCAT_DIR"
    exit
  fi
  CURRENT_VERSION=$(grep -oP 'Apache Tomcat Version \K[0-9.]+' "$TOMCAT_DIR/RELEASE-NOTES" 2>/dev/null || echo "unknown")
  LATEST_VERSION=$(curl -fsSL "https://dlcdn.apache.org/tomcat/tomcat-${TOMCAT_MAJOR}/" | grep -oP 'v[0-9]+\.[0-9]+\.[0-9]+(-M[0-9]+)?/' | sort -V | tail -n1 | sed 's/\/$//; s/v//')

  if [[ -z "$LATEST_VERSION" ]]; then
    msg_error "Failed to fetch latest version for Tomcat ${TOMCAT_MAJOR}"
    exit
  fi

  if [[ "$CURRENT_VERSION" == "$LATEST_VERSION" ]]; then
    msg_ok "${APP} ${CURRENT_VERSION} is already up to date"
    exit
  fi

  msg_info "Stopping Tomcat service"
  systemctl stop tomcat
  msg_ok "Stopped Tomcat service"

  msg_info "Backing up configuration and applications"
  BACKUP_DIR="/tmp/tomcat-backup-$$"
  mkdir -p "$BACKUP_DIR"
  cp -a "$TOMCAT_DIR/conf" "$BACKUP_DIR/conf"
  cp -a "$TOMCAT_DIR/webapps" "$BACKUP_DIR/webapps"
  [[ -d "$TOMCAT_DIR/lib" ]] && cp -a "$TOMCAT_DIR/lib" "$BACKUP_DIR/lib"
  msg_ok "Backed up configuration and applications"

  msg_info "Downloading Tomcat ${LATEST_VERSION}"
  TOMCAT_URL="https://dlcdn.apache.org/tomcat/tomcat-${TOMCAT_MAJOR}/v${LATEST_VERSION}/bin/apache-tomcat-${LATEST_VERSION}.tar.gz"
  curl -fsSL "$TOMCAT_URL" -o /tmp/tomcat-update.tar.gz
  msg_ok "Downloaded Tomcat ${LATEST_VERSION}"

  msg_info "Installing update"
  rm -rf "${TOMCAT_DIR:?}"/*
  tar --strip-components=1 -xzf /tmp/tomcat-update.tar.gz -C "$TOMCAT_DIR"
  rm -f /tmp/tomcat-update.tar.gz
  msg_ok "Installed update"

  msg_info "Restoring configuration and applications"
  cp -a "$BACKUP_DIR/conf"/* "$TOMCAT_DIR/conf/"
  cp -a "$BACKUP_DIR/webapps"/* "$TOMCAT_DIR/webapps/" 2>/dev/null || true
  if [[ -d "$BACKUP_DIR/lib" ]]; then
    for jar in "$BACKUP_DIR/lib"/*.jar; do
      [[ -f "$jar" ]] || continue
      jar_name=$(basename "$jar")
      if [[ ! -f "$TOMCAT_DIR/lib/$jar_name" ]]; then
        cp "$jar" "$TOMCAT_DIR/lib/"
      fi
    done
  fi
  rm -rf "$BACKUP_DIR"
  chown -R root:root "$TOMCAT_DIR"
  msg_ok "Restored configuration and applications"

  msg_info "Starting Tomcat service"
  systemctl start tomcat
  msg_ok "Started Tomcat service"
  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"
