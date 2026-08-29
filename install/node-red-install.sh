#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://nodered.org/ | Github: https://github.com/node-red/node-red

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

setup_deb_based() {
  msg_info "Installing Dependencies"
  $STD apt install -y \
    git \
    ca-certificates
  msg_ok "Installed Dependencies"

  NODE_VERSION="22" setup_nodejs

  msg_info "Installing Node-Red"
  $STD npm install -g node-red
  echo "journalctl -f -n 100 -u nodered -o cat" >/usr/bin/node-red-log
  chmod +x /usr/bin/node-red-log
  echo "systemctl stop nodered" >/usr/bin/node-red-stop
  chmod +x /usr/bin/node-red-stop
  echo "systemctl start nodered" >/usr/bin/node-red-start
  chmod +x /usr/bin/node-red-start
  echo "systemctl restart nodered" >/usr/bin/node-red-restart
  chmod +x /usr/bin/node-red-restart
  msg_ok "Installed Node-Red"

  msg_info "Creating Service"
  service_path="/etc/systemd/system/nodered.service"
  echo "[Unit]
  Description=Node-RED
  After=syslog.target network.target

  [Service]
  ExecStart=/usr/bin/node-red --max-old-space-size=128 -v
  Restart=on-failure
  KillSignal=SIGINT

  SyslogIdentifier=node-red
  StandardOutput=syslog

  WorkingDirectory=/root/
  User=root
  Group=root

  [Install]
  WantedBy=multi-user.target" >$service_path
  systemctl enable -q --now nodered
  msg_ok "Created Service"
}

setup_alpine() {
  msg_info "Installing Dependencies"
  $STD apk add --no-cache \
    git \
    nodejs \
    npm
  msg_ok "Installed Dependencies"

  msg_info "Creating Node-RED User"
  adduser -D -H -s /sbin/nologin -G users nodered
  msg_ok "Created Node-RED User"

  msg_info "Installing Node-RED"
  $STD npm install -g node-red
  msg_ok "Installed Node-RED"

  msg_info "Creating /home/nodered"
  mkdir -p /home/nodered
  chown -R nodered:users /home/nodered
  chmod 750 /home/nodered
  msg_ok "Created /home/nodered"

  msg_info "Creating Node-RED Service"
  service_path="/etc/init.d/nodered"

  echo '#!/sbin/openrc-run
  description="Node-RED Service"

  command="/usr/local/bin/node-red"
  command_args="--max-old-space-size=128 -v"
  command_user="nodered"
  pidfile="/var/run/nodered.pid"
  command_background="yes"

  depend() {
      use net
  }' >$service_path

  chmod +x $service_path
  msg_ok "Created Node-RED Service"

  msg_info "Starting Node-RED"
  $STD rc-update add nodered
  $STD rc-service nodered start
  msg_ok "Started Node-RED"
}

run_os_setup

motd_ssh
customize
cleanup_lxc
