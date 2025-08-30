#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/RayLabsHQ/gitea-mirror

APP="gitea-mirror"
var_tags="${var_tags:-mirror;gitea}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
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
  if [[ ! -d /opt/gitea-mirror ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  APP_VERSION=$(grep -o '"version": *"[^"]*"' /opt/gitea-mirror/package.json | cut -d'"' -f4)
  if [[ $APP_VERSION =~ ^2\. ]]; then
    if ! whiptail --backtitle "Gitea Mirror Update" --title "⚠️  VERSION 2.x DETECTED" --yesno \
      "WARNING: Version $APP_VERSION detected!\n\nUpdating from version 2.x will CLEAR ALL CONFIGURATION.\n\nThis includes:\n• API tokens\n• User settings\n• Repository configurations\n• All custom settings\n\nDo you want to continue with the update process?" 15 70 --defaultno; then
      exit 0
    fi

    if ! whiptail --backtitle "Gitea Mirror Update" --title "⚠️  FINAL CONFIRMATION" --yesno \
      "FINAL WARNING: This update WILL clear all configuration!\n\nBEFORE PROCEEDING, please:\n\n• Copy API tokens to a safe location\n• Backup any custom configurations\n• Note down repository settings\n\nThis action CANNOT be undone!" 18 70 --defaultno; then
      whiptail --backtitle "Gitea Mirror Update" --title "Update Cancelled" --msgbox "Update process cancelled. Please backup your configuration before proceeding." 8 60
      exit 0
    fi
    whiptail --backtitle "Gitea Mirror Update" --title "Proceeding with Update" --msgbox \
      "Proceeding with version $APP_VERSION update.\n\nAll configuration will be cleared as warned." 8 50
    rm -rf /opt/gitea-mirror
  fi

  if [[ ! -f /opt/gitea-mirror.env ]]; then
      msg_info "Detected old Enviroment, updating files"
      APP_SECRET=$(openssl rand -base64 32)
      HOST_IP=$(hostname -I | awk '{print $1}')
      cat <<EOF >/opt/gitea-mirror.env
# See here for config options: https://github.com/RayLabsHQ/gitea-mirror/blob/main/docs/ENVIRONMENT_VARIABLES.md
NODE_ENV=production
HOST=0.0.0.0
PORT=4321
DATABASE_URL=sqlite://data/gitea-mirror.db
BETTER_AUTH_URL=http://${HOST_IP}:4321
BETTER_AUTH_SECRET=${APP_SECRET}
npm_package_version=${APP_VERSION}
EOF
    rm /etc/systemd/system/gitea-mirror.service
    cat <<EOF >/etc/systemd/system/gitea-mirror.service
[Unit]
Description=Gitea Mirror
After=network.target
[Service]
Type=simple
WorkingDirectory=/opt/gitea-mirror
ExecStart=/usr/local/bin/bun dist/server/entry.mjs
Restart=on-failure
RestartSec=10
EnvironmentFile=/opt/gitea-mirror.env
[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    msg_ok "Old Enviroment fixed"
fi

  if check_for_gh_release "gitea-mirror" "RayLabsHQ/gitea-mirror"; then
    msg_info "Stopping Services"
    systemctl stop gitea-mirror
    msg_ok "Services Stopped"

    msg_info "Backup Data"
    mkdir -p /opt/gitea-mirror-backup/data
    cp /opt/gitea-mirror/data/* /opt/gitea-mirror-backup/data/
    msg_ok "Backup Data"

    msg_info "Installing Bun"
    export BUN_INSTALL=/opt/bun
    curl -fsSL https://bun.sh/install | $STD bash
    ln -sf /opt/bun/bin/bun /usr/local/bin/bun
    ln -sf /opt/bun/bin/bun /usr/local/bin/bunx
    msg_ok "Installed Bun"

    rm -rf /opt/gitea-mirror
    fetch_and_deploy_gh_release "gitea-mirror" "RayLabsHQ/gitea-mirror"

    msg_info "Updating and rebuilding ${APP}"
    cd /opt/gitea-mirror
    $STD bun run setup
    $STD bun run build
    APP_VERSION=$(grep -o '"version": *"[^"]*"' package.json | cut -d'"' -f4)

    sudo sed -i.bak "s|^npm_package_version=.*|npm_package_version=${APP_VERSION}|" /opt/gitea-mirror.env
    msg_ok "Updated and rebuilt ${APP}"

    msg_info "Restoring Data"
    cp /opt/gitea-mirror-backup/data/* /opt/gitea-mirror/data
    msg_ok "Restored Data"

    msg_info "Starting Service"
    systemctl start gitea-mirror
    msg_ok "Service Started"
    msg_ok "Update Successfully"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:4321${CL}"
