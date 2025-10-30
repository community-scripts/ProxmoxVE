#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://gethomepage.dev/

APP="Homepage"
var_tags="${var_tags:-dashboard}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-6}"
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
  if [[ ! -d /opt/homepage ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  NODE_VERSION="22" NODE_MODULE="pnpm@latest" setup_nodejs
  if ! command -v jq &>/dev/null; then
    $STD msg_info "Installing jq..."
    $STD apt-get update -qq &>/dev/null
    $STD apt-get install -y jq &>/dev/null || {
      msg_error "Failed to install jq"
      exit
    }
  fi
  LOCAL_IP=$(hostname -I | awk '{print $1}')
  RELEASE=$(curl -fsSL https://api.github.com/repos/gethomepage/homepage/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then
    msg_info "Updating Homepage to v${RELEASE} (Patience)"
    systemctl stop homepage
    curl -fsSL "https://github.com/gethomepage/homepage/archive/refs/tags/v${RELEASE}.tar.gz" -o $(basename "https://github.com/gethomepage/homepage/archive/refs/tags/v${RELEASE}.tar.gz")
    tar -xzf v${RELEASE}.tar.gz
    rm -rf v${RELEASE}.tar.gz
    cp -r homepage-${RELEASE}/* /opt/homepage/
    rm -rf homepage-${RELEASE}
    cd /opt/homepage
    $STD pnpm install
    $STD pnpm update --no-save caniuse-lite
    export NEXT_PUBLIC_VERSION="v$RELEASE"
    export NEXT_PUBLIC_REVISION="source"
    export NEXT_PUBLIC_BUILDTIME=$(curl -fsSL https://api.github.com/repos/gethomepage/homepage/releases/latest | jq -r '.published_at')
    export NEXT_TELEMETRY_DISABLED=1
    $STD pnpm build
    if [[ ! -f /opt/homepage/.env ]]; then
      echo "HOMEPAGE_ALLOWED_HOSTS=localhost:3000,${LOCAL_IP}:3000" >/opt/homepage/.env
    fi
    systemctl start homepage
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated successfully!"
  else
    msg_ok "No update required. ${APP} is already at v${RELEASE}"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
