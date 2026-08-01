#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://coder.com/ | Github: https://github.com/coder/code-server

source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/core.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/tools.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/error_handler.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/api.func) 2>/dev/null || true
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "coder-code-server" "addon"

# Enable error handling
set -Eeuo pipefail
trap 'error_handler' ERR

APP="Coder Code Server"
APP_TYPE="addon"

# Initialize all core functions (colors, formatting, icons, STD mode)
load_functions

header_info

if command -v pveversion >/dev/null 2>&1; then
  msg_error "Can't Install on Proxmox"
  exit 1
fi
if [ -e /etc/alpine-release ]; then
  msg_error "Can't Install on Alpine"
  exit 1
fi

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

msg_info "Installing Dependencies"
$STD apt update
$STD apt install -y curl git
msg_ok "Installed Dependencies"

VERSION=$(curl -fsSL https://api.github.com/repos/coder/code-server/releases/latest |
  grep "tag_name" |
  awk '{print substr($2, 3, length($2)-4) }')

msg_info "Installing Code-Server v${VERSION}"
config_path="${HOME}/.config/code-server/config.yaml"
preexisting_config=false

if [ -f "$config_path" ]; then
  preexisting_config=true
fi

$STD curl -fOL https://github.com/coder/code-server/releases/download/v"$VERSION"/code-server_"${VERSION}"_amd64.deb
$STD dpkg -i code-server_"${VERSION}"_amd64.deb
rm -rf code-server_"${VERSION}"_amd64.deb
mkdir -p "${HOME}/.config/code-server/"

if [ "$preexisting_config" = false ]; then
  cat <<EOF >"$config_path"
bind-addr: 0.0.0.0:8680
auth: none
password: 
cert: false
EOF
fi
systemctl enable -q --now code-server@"$USER"
systemctl restart code-server@"$USER"
if ! systemctl is-active --quiet code-server@"$USER"; then
  msg_error "code-server service failed to start."
  exit 1
fi
msg_ok "Installed Code-Server v${VERSION}"

echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}:8680${CL} \n"
