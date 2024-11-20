#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
       __     ____
      / /__  / / /_  __________  ___  __________
 __  / / _ \/ / / / / / ___/ _ \/ _ \/ ___/ ___/
/ /_/ /  __/ / / /_/ (__  )  __/  __/ /  / /
\____/\___/_/_/\__, /____/\___/\___/_/  /_/
              /____/
EOF
}
header_info
echo -e "Loading..."
APP="Jellyseerr"
var_disk="8"
var_cpu="4"
var_ram="4096"
var_os="debian"
var_version="12"
variables
color
catch_errors

function default_settings() {
  CT_TYPE="1"
  PW=""
  CT_ID=$NEXTID
  HN=$NSAPP
  DISK_SIZE="$var_disk"
  CORE_COUNT="$var_cpu"
  RAM_SIZE="$var_ram"
  BRG="vmbr0"
  NET="dhcp"
  GATE=""
  APT_CACHER=""
  APT_CACHER_IP=""
  DISABLEIP6="no"
  MTU=""
  SD=""
  NS=""
  MAC=""
  VLAN=""
  SSH="no"
  VERB="no"
  echo_default
}

function update_script() {
header_info
check_container_storage
check_container_resources
if [[ ! -d /opt/jellyseerr ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
if ! command -v pnpm &> /dev/null; then
    msg_error "pnpm not found. Installing..."
    npm install -g pnpm &>/dev/null
else
    msg_ok "pnpm is already installed."
fi
msg_info "Updating $APP"
cd /opt/jellyseerr
output=$(git pull --no-rebase)
if echo "$output" | grep -q "Already up to date."
then
  msg_ok "$APP is already up to date."
  exit
fi
systemctl stop jellyseerr
rm -rf dist
rm -rf .next 
rm -rf node_modules 
export CYPRESS_INSTALL_BINARY=0 
pnpm install --frozen-lockfile &>/dev/null
export NODE_OPTIONS="--max-old-space-size=3072"
pnpm build &>/dev/null
cat <<EOF >/etc/systemd/system/jellyseerr.service
[Unit]
Description=jellyseerr Service
After=network.target

[Service]
EnvironmentFile=/etc/jellyseerr/jellyseerr.conf
Environment=NODE_ENV=production
Type=exec
WorkingDirectory=/opt/jellyseerr
ExecStart=/usr/bin/node dist/index.js

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl start jellyseerr
msg_ok "Updated $APP"
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}:5055${CL} \n"
