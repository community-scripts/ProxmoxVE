#!/usr/bin/env bash

# Copyright (c) 2021-2024 tteck
# Author: beardnetwork
# License: MIT
# https://github.com/cbeardcodes/ProxmoxVE-beardnetwork/raw/main/LICENSE

function header_info {
    clear
    cat <<"EOF"
  _____          _           _ _ 
 |_   _|   _  __| |_   _  __| (_)
   | || | | |/ _` | | | |/ _` | |
   | || |_| | (_| | |_| | (_| | |
   |_| \__,_|\__,_|\__,_|\__,_|_|
                                 

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
HOLD=" "
CM="${GN}✓${CL}"
APP="Tududi"
hostname="$(hostname)"
silent() { "$@" >/dev/null 2>&1; }
set -e
spinner() {
    local chars="/-\|"
    local spin_i=0
    printf "\e[?25l"
    while true; do
        printf "\r \e[36m%s\e[0m" "${chars:spin_i++%${#chars}:1}"
        sleep 0.1
    done
}

msg_info() {
  local msg="$1"
  echo -ne " ${HOLD} ${YW}${msg}   "
  spinner & 
  SPINNER_PID=$!
}

msg_ok() {
  if [ -n "$SPINNER_PID" ] && ps -p $SPINNER_PID > /dev/null; then kill $SPINNER_PID > /dev/null; fi
  printf "\e[?25h"
  local msg="$1"
  echo -e "${BFR} ${CM} ${GN}${msg}${CL}"
}

install() {
  header_info
  while true; do
      read -p "This will Install ${APP} on $hostname. Proceed(y/n)?" yn
      case $yn in
      [Yy]*) break ;;
      [Nn]*) exit ;;
      *) echo "Please answer yes or no." ;;
      esac
  done
  header_info
  read -r -p "Verbose mode? <y/N> " prompt
  if [[ ${prompt,,} =~ ^(y|yes)$ ]]; then
    STD=""
  else
    STD="silent"
  fi
  msg_info "Installing $APP"
  
  # Install dependencies
  $STD apt-get update -y
  $STD apt-get install -y git curl python3 python3-pip python3-venv
  
  # Clone Tududi repository if not already present
  if [ ! -d "/opt/tududi" ]; then
    $STD git clone https://github.com/chrisvel/tududi.git /opt/tududi
  else
    cd /opt/tududi
    $STD git pull origin main
  fi
  
  # Set up Python environment
  cd /opt/tududi
  $STD python3 -m venv venv
  source /opt/tududi/venv/bin/activate
  $STD pip install -r /opt/tududi/requirements.txt
  
  # Create systemd service for Tududi
  cat <<EOF >/etc/systemd/system/tududi.service
[Unit]
Description=Tududi Service
After=network.target

[Service]
ExecStart=/opt/tududi/venv/bin/python /opt/tududi/tududi.py
WorkingDirectory=/opt/tududi
User=root
Group=root
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

  # Enable and start Tududi service
  systemctl enable tududi.service
  systemctl start tududi.service
  
  msg_ok "Installed $APP on $hostname"
  echo -e "${APP} should be reachable by going to the following URL.\n"
}

uninstall() {
  header_info
  msg_info "Uninstalling $APP"
  if [ -n "$SPINNER_PID" ] && ps -p $SPINNER_PID > /dev/null; then kill $SPINNER_PID > /dev/null; fi
  systemctl disable -q --now tududi
  rm -rf /opt/tududi
  rm -f /etc/systemd/system/tududi.service
  msg_ok "Uninstalled $APP"
  msg_ok "Completed Successfully!\n"
}

OPTIONS=(Install "Install $APP" \
         Uninstall "Uninstall $APP")

CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "$APP" --menu "Select an option:" 10 58 2 \
          "${OPTIONS[@]}" 3>&1 1>&2 2>&3)

case $CHOICE in
  "Install")
    install
    ;;
  "Uninstall")
    uninstall
    ;;
  *)
    echo "Exiting..."
    exit 0
    ;;
esac