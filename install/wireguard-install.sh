#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
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

setup_deb_based() {
  msg_info "Installing Dependencies"
  $STD apt install -y git
  msg_ok "Installed Dependencies"

  msg_info "Installing WireGuard"
  $STD apt install -y wireguard wireguard-tools net-tools iptables
  DEBIAN_FRONTEND=noninteractive apt -o Dpkg::Options::="--force-confnew" install -y iptables-persistent &>/dev/null
  $STD netfilter-persistent reload
  msg_ok "Installed WireGuard"

  read -r -p "${TAB3}Would you like to add WGDashboard? <y/N> " prompt
  if [[ "${prompt,,}" =~ ^(y|yes)$ ]]; then
    git clone -q https://github.com/WGDashboard/WGDashboard.git /etc/wgdashboard

    msg_info "Installing WGDashboard"
    cd /etc/wgdashboard/src
    chmod u+x wgd.sh
    $STD ./wgd.sh install
    . /etc/os-release
    if [ "$VERSION_CODENAME" = "trixie" ]; then
      echo "net.ipv4.ip_forward=1" >>/etc/sysctl.d/sysctl.conf
      $STD sysctl -p /etc/sysctl.d/sysctl.conf
    else
      echo "net.ipv4.ip_forward=1" >>/etc/sysctl.conf
      $STD sysctl -p /etc/sysctl.conf
    fi
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
}

setup_alpine() {
  msg_info "Installing Dependencies"
  $STD apk add \
    iptables \
    openrc
  msg_ok "Installed Dependencies"

  msg_info "Installing WireGuard"
  $STD apk add --no-cache wireguard-tools
  if [[ ! -L /etc/init.d/wg-quick.wg0 ]]; then
    ln -s /etc/init.d/wg-quick /etc/init.d/wg-quick.wg0
  fi

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
  echo "net.ipv4.ip_forward=1" >>/etc/sysctl.conf
  $STD rc-update add sysctl
  $STD sysctl -p /etc/sysctl.conf
  msg_ok "Installed WireGuard"

  read -rp "${TAB3}Do you want to install WGDashboard? (y/N): " INSTALL_WGD
  if [[ "$INSTALL_WGD" =~ ^[Yy]$ ]]; then
    msg_info "Installing additional dependencies for WGDashboard"
    $STD apk add --no-cache \
      python3 \
      py3-pip \
      git \
      sudo \
      musl-dev \
      linux-headers \
      gcc \
      python3-dev
    msg_ok "Installed additional dependencies for WGDashboard"
    msg_info "Installing WGDashboard"
    git clone -q https://github.com/WGDashboard/WGDashboard.git /etc/wgdashboard
    cd /etc/wgdashboard/src
    chmod u+x wgd.sh
    $STD ./wgd.sh install
    msg_ok "Installed WGDashboard"

    msg_info "Creating Service for WGDashboard"
    cat <<EOF >/etc/init.d/wg-dashboard
#!/sbin/openrc-run

description="WireGuard Dashboard Service"

depend() {
    need net
    after firewall
}

start() {
    ebegin "Starting WGDashboard"
    cd /etc/wgdashboard/src/
    ./wgd.sh start &
    eend $?
}

stop() {
    ebegin "Stopping WGDashboard"
    pkill -f "wgd.sh"
    eend $?
}
EOF
    chmod +x /etc/init.d/wg-dashboard
    $STD rc-update add wg-dashboard default
    $STD rc-service wg-dashboard start
    msg_ok "Created Service for WGDashboard"

  fi

  msg_info "Starting Services"
  $STD rc-update add wg-quick.wg0 default
  $STD rc-service wg-quick.wg0 start
  msg_ok "Started Services"
}

run_os_setup

motd_ssh
customize
cleanup_lxc
