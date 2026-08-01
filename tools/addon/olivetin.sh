#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://docs.olivetin.app/ | Github: https://github.com/OliveTin/OliveTin

APP="OliveTin"
APP_TYPE="addon"

source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/core.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/tools.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/error_handler.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/api.func) 2>/dev/null || true
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "olivetin" "addon"

# Enable error handling
set -Eeuo pipefail
trap 'error_handler' ERR

# Initialize all core functions (colors, formatting, icons, STD mode)
load_functions

header_info
get_lxc_ip
IP="$LOCAL_IP"

while true; do
  echo -n "${TAB}This will Install ${APP}. Proceed (y/n)? "
  read -r yn
  case $yn in
  [Yy]*) break ;;
  [Nn]*) exit ;;
  *) echo "Please answer yes or no." ;;
  esac
done
unset _HEADER_SHOWN
header_info

msg_info "Installing ${APP}"
if ! command -v curl &>/dev/null; then
  $STD apt-get update
  $STD apt-get install -y curl
fi
curl -fsSL "https://github.com/OliveTin/OliveTin/releases/latest/download/OliveTin_linux_amd64.deb" -o OliveTin_linux_amd64.deb
$STD dpkg -i OliveTin_linux_amd64.deb
systemctl enable --now OliveTin &>/dev/null
rm OliveTin_linux_amd64.deb
msg_ok "Installed ${APP}"

msg_ok "Completed successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}:1337${CL} \n"
