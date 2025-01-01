#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
    clear
    cat <<"EOF"
    _______ __     ____
   / ____(_) /__  / __ )_________ _      __________  _____
  / /_  / / / _ \/ __  / ___/ __ \ | /| / / ___/ _ \/ ___/
 / __/ / / /  __/ /_/ / /  / /_/ / |/ |/ (__  )  __/ /
/_/   /_/_/\___/_____/_/   \____/|__/|__/____/\___/_/

EOF
}
IP=$(hostname -I | awk '{print $1}')
YW=$(echo "\033[33m")
BL=$(echo "\033[36m")
RD=$(echo "\033[01;31m")
BGN=$(echo "\033[4;92m")
GN=$(echo "\033[1;92m")
DGN=$(echo "\033[32m")
CL=$(echo "\033[m")
BFR="\\r\\033[K"
HOLD="-"
CM="${GN}✓${CL}"
APP="FileBrowser"
hostname="$(hostname)"
header_info
if [ -f /root/filebrowser.db ]; then
  read -r -p "Would you like to uninstall ${APP} on $hostname.? <y/N> " prompt
    if [[ "${prompt,,}" =~ ^(y|yes)$ ]]; then
      systemctl disable -q --now filebrowser.service
      rm -rf /usr/local/bin/filebrowser /root/filebrowser.db /etc/systemd/system/filebrowser.service
      echo "$APP Removed"
      sleep 2
      clear
      exit
    else
      clear
      exit
    fi
fi 
while true; do
    read -p "This will Install ${APP} on $hostname. Proceed(y/n)?" yn
    case $yn in
    [Yy]*) break ;;
    [Nn]*) exit ;;
    *) echo "Please answer yes or no." ;;
    esac
done
header_info
function msg_info() {
    local msg="$1"
    echo -ne " ${HOLD} ${YW}${msg}..."
}

function msg_ok() {
    local msg="$1"
    echo -e "${BFR} ${CM} ${GN}${msg}${CL}"
}

read -r -p "Would you like to use No Authentication? <y/N> " prompt
msg_info "Installing ${APP}"
apt-get install -y curl &>/dev/null
RELEASE=$(curl -fsSL https://api.github.com/repos/filebrowser/filebrowser/releases/latest | grep -o '"tag_name": ".*"' | sed 's/"//g' | sed 's/tag_name: //g')
curl -fsSL https://github.com/filebrowser/filebrowser/releases/download/$RELEASE/linux-amd64-filebrowser.tar.gz | tar -xzv -C /usr/local/bin &>/dev/null

if [[ "${prompt,,}" =~ ^(y|yes)$ ]]; then
  filebrowser config init -a '0.0.0.0' &>/dev/null
  filebrowser config set -a '0.0.0.0' &>/dev/null
  filebrowser config init --auth.method=noauth &>/dev/null
  filebrowser config set --auth.method=noauth &>/dev/null
  filebrowser users add ID 1 --perm.admin &>/dev/null  
else
  filebrowser config init -a '0.0.0.0' &>/dev/null
  filebrowser config set -a '0.0.0.0' &>/dev/null
  filebrowser users add admin helper-scripts.com --perm.admin &>/dev/null
fi
msg_ok "Installed ${APP} on $hostname"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/filebrowser.service
[Unit]
Description=Filebrowser
After=network-online.target

[Service]
User=root
WorkingDirectory=/root/
ExecStart=/usr/local/bin/filebrowser -r /

[Install]
WantedBy=default.target
EOF
systemctl enable -q --now filebrowser.service
msg_ok "Created Service"

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://$IP:8080${CL} \n"
