#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
    clear
    cat <<"EOF"
   ________
  / ____/ /___ _____  ________  _____
 / / __/ / __ `/ __ \/ ___/ _ \/ ___/
/ /_/ / / /_/ / / / / /__/  __(__  )
\____/_/\__,_/_/ /_/\___/\___/____/

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
APP="Glances"
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
  rm -rf /usr/lib/python3.*/EXTERNALLY-MANAGED
  $STD bash -c "$(wget -qLO - https://raw.githubusercontent.com/nicolargo/glancesautoinstall/master/install.sh)"
  cat <<EOF >/etc/systemd/system/glances.service
[Unit]
Description=Glances - An eye on your system
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/glances -w
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
  systemctl enable -q --now glances.service
  msg_ok "Installed $APP on $hostname"

  echo -e "${APP} should be reachable by going to the following URL.
           ${BL}http://$IP:61208${CL} \n"
}
uninstall() {
  header_info
  msg_info "Uninstalling $APP"
  if [ -n "$SPINNER_PID" ] && ps -p $SPINNER_PID > /dev/null; then kill $SPINNER_PID > /dev/null; fi
  systemctl disable -q --now glances
  bash -c "$(wget -qLO - https://raw.githubusercontent.com/nicolargo/glancesautoinstall/master/uninstall.sh)"
  rm -rf /etc/systemd/system/glances.service
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
