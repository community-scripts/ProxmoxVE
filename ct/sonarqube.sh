#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: prop4n
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://docs.sonarsource.com/sonarqube-server

APP="SonarQube"
var_tags="${var_tags:-automation}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-6144}"
var_disk="${var_disk:-25}"
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
  if [[ ! -d /opt/sonarqube ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "sonarqube" "SonarSource/sonarqube"; then
    msg_info "Stopping Service"
    systemctl stop sonarqube
    msg_ok "Stopped Service"

    msg_info "Creating backup"
    BACKUP_DIR="/opt/sonarqube-backup"
    mv /opt/sonarqube ${BACKUP_DIR}
    msg_ok "Backup created"

    msg_info "Installing sonarqube"
    temp_file=$(mktemp)
    RELEASE=$(curl -fsSL https://api.github.com/repos/SonarSource/sonarqube/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
    curl -fsSL "https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-${RELEASE}.zip" -o $temp_file
    unzip -q "$temp_file" -d /opt
    mv /opt/sonarqube-* /opt/sonarqube
    msg_ok "Installed sonarqube"

    msg_info "Restoring backup"
    cp -rp ${BACKUP_DIR}/data/ /opt/sonarqube/data/
    cp -rp ${BACKUP_DIR}/extensions/ /opt/sonarqube/extensions/
    cp -p ${BACKUP_DIR}/conf/sonar.properties /opt/sonarqube/conf/sonar.properties
    rm -rf ${BACKUP_DIR}
    chown -R sonarqube:sonarqube /opt/sonarqube
    msg_ok "Backup restored"

    msg_info "Starting Service"
    systemctl start sonarqube
    msg_ok "Service started"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:9000${CL}"
