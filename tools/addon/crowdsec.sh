#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.crowdsec.net/ | Github: https://github.com/crowdsecurity/crowdsec

APP="CrowdSec"
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
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "crowdsec" "addon"

# Enable error handling
set -Eeuo pipefail
trap 'error_handler' ERR

# Initialize all core functions (colors, formatting, icons, STD mode)
load_functions
require_debian_like

header_info
confirm_not_pve_host

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
$STD apt update
$STD apt install -y \
  curl \
  gnupg
$STD bash -c "curl -fsSL https://install.crowdsec.net | bash"
msg_ok "Setup ${APP} Repository"

msg_info "Installing ${APP}"
$STD apt update
$STD apt install -y crowdsec
msg_ok "Installed ${APP}"

msg_info "Installing ${APP} Common Bouncer"
$STD apt install -y crowdsec-firewall-bouncer-iptables
msg_ok "Installed ${APP} Common Bouncer"

msg_ok "Completed successfully!\n"
