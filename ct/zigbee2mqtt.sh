#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/develop/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.zigbee2mqtt.io/

# App Default Values
APP="Zigbee2MQTT"
var_tags="smarthome;zigbee;mqtt"
var_cpu="2"
var_ram="1024"
var_disk="4"
var_os="debian"
var_version="12"
var_unprivileged="0"

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
  if [[ ! -d /opt/zigbee2mqtt ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if [[ "$(node -v | cut -d 'v' -f 2)" == "18."* ]]; then
    if ! command -v npm >/dev/null 2>&1; then
      echo "Installing NPM..."
      apt-get install -y npm >/dev/null 2>&1
      echo "Installed NPM..."
    fi
  fi
  cd /opt/zigbee2mqtt

  stop_zigbee2mqtt() {
    if which systemctl 2>/dev/null >/dev/null; then
      echo "Shutting down Zigbee2MQTT..."
      sudo systemctl stop zigbee2mqtt
    else
      echo "Skipped stopping Zigbee2MQTT, no systemctl found"
    fi
  }

  start_zigbee2mqtt() {
    if which systemctl 2>/dev/null >/dev/null; then
      echo "Starting Zigbee2MQTT..."
      sudo systemctl start zigbee2mqtt
    else
      echo "Skipped starting Zigbee2MQTT, no systemctl found"
    fi
  }

  set -e

  if [ -d data-backup ]; then
    echo "ERROR: Backup directory exists. May be previous restoring was failed?"
    echo "1. Save 'data-backup' and 'data' dirs to safe location to make possibility to restore config later."
    echo "2. Manually delete 'data-backup' dir and try again."
    exit 1
  fi

  stop_zigbee2mqtt

  echo "Generating a backup of the configuration..."
  cp -R data data-backup || {
    echo "Failed to create backup."
    exit 1
  }

  echo "Checking if any changes were made to package-lock.json..."
  git checkout package-lock.json || {
    echo "Failed to check package-lock.json."
    exit 1
  }

  echo "Initiating update..."
  if ! git pull; then
    echo "Update failed, temporarily storing changes and trying again."
    git stash && git pull || (
      echo "Update failed even after storing changes. Aborting."
      exit 1
    )
  fi

  echo "Acquiring necessary components..."
  npm ci || {
    echo "Failed to install necessary components."
    exit 1
  }

  echo "Building..."
  npm run build || {
    echo "Failed to build new version."
    exit 1
  }

  echo "Restoring configuration..."
  cp -R data-backup/* data || {
    echo "Failed to restore configuration."
    exit 1
  }

  rm -rf data-backup || {
    echo "Failed to remove backup directory."
    exit 1
  }

  start_zigbee2mqtt

  echo "Done!"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:9442${CL}"