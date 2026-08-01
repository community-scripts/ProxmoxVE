#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.crowdsec.net/ | Github: https://github.com/crowdsecurity/crowdsec

APP="CrowdSec"
APP_TYPE="addon"

source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/core.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/tools.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/error_handler.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/api.func) 2>/dev/null || true
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "crowdsec" "addon"

# Enable error handling
set -Eeuo pipefail
trap 'error_handler' ERR

# Initialize all core functions (colors, formatting, icons, STD mode)
load_functions

header_info

if command -v pveversion >/dev/null 2>&1; then
  msg_error "Can't Install on Proxmox"
  exit 1
fi

while true; do
  echo -n "${TAB}This will Install ${APP}. Proceed (y/n)? "
  read -r yn
  case $yn in
  [Yy]*) break ;;
  [Nn]*) exit ;;
  *) echo "Please answer yes or no." ;;
  esac
done

msg_info "Setting up ${APP} Repository"
$STD apt-get update
$STD apt-get install -y curl
$STD apt-get install -y gnupg
$STD bash -c "curl -fsSL https://install.crowdsec.net | bash"
msg_ok "Setup ${APP} Repository"

msg_info "Installing ${APP}"
$STD apt-get update
$STD apt-get install -y crowdsec
msg_ok "Installed ${APP}"

msg_info "Installing ${APP} Common Bouncer"
$STD apt-get install -y crowdsec-firewall-bouncer-iptables
msg_ok "Installed ${APP} Common Bouncer"

msg_ok "Completed successfully!\n"
