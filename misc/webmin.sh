#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
  clear
  cat <<"EOF"
  _      __    __         _
 | | /| / /__ / /  __ _  (_)__
 | |/ |/ / -_) _ \/  ' \/ / _ \
 |__/|__/\__/_.__/_/_/_/_/_//_/

EOF
}
set -eEuo pipefail
YW=$(echo "\033[33m")
BL=$(echo "\033[36m")
BGN=$(echo "\033[4;92m")
GN=$(echo "\033[1;92m")
DGN=$(echo "\033[32m")
CL=$(echo "\033[m")
CM="${GN}✓${CL}"
BFR="\\r\\033[K"
HOLD="-"

msg_info() {
  local msg="$1"
  echo -ne " ${HOLD} ${YW}${msg}..."
}

msg_ok() {
  local msg="$1"
  echo -e "${BFR} ${CM} ${GN}${msg}${CL}"
}

header_info

whiptail --backtitle "Proxmox VE Helper Scripts" --title "Webmin Installer" --yesno "This Will Install Webmin on this LXC Container. Proceed?" 10 58 || exit

msg_info "Installing Prerequisites"
apt update &>/dev/null
apt-get -y install libnet-ssleay-perl libauthen-pam-perl libio-pty-perl unzip shared-mime-info &>/dev/null
msg_ok "Installed Prerequisites"

LATEST=$(curl -sL https://api.github.com/repos/webmin/webmin/releases/latest | grep '"tag_name":' | cut -d'"' -f4)

msg_info "Downloading Webmin"
wget -q https://github.com/webmin/webmin/releases/download/$LATEST/webmin_${LATEST}_all.deb
msg_ok "Downloaded Webmin"

msg_info "Installing Webmin"
dpkg -i webmin_${LATEST}_all.deb &>/dev/null
/usr/share/webmin/changepass.pl /etc/webmin root root &>/dev/null
rm -rf /root/webmin_${LATEST}_all.deb
msg_ok "Installed Webmin"

IP=$(hostname -I | cut -f1 -d ' ')
echo -e "Successfully Installed!! Webmin should be reachable by going to ${BL}https://${IP}:10000${CL}"
