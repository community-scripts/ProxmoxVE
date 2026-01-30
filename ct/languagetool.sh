#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://languagetool.org/

APP="LanguageTool"
var_tags="${var_tags:-spellcheck}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-16}"
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
  if [[ ! -d /opt/LanguageTool ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  RELEASE=$(curl -fsSL https://languagetool.org/download/ | grep -oP 'LanguageTool-\K[0-9]+\.[0-9]+(\.[0-9]+)?(?=\.zip)' | sort -V | tail -n1)
  if [[ "${RELEASE}" != "$(cat ~/.languagetool 2>/dev/null)" ]] || [[ ! -f ~/.languagetool ]]; then
    msg_info "Stopping Service"
    systemctl stop language-tool
    msg_ok "Stopped Service"

    msg_info "Creating Backup"
    cp /opt/LanguageTool/server.properties /opt/server.properties
    msg_ok "Created Backup"

    msg_info "Updating LanguageTool"
    rm -rf /opt/LanguageTool
    download_file "https://languagetool.org/download/LanguageTool-stable.zip" /tmp/LanguageTool-stable.zip
    unzip -q /tmp/LanguageTool-stable.zip -d /opt
    mv /opt/LanguageTool-*/ /opt/LanguageTool/
    mv /opt/server.properties /opt/LanguageTool/server.properties
    rm -f /tmp/LanguageTool-stable.zip
    echo "${RELEASE}" >~/.languagetool
    msg_ok "Updated LanguageTool"

    msg_info "Starting Service"
    systemctl start language-tool
    msg_ok "Started Service"
    msg_ok "Updated successfuly!"
  else
    msg_ok "No update required. ${APP} is already at v${RELEASE}"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8081/v2${CL}"
