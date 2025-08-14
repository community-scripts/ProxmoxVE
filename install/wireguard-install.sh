#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.wireguard.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing WireGuard"
$STD apt-get install -y wireguard wireguard-tools net-tools iptables
DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confnew" install -y iptables-persistent &>/dev/null
$STD netfilter-persistent reload
msg_ok "Installed WireGuard"

read -r -p "${TAB3}Would you like to add WGDashboard? <y/N> " prompt
if [[ "${prompt,,}" =~ ^(y|yes)$ ]]; then
  fetch_and_deploy_gh_release "wgdashboard" "donaldzou/WGDashboard" "tarball" "latest" "/etc/wgdashboard"

  msg_info "Installing WGDashboard"
  cd /etc/wgdashboard/src
  chmod u+x wgd.sh
  $STD ./wgd.sh install
  echo "net.ipv4.ip_forward=1" >>/etc/sysctl.conf
  $STD sysctl -p /etc/sysctl.conf
  msg_ok "Installed WGDashboard"

  msg_info "Create Example Config for WGDashboard"
  private_key=$(wg genkey)
  cat <<EOF >/etc/wireguard/wg0.conf
[Interface]
PrivateKey = ${private_key}
Address = 10.0.0.1/24
SaveConfig = true
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -o wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE;
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -D FORWARD -o wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE;
ListenPort = 51820
EOF
  msg_ok "Created Example Config for WGDashboard"

  msg_info "Creating Service"
  cat <<EOF >/etc/systemd/system/wg-dashboard.service
[Unit]
After=syslog.target network-online.target
Wants=wg-quick.target
ConditionPathIsDirectory=/etc/wireguard

[Service]
Type=forking
PIDFile=/etc/wgdashboard/src/gunicorn.pid
WorkingDirectory=/etc/wgdashboard/src
ExecStart=/etc/wgdashboard/src/wgd.sh start
ExecStop=/etc/wgdashboard/src/wgd.sh stop
ExecReload=/etc/wgdashboard/src/wgd.sh restart
TimeoutSec=120
PrivateTmp=yes
Restart=always

[Install]
WantedBy=multi-user.target
EOF
  systemctl enable -q --now wg-dashboard
  msg_ok "Created Service"
fi

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
