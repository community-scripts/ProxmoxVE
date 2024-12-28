#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 community-scripts ORG
# Author: remz1337
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

# App Default Values
APP="Authentik"
var_tags="identity-provider"
var_disk="15"
var_cpu="6"
var_ram="8192"
var_os="debian"
var_version="12"
var_unprivileged="1"

# App Output & Base Settings
header_info "$APP"
base_settings

# Core
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -f /etc/systemd/system/authentik-server.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -s https://api.github.com/repos/goauthentik/authentik/releases/latest | grep "tarball_url" | awk '{print substr($2, 2, length($2)-3)}')
  if [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then
    msg_info "Stopping ${APP}"
    systemctl stop authentik-server
    systemctl stop authentik-worker
    msg_ok "Stopped ${APP}"

    msg_info "Building ${APP} website"
    mkdir -p /opt/authentik
    wget -qO authentik.tar.gz "${RELEASE}"
    tar -xzf authentik.tar.gz -C /opt/authentik --strip-components 1 --overwrite
    rm -rf authentik.tar.gz
    cd /opt/authentik/website
    npm install &>/dev/null
    npm run build-bundled &>/dev/null
    cd /opt/authentik/web
    npm install &>/dev/null
    npm run build &>/dev/null
    msg_ok "Built ${APP} website"

    msg_info "Installing Python Dependencies"
    cd /opt/authentik
    poetry install --only=main --no-ansi --no-interaction --no-root &>/dev/null
    poetry export --without-hashes --without-urls -f requirements.txt --output requirements.txt &>/dev/null
    pip install --no-cache-dir -r requirements.txt &>/dev/null
    pip install . &>/dev/null
    msg_ok "Installed Python Dependencies"

    msg_info "Updating ${APP} to v${RELEASE} (Patience)"
    cp -r /opt/authentik/authentik/blueprints /opt/authentik/blueprints
    bash /opt/authentik/lifecycle/ak migrate &>/dev/null
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated ${APP} to v${RELEASE}"

    msg_info "Starting ${APP}"
    systemctl start authentik-server
    systemctl start authentik-worker
    msg_ok "Started ${APP}"
  else
    msg_ok "No update required. ${APP} is already at v${RELEASE}"
  fi
  exit
}

start
build_container
description

echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:9000/if/flow/initial-setup/${CL}"
