#!/usr/bin/env bash
COMMUNITY_SCRIPTS_URL="${COMMUNITY_SCRIPTS_URL:-https://raw.githubusercontent.com/Heretek-AI/ProxmoxVE/refs/heads/main}"
source <(curl -fsSL "${COMMUNITY_SCRIPTS_URL}"/misc/build.func)
# Author: BillyOutlast
# License: MIT | https://github.com/Heretek-AI/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/mudler/skillserver

APP="skillserver"
var_tags="${var_tags:-ai;mcp;skills;agents}"
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

  if [[ ! -f /usr/local/bin/skillserver ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "skillserver" "mudler/skillserver"; then
    msg_info "Stopping Service"
    systemctl stop skillserver
    msg_ok "Stopped Service"

    msg_info "Backing up Data"
    cp -r /opt/skillserver/skills /opt/skillserver_skills_backup
    msg_ok "Backed up Data"

    setup_go

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "skillserver" "mudler/skillserver" "tarball" "latest" "/opt/skillserver"

    msg_info "Building Application"
    cd /opt/skillserver || exit
    $STD go build -o /usr/local/bin/skillserver ./cmd/skillserver
    msg_ok "Built Application"

    msg_info "Restoring Data"
    cp -r /opt/skillserver_skills_backup/. /opt/skillserver/skills
    rm -rf /opt/skillserver_skills_backup
    msg_ok "Restored Data"

    msg_info "Starting Service"
    systemctl start skillserver
    msg_ok "Started Service"
    msg_ok "Updated Successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"
