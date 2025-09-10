#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.bunkerweb.io/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y apt-transport-https
$STD apt-get install -y lsb-release
msg_ok "Installed Dependencies"

RELEASE=$(curl -fsSL https://api.github.com/repos/bunkerity/bunkerweb/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
msg_warn "WARNING: This script will run an external installer from a third-party source (install-bunkerweb.sh)."
msg_warn "The following code is NOT maintained or audited by our repository."
msg_warn "If you have any doubts or concerns, please review the installer code before proceeding:"
msg_custom "${TAB3}${GATEWAY}${BGN}${CL}" "\e[1;34m" "→  https://github.com/bunkerity/bunkerweb/raw/v${RELEASE}/misc/install-bunkerweb.sh"
echo
read -r -p "${TAB3}Do you want to continue? [y/N]: " CONFIRM
if [[ ! "$CONFIRM" =~ ^([yY][eE][sS]|[yY])$ ]]; then
  msg_error "Aborted by user. No changes have been made."
  exit 10
fi
msg_info "Installing BunkerWeb (Patience)"
curl -fsSL -o install-bunkerweb.sh https://github.com/bunkerity/bunkerweb/raw/v${RELEASE}/misc/install-bunkerweb.sh
chmod +x install-bunkerweb.sh
$STD ./install-bunkerweb.sh --yes
$STD apt-mark unhold bunkerweb nginx
cat <<EOF >/etc/apt/preferences.d/bunkerweb
Package: bunkerweb
Pin: version ${RELEASE}
Pin-Priority: 1001
EOF
echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
msg_ok "Installed BunkerWeb v${RELEASE}"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
