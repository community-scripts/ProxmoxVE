#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://adguard.com/ | Github: https://github.com/AdguardTeam/AdGuardHome

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

setup_deb_based() {
  fetch_and_deploy_gh_release "AdGuardHome" "AdguardTeam/AdGuardHome" "prebuild" "latest" "/opt/AdGuardHome" "AdGuardHome_linux_$(arch_resolve).tar.gz"

  msg_info "Creating Service"
  cat <<EOF >/etc/systemd/system/AdGuardHome.service
[Unit]
Description=AdGuard Home: Network-level blocker
ConditionFileIsExecutable=/opt/AdGuardHome/AdGuardHome
After=syslog.target network-online.target

[Service]
StartLimitInterval=5
StartLimitBurst=10
ExecStart=/opt/AdGuardHome/AdGuardHome "-s" "run"
WorkingDirectory=/opt/AdGuardHome
StandardOutput=file:/var/log/AdGuardHome.out
StandardError=file:/var/log/AdGuardHome.err
Restart=always
RestartSec=10
EnvironmentFile=-/etc/sysconfig/AdGuardHome

[Install]
WantedBy=multi-user.target
EOF
  systemctl enable -q --now AdGuardHome
  msg_ok "Created Service"
}

setup_alpine() {
  msg_info "Downloading AdGuard Home"
  $STD curl -fsSL -o /tmp/AdGuardHome_linux_$(arch_resolve).tar.gz \
  "https://github.com/AdguardTeam/AdGuardHome/releases/latest/download/AdGuardHome_linux_$(arch_resolve).tar.gz"
  msg_ok "Downloaded AdGuard Home"

  msg_info "Installing AdGuard Home"
  $STD tar -xzf /tmp/AdGuardHome_linux_$(arch_resolve).tar.gz -C /opt
  $STD rm /tmp/AdGuardHome_linux_$(arch_resolve).tar.gz
  msg_ok "Installed AdGuard Home"

  msg_info "Creating AdGuard Home Service"
  cat <<EOF >/etc/init.d/adguardhome
#!/sbin/openrc-run
name="AdGuardHome"
description="AdGuard Home Service"
command="/opt/AdGuardHome/AdGuardHome"
command_background="yes"
pidfile="/run/adguardhome.pid"
EOF
  $STD chmod +x /etc/init.d/adguardhome
  msg_ok "Created AdGuard Home Service"

  msg_info "Enabling AdGuard Home Service"
  $STD rc-update add adguardhome default
  msg_ok "Enabled AdGuard Home Service"

  msg_info "Starting AdGuard Home"
  $STD rc-service adguardhome start
  msg_ok "Started AdGuard Home"
}

run_os_setup

motd_ssh
customize
cleanup_lxc
