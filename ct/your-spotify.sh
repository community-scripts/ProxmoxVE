#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Yooooomi/your_spotify

APP="Your-Spotify"
var_tags="${var_tags:-music;analytics}"
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

  if [[ ! -d /opt/your-spotify ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "your-spotify" "Yooooomi/your_spotify"; then
    msg_info "Stopping Services"
    systemctl stop your-spotify your-spotify-web
    msg_ok "Stopped Services"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "your-spotify" "Yooooomi/your_spotify" "tarball"

    msg_info "Building Your Spotify"
    cd /opt/your-spotify
    $STD pnpm install --frozen-lockfile
    $STD pnpm --filter @your_spotify/server build
    $STD pnpm --filter @your_spotify/client build
    msg_ok "Built Your Spotify"

  fi

  msg_info "Applying Client Configuration"
  API_ENDPOINT=$(grep '^API_ENDPOINT=' /opt/your-spotify.env | cut -d= -f2-)
  cp /opt/your-spotify/apps/client/build/variables-template.js /opt/your-spotify/apps/client/build/variables.js
  sed -i "s;__API_ENDPOINT__;${API_ENDPOINT};g" /opt/your-spotify/apps/client/build/variables.js
  sed -i "s#connect-src \(.*\);#connect-src 'self' ${API_ENDPOINT}/;#g" /opt/your-spotify/apps/client/build/index.html
  msg_ok "Applied Client Configuration"

  msg_info "Restarting Services"
  systemctl restart your-spotify your-spotify-web
  msg_ok "Restarted Services"
  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:3000${CL}"
echo -e "${INFO}${YW}Add your Spotify app keys to /opt/your-spotify.env first${CL}"
echo -e "${INFO}${YW}Spotify rejects plain http redirect URIs on a LAN address.${CL}"
echo -e "${INFO}${YW}Put this behind a TLS reverse proxy and register:${CL}"
echo -e "${TAB}${DEFAULT}${BGN}https://your.domain/oauth/spotify/callback${CL}"
echo -e "${INFO}${YW}Then set API_ENDPOINT to that https URL and rerun the update.${CL}"
