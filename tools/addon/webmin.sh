#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.webmin.com/ | Github: https://github.com/webmin/webmin

APP="Webmin"
APP_TYPE="addon"

if ! command -v curl &>/dev/null; then
  printf "\r\e[2K%b" '\033[93m Setup Source \033[m' >&2
  if [[ -f /etc/alpine-release ]]; then
    apk update >/dev/null 2>&1
    apk add --no-cache curl >/dev/null 2>&1
  else
    apt-get update >/dev/null 2>&1
    apt-get install -y curl >/dev/null 2>&1
  fi
fi
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/core.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/tools.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/error_handler.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/api.func) 2>/dev/null || true
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "webmin" "addon"

# Enable error handling
set -Eeuo pipefail
trap 'error_handler' ERR

# Initialize all core functions (colors, formatting, icons, STD mode)
load_functions
require_debian_like

header_info

whiptail --backtitle "Proxmox VE Helper Scripts" --title "${APP} Installer" --yesno "This Will Install ${APP} on this LXC Container. Proceed?" 10 58

msg_info "Installing Prerequisites"
$STD apt update
$STD apt install -y \
  libnet-ssleay-perl \
  libauthen-pam-perl \
  libio-pty-perl \
  unzip \
  shared-mime-info \
  curl
msg_ok "Installed Prerequisites"

msg_info "Installing ${APP}"
fetch_and_deploy_gh_release "webmin" "webmin/webmin" "binary" "latest" "/opt/webmin" "webmin_*_all.deb"
/usr/share/webmin/changepass.pl /etc/webmin root root &>/dev/null
msg_ok "Installed ${APP}"

get_lxc_ip
echo -e "Successfully Installed!! ${APP} should be reachable by going to ${BL}https://${LOCAL_IP}:10000${CL}"

