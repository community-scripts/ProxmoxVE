#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: MickLesk (Canbiz) & vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://hoarder.app/

APP="Hoarder"
var_tags="bookmark"
var_cpu="2"
var_ram="4096"
var_disk="10"
var_os="debian"
var_version="12"
var_unprivileged="1"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  APP_OLD="hoarder"
  APP_NEW="karakeep"

  if [[ ! -d /opt/${APP_OLD} ]]; then
    msg_error "No exist ${APP_OLD}-Installation found!"
    exit 1
  fi

  msg_info "Stopping old Services"
  systemctl stop hoarder-web hoarder-workers hoarder-browser meilisearch &>/dev/null || true
  msg_ok "Stopped old Services"

  msg_info "Disable old Services"
  systemctl disable hoarder-web hoarder-workers hoarder-browser meilisearch &>/dev/null || true
  rm -f /etc/systemd/system/hoarder-*.service
  msg_ok "OLd Services disabled"

  msg_info "Copy Folderstructure to new Project (/opt/${APP_NEW})"
  mv /opt/${APP_OLD} /opt/${APP_NEW}
  [[ -f /opt/${APP_OLD}_version.txt ]] && mv "/opt/${APP_OLD}_version.txt" "/opt/${APP_NEW^}_version.txt"
  msg_ok "Copy Folderstructure done"

  msg_info "Migrate .env File"
  mkdir -p /etc/${APP_NEW}
  if [[ -f /etc/${APP_OLD}/${APP_OLD}.env ]]; then
    mv "/etc/${APP_OLD}/${APP_OLD}.env" "/etc/${APP_NEW}/${APP_NEW}.env"
    rm -rf "/etc/${APP_OLD}"
  fi
  msg_ok ".env migrated"

  msg_info "Modify .env file"
  sed -i "s|/opt/${APP_OLD}|/opt/${APP_NEW}|g" "/etc/${APP_NEW}/${APP_NEW}.env"
  sed -i "s|${APP_OLD}|${APP_NEW}|g" "/etc/${APP_NEW}/${APP_NEW}.env"
  msg_ok ".env updated"

  msg_info "Create new Services"
  cat <<EOF >/etc/systemd/system/karakeep-web.service
[Unit]
Description=Karakeep Web
Wants=network.target karakeep-workers.service
After=network.target karakeep-workers.service

[Service]
ExecStart=pnpm start
WorkingDirectory=/opt/karakeep/apps/web
EnvironmentFile=/etc/karakeep/karakeep.env
Restart=always

[Install]
WantedBy=multi-user.target
EOF

  cat <<EOF >/etc/systemd/system/karakeep-browser.service
[Unit]
Description=Karakeep Headless Browser
After=network.target

[Service]
User=root
ExecStart=/usr/bin/chromium --headless --no-sandbox --disable-gpu --disable-dev-shm-usage --remote-debugging-address=127.0.0.1 --remote-debugging-port=9222 --hide-scrollbars
Restart=always

[Install]
WantedBy=multi-user.target
EOF

  cat <<EOF >/etc/systemd/system/karakeep-workers.service
[Unit]
Description=Karakeep Workers
Wants=network.target karakeep-browser.service meilisearch.service
After=network.target karakeep-browser.service meilisearch.service

[Service]
ExecStart=pnpm start:prod
WorkingDirectory=/opt/karakeep/apps/workers
EnvironmentFile=/etc/karakeep/karakeep.env
Restart=always
TimeoutStopSec=5

[Install]
WantedBy=multi-user.target
EOF

  msg_ok "New Services created"

  msg_info "Activate Karakeep-Services"
  systemctl daemon-reexec
  systemctl daemon-reload
  systemctl enable --now karakeep-web karakeep-workers karakeep-browser meilisearch
  msg_ok "Karakeep-Services activated"

  msg_info "Migrate update function"
  rm -f /usr/bin/update
  echo 'bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/karakeep.sh)"' >/usr/bin/update
  chmod +x /usr/bin/update
  msg_ok "Update function migrated"

  msg_info "Starting update process for ${APP_NEW}"
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/karakeep.sh)"
  msg_ok "Done"
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
