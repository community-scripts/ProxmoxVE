#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/WeblateOrg/weblate

APP="Weblate"
var_tags="${var_tags:-translation;localization}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-3072}"
var_disk="${var_disk:-10}"
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

  if [[ ! -d /opt/weblate ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "weblate" "WeblateOrg/weblate"; then
    msg_info "Stopping Weblate"
    systemctl stop weblate weblate-celery
    msg_ok "Stopped Weblate"

    PYTHON_VERSION="3.14" setup_uv
    USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "weblate" "WeblateOrg/weblate" "singlefile" "latest" "/opt/weblate" "weblate-*-py3-none-any.whl"

    msg_info "Updating Weblate"
    $STD uv pip install --python /opt/weblate/.venv/bin/python --compile-bytecode /opt/weblate/weblate-*.whl "weblate[all,wsgi]"
    rm -f /opt/weblate/weblate-*.whl
    set -a
    source /opt/weblate_data/weblate.env
    set +a
    $STD /opt/weblate/.venv/bin/weblate migrate --noinput
    $STD /opt/weblate/.venv/bin/weblate collectstatic --noinput
    msg_ok "Updated Weblate"

    msg_info "Starting Weblate"
    systemctl start weblate-celery weblate
    msg_ok "Started Weblate"
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
