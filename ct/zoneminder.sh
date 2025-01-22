#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 community-scripts ORG
# Author: [YourUserName]
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: [SOURCE_URL]

# App Default Values
APP="ZoneMinder"
# Name of the app (e.g. Google, Adventurelog, Apache-Guacamole)
TAGS="cctv;surveillance"
# Tags for Proxmox VE, maximum 2 pcs., no spaces allowed, separated by a semicolon ; (e.g. database | adblock;dhcp)
var_cpu="2"
# Number of cores (1-X) (e.g. 4) - default is 2
var_ram="2048"
# Amount of used RAM in MB (e.g. 2048 or 4096)
var_disk="16"
# Amount of used disk space in GB (e.g. 4 or 10)
var_os="ubuntu"
# Default OS (e.g. debian, ubuntu, alpine)
var_version="22.04"
# Default OS version (e.g. 12 for debian, 24.04 for ubuntu, 3.20 for alpine)
var_unprivileged="1"
# 1 = unprivileged container, 0 = privileged container

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

    # Check if installation is present | -f for file, -d for folder
    # We assume zmpkg.pl is present if ZoneMinder was installed
    if [[ ! -f /usr/bin/zmpkg.pl ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi

    # Get the latest available release tag from GitHub
    # NOTE: The container must have 'grep' available (which is standard).
    RELEASE=$(curl -fsSL https://api.github.com/repos/ZoneMinder/zoneminder/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
    if [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt 2>/dev/null || echo 'none')" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then
        msg_info "Updating $APP"

        # Stopping Services
        msg_info "Stopping $APP"
        systemctl stop zoneminder
        msg_ok "Stopped $APP"

        # Creating Backup
        # Adjust paths as needed for your environment
        msg_info "Creating Backup"
        tar -czf "/opt/${APP}_backup_$(date +%F).tar.gz" /etc/zm /usr/share/zoneminder /var/cache/zoneminder
        msg_ok "Backup Created"

        # Execute Update (apt-based)
        msg_info "Updating $APP to v${RELEASE}"
        apt-get update && apt-get install --only-upgrade zoneminder -y
        msg_ok "Updated $APP to v${RELEASE}"

        # Starting Services
        msg_info "Starting $APP"
        systemctl start zoneminder
        sleep 2
        msg_ok "Started $APP"

        # Cleaning up
        msg_info "Cleaning Up"
        rm -rf /tmp/zoneminder-update
        msg_ok "Cleanup Completed"

        # Write out the new version
        echo "${RELEASE}" >/opt/${APP}_version.txt
        msg_ok "Update Successful"
    else
        msg_ok "No update required. ${APP} is already at v${RELEASE}"
    fi
    exit
}

function post_build_provision() {
  local FILE='zoneminder-install.sh'
  local file_name="${FILE##*/}"

  # Make sure we actually have the install script on the PVE host:
  if [[ ! -f "$FILE" ]]; then
    msg_error "Unable to find $FILE on Proxmox host. Please ensure it’s in the same directory."
    exit 1
  fi

  msg_info "Uploading $FILE to container"
  pct push "${CTID}" "$FILE" "/root/$file_name" >/dev/null 2>&1
  msg_ok "Uploaded $FILE"

  msg_info "Executing $FILE inside container"
  pct exec "${CTID}" -- chmod +x "/root/$file_name"
  pct exec "${CTID}" -- "/root/$file_name"
  msg_ok "Executed $FILE"
}

start
build_container
post_build_provision
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:80/zm${CL}"
