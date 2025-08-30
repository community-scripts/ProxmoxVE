#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Snarkenfaugister
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/pocket-id/pocket-id

APP="PocketID"
var_tags="${var_tags:-identity-provider}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-4}"
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

  if [[ ! -d /opt/pocket-id ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "pocket-id" "pocket-id/pocket-id"; then
    if [ "$(printf '%s\n%s' "$(cat ~/.pocket-id 2>/dev/null || echo 0.0.0)" "1.0.0" | sort -V | head -n1)" = "$(cat ~/.pocket-id 2>/dev/null || echo 0.0.0)" ] \
      && [ "$(cat ~/.pocket-id 2>/dev/null || echo 0.0.0)" != "1.0.0" ]; then      
      msg_info "Migrating ${APP}"
      systemctl -q disable --now pocketid-backend pocketid-frontend caddy
      mv /etc/caddy/Caddyfile ~/Caddyfile.bak
      $STD apt remove --purge caddy nodejs -y
      $STD apt autoremove -y
      rm /etc/apt/{keyrings/nodesource.gpg,sources.list.d/nodesource.list}
      rm -r /usr/local/go
      cp -r /opt/pocket-id/backend/data /opt/data
      cp /opt/pocket-id/backend/.env /opt/env
      sed -i -e 's/PUBLIC_//g' \
        -e '/^SQLITE_DB_PATH/d' \
        -e '/^POSTGRES/s/^/# /' \
        -e '/^UPLOAD_PATH/d' \
        -e 's/8080/1411/' /opt/env
      rm -r /opt/pocket-id
      rm /etc/systemd/system/pocketid-frontend.service
      BACKEND="/etc/systemd/system/pocketid-backend.service"
      sed -i -e 's/Backend/Service/' \
        -e 's/\/backend\|-backend//g' "$BACKEND"
      mv "$BACKEND" ${BACKEND//-backend/}
      systemctl daemon-reload
      systemctl -q enable pocketid
      mkdir /opt/pocket-id
      mv /opt/data /opt/pocket-id
      msg_ok "Migration complete. The reverse proxy port has been changed to 1411."
    else
      msg_info "Stopping ${APP}"
      systemctl stop pocketid
      msg_ok "Stopped ${APP}"
      cp /opt/pocket-id/.env /opt/env
    fi

    fetch_and_deploy_gh_release "pocket-id" "pocket-id/pocket-id" "singlefile" "latest" "/opt/pocket-id/" "pocket-id-linux-amd64"
    mv /opt/env /opt/pocket-id/.env

    msg_info "Starting $APP"
    systemctl start pocketid
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
echo -e "${INFO}${YW} Configure your reverse proxy to point to:${BGN} ${IP}:1411${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}https://{PUBLIC_URL}/setup${CL}"
