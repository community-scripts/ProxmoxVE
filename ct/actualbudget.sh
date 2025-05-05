#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVED/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://actualbudget.org/

APP="Actual Budget"
var_tags="finance"
var_cpu="2"
var_ram="2048"
var_disk="4"
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

  if [[ ! -d /opt/actualbudget ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  NODE_VERSION="22"
  install_node_and_modules
  RELEASE=$(curl -fsSL https://api.github.com/repos/actualbudget/actual/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [[ -f /opt/actualbudget-data/config.json ]]; then
    if [[ ! -f /opt/actualbudget_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/actualbudget_version.txt)" ]]; then
      msg_info "Stopping ${APP}"
      systemctl stop actualbudget
      msg_ok "${APP} Stopped"

      msg_info "Updating ${APP} to ${RELEASE}"
      $STD npm update -g @actual-app/sync-server
      echo "${RELEASE}" >/opt/actualbudget_version.txt
      msg_ok "Updated ${APP} to ${RELEASE}"

      msg_info "Starting ${APP}"
      systemctl start actualbudget
      msg_ok "Restarted ${APP}"
    fi
  else
    msg_info "Performing full migration to npm-based version (${RELEASE})"
    systemctl stop actualbudget
    rm -rf /opt/actualbudget
    rm -rf /opt/actualbudget_bak
    mkdir -p /opt/actualbudget
    cd /opt/actualbudget
    $STD npm install --location=global @actual-app/sync-server

    mkdir -p /opt/actualbudget-data/{server-files,user-files}
    chown -R root:root /opt/actualbudget-data
    chmod -R 755 /opt/actualbudget-data
    cat <<EOF >/opt/actualbudget-data/config.json
{
  "port": 5006,
  "hostname": "::",
  "serverFiles": "/opt/actualbudget-data/server-files",
  "userFiles": "/opt/actualbudget-data/user-files",
  "trustedProxies": [
    "10.0.0.0/8",
    "172.16.0.0/12",
    "192.168.0.0/16",
    "127.0.0.1/32",
    "::1/128",
    "fc00::/7"
  ],
  "https": {
    "key": "/opt/actualbudget/selfhost.key",
    "cert": "/opt/actualbudget/selfhost.crt"
  }
}
EOF

    if [[ ! -f /opt/actualbudget/selfhost.key ]]; then
      openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /opt/actualbudget/selfhost.key \
        -out /opt/actualbudget/selfhost.crt \
        -subj "/C=US/ST=California/L=San Francisco/O=My Organization/OU=My Unit/CN=localhost/emailAddress=myemail@example.com"
    fi
    cat <<EOF >/etc/systemd/system/actualbudget.service
[Unit]
Description=Actual Budget Service
After=network.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=/opt/actualbudget
Environment=ACTUAL_UPLOAD_FILE_SIZE_LIMIT_MB=20
Environment=ACTUAL_UPLOAD_SYNC_ENCRYPTED_FILE_SYNC_SIZE_LIMIT_MB=50
Environment=ACTUAL_UPLOAD_FILE_SYNC_SIZE_LIMIT_MB=20
ExecStart=/usr/bin/actual-server --config /opt/actualbudget-data/config.json
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    echo "${RELEASE}" >/opt/actualbudget_version.txt
    $STD systemctl daemon-reload
    systemctl enable actualbudget
    systemctl start actualbudget
    msg_ok "Migrated and started ${APP} ${RELEASE}"
  fi

  msg_ok "Update done"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}https://${IP}:5006${CL}"
