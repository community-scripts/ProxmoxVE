#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://mealie.io

APP="Mealie"
var_tags="${var_tags:-recipes}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-10}"
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

  if [[ ! -d /opt/mealie ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "mealie" "mealie-recipes/mealie"; then
    PYTHON_VERSION="3.12" setup_uv
    NODE_MODULE="yarn" NODE_VERSION="20" setup_nodejs

    msg_info "Stopping $APP"
    systemctl stop mealie
    msg_ok "Stopped $APP"

    msg_info "Backing up .env and start.sh"
    cp -f /opt/mealie/mealie.env /opt/mealie/mealie.env.bak
    cp -f /opt/mealie/start.sh /opt/mealie/start.sh.bak
    msg_ok "Backup completed"

    fetch_and_deploy_gh_release "mealie" "mealie-recipes/mealie" "tarball" "latest" "/opt/mealie"

    msg_info "Rebuilding Frontend"
    export NUXT_TELEMETRY_DISABLED=1
    cd /opt/mealie/frontend
    $STD yarn install --prefer-offline --frozen-lockfile --non-interactive --production=false --network-timeout 1000000
    $STD yarn generate
    cp -r /opt/mealie/frontend/dist /opt/mealie/mealie/frontend
    msg_ok "Frontend rebuilt"

    msg_info "Rebuilding Backend Environment"
    cd /opt/mealie
    $STD /opt/mealie/.venv/bin/poetry self add "poetry-plugin-export>=1.9"
    MEALIE_VERSION=$(/opt/mealie/.venv/bin/poetry version --short)
    $STD /opt/mealie/.venv/bin/poetry build --output dist
    $STD /opt/mealie/.venv/bin/poetry export --only=main --extras=pgsql --output=dist/requirements.txt
    echo "mealie[pgsql]==$MEALIE_VERSION \\" >>dist/requirements.txt
    /opt/mealie/.venv/bin/poetry run pip hash dist/mealie-$MEALIE_VERSION*.whl | tail -n1 | tr -d '\n' >>dist/requirements.txt
    echo " \\" >>dist/requirements.txt
    /opt/mealie/.venv/bin/poetry run pip hash dist/mealie-$MEALIE_VERSION*.tar.gz | tail -n1 >>dist/requirements.txt
    msg_ok "Backend prepared"

    msg_info "Finalize Installation"
    $STD /opt/mealie/.venv/bin/uv pip install --require-hashes -r /opt/mealie/dist/requirements.txt --find-links dist
    msg_ok "Mealie installed"

    msg_info "Restoring Configuration"
    mv -f /opt/mealie/mealie.env.bak /opt/mealie/mealie.env
    mv -f /opt/mealie/start.sh.bak /opt/mealie/start.sh
    chmod +x /opt/mealie/start.sh
    msg_ok "Configuration restored"

    msg_info "Starting $APP"
    systemctl start mealie
    msg_ok "Started $APP"
    msg_ok "Update Successful"
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
